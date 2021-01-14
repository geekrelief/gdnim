import macros, strformat, os
from strutils import contains
import msgpack4nim, options, optionsutils
export msgpack4nim, options, optionsutils


proc `^`*(s:string):NimNode {.inline.} =
  ident(s)

# packs arguments pass as a seq[byte]
# save(self.i, self.f, self.s)
macro save*(args: varargs[typed]):untyped =
  #[
    var b = MsgStream.init()
    b.pack(self.i)
    b.pack(self.f)
    b.pack(self.s)
    cast[seq[byte]](b.data)
  ]#
  var stmts = newStmtList()
  var buffer = genSym(nskVar, "buffer")
  stmts.add newVarStmt(buffer, newCall(newDotExpr(^"MsgStream", ^"init")))
  for arg in args:
    var prop:NimNode
    case arg.kind:
    of nnkCall: prop = ^($arg[0])
    else: prop = ^($arg[1])
    stmts.add newCall(newDotExpr(buffer, ^"pack"),
      newDotExpr(^"self", prop)
    )
  stmts.add nnkCast.newTree(nnkBracketExpr.newTree(^"seq", ^"byte"), newDotExpr(buffer, ^"data"))

  result = stmts

#load takes a MsgStream or seq[byte] for loading#
macro load*(data:typed, args: varargs[typed]):untyped =
  # load(buffer, self.i)
  var stmts = newStmtList()
  var buffer = data
  if getTypeInst(data).repr == "seq[byte]":
    buffer = genSym(nskVar, "buffer")
    stmts.add newVarStmt(buffer, newCall(newDotExpr(^"MsgStream", ^"init"), nnkCast.newTree(^"string", data)))

  var unpackStmts = newStmtList()
  stmts.add unpackStmts
  for aprop in args:
    var prop:NimNode
    var propType:NimNode
    case aprop.kind
    of nnkCall:
      prop = ^($aprop[0])
      propType = ^($getTypeInst(aprop))
    else:
      prop = ^($aprop[1])
      propType = ^($getTypeInst(aprop[1]))

    unpackStmts.add(
      nnkVarSection.newTree( nnkIdentDefs.newTree(prop, propType, newEmptyNode())),
      newCall(newDotExpr(buffer, ^"unpack"), prop),
      newAssignment(newDotExpr(^"self", prop), prop)
    )

  #echo stmts.repr
  result = stmts

# simple register, pass in the compName as a symbol, returns Option[MsgStream]
macro register*(compName:untyped):untyped =
  var compNameStr = newLit(compName.repr)
  result = quote do:
    var watcher = self.get_node("/root/Watcher")
    if watcher.isNil:
      raise newException(Defect, "Watcher not found")

    var bv = watcher.call("register_instance",
      `compNameStr`.toVariant,
      ($(self.get_path())).toVariant,
      ($(self.get_parent().get_path())).toVariant
    )
    var data:seq[byte]
    discard fromVariant(data, bv)
    if data.len != 0:
      some(MsgStream.init(cast[string](data)))
    else:
      none(MsgStream)

#register with the watcher and returns an Option[MsgStream]
# compName, saverProc, loaderProc are symbols, converted to strings
macro register*(compName:untyped, reloaderPath:string, saverProc:untyped, loaderProc:untyped):untyped =
  # var path = $self.get_path()
  #var stream = register_instance(bullet, path, save_bullets, setup_bullets) # returns Option[MsgStream]
  var compNameStr = newLit(compName.repr)
  var saverProcStr = newLit(saverProc.repr)
  var loaderProcStr = newLit(loaderProc.repr)

  result = quote do:
    var watcher = self.get_node("/root/Watcher")
    if watcher.isNil:
      raise newException(Defect, "Watcher not found")

    var bv = watcher.call("register_instance",
      `compNameStr`.toVariant,
      `reloaderPath`.toVariant, #saver path
      `reloaderPath`.toVariant, #loader path
      `saverProcStr`.toVariant,
      `loaderProcStr`.toVariant
    )
    var data:seq[byte]
    discard fromVariant(data, bv)
    if data.len != 0:
      some(MsgStream.init(cast[string](data)))
    else:
      none(MsgStream)


# if component A instances component B,
# A must register B as a dependency if it holds a reference to B
# component A must have a proc:
#   proc hot_dep_unload*(compName:string, isUnloading:bool) {.gdExport.}
macro register_dependencies*(compName:untyped, dependencies:varargs[untyped]):untyped =
  var compNameStr = newLit(compName.repr)

  var bracketNode = newNimNode(nnkBracket)
  var depNode = prefix(bracketNode, "@")
  for dep in dependencies:
    bracketNode.add newLit(dep.repr)

  result = quote do:
    var watcher = self.get_node("/root/Watcher")
    if watcher.isNil:
      raise newException(Defect, "Watcher not found")

    discard watcher.call("register_dependencies",
      `compNameStr`.toVariant,
      `depNode`.toVariant,
    )


const tscnDir = "_tscn"
# find the resource at runtime, returns the first resource that matches compName
proc findCompTscn*(compName:string):string =
  var tscnFilename = &"{compName}.tscn"
  var matches:seq[string]
  for f in walkDirRec(&"{tscnDir}"):
    if f.contains(tscnFilename):
      matches.add move(&"res://{f}")
  if matches.len == 1:
    return matches[0]
  if matches.len == 0:
    raise newException(IOError, &"Scene resource for {compName} could not be found!")
  if matches.len > 1:
    raise newException(IOError, &"Multiple resources found with {compName}:\n\t{matches}")

# helper to convert types and execute body, if object can be cast to type
# example: ifis(event, InputEventKey): print it.scancode
template ifis*(a:typed, T:typed, body:untyped):untyped =
  if a of T:
    var it {.inject.} = a as T
    body