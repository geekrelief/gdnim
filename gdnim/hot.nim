import macros, strformat
import msgpack4nim, options, optionsutils
export msgpack4nim, options, optionsutils

const does_reload* {.booldefine.}: bool = true
const is_tool* {.booldefine.}: bool = false

proc `^`(s:string):NimNode {.inline.} =
  ident(s)

type
  HotReloadDefect = object of Defect

  WatcherNoticeCode* = enum
    UNLOADING,
    RELOADED,
    REGISTER_COMP

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
  when defined(does_reload):
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
  else:
    discard

# loads args from buffer where args are tuples of properties and whether they should be assigned
macro loadHelper(data:typed, args:varargs[typed]):untyped =
  when defined(does_reload):
    var stmts = newStmtList()
    var buffer = data
    if getTypeInst(data).repr == "seq[byte]":
      buffer = genSym(nskVar, "buffer")
      stmts.add newVarStmt(buffer, newCall(newDotExpr(^"MsgStream", ^"init"), nnkCast.newTree(^"string", data)))

    var unpackStmts = newStmtList()
    stmts.add unpackStmts
    for arg in args:
      var prop = arg[0]
      var isAssigned = arg[1]
      var unpackVar:NimNode = genSym(nskVar)
      var propType:NimNode = getTypeInst(prop)

      unpackStmts.add quote do:
        var `unpackVar`:`propType`
        `buffer`.unpack(`unpackVar`)

      unpackStmts.add case prop.kind
      of nnkCall: # for method properties `prop=`(self, T)
        var propName = prop[0]
        quote do:
          if `isAssigned`:
            self.`propName` = `unpackVar`
      of nnkDotExpr: # for data properties self.prop
        var propName = prop[1]
        quote do:
          if `isAssigned`:
            self.`propName` = `unpackVar`
      of nnkSym: # for variables
        var propName = prop
        quote do:
          if `isAssigned`:
            `propName` = `unpackVar`
      else:
        raise newException(HotReloadDefect, &"Unsupporterd {prop.repr}")

    #echo stmts.repr
    result = stmts
  else:
    discard

#load takes a MsgStream or seq[byte] for loading
# symbol with '!' in front are loaded from the buffer, but not asssigned
# load converts the args from untyped to typed and pass it to loadHelper
macro load*(data:typed, args: varargs[untyped]):untyped =
  # load(buffer, self.speed, !self.direction)
  when defined(does_reload):
    var targs:NimNode = newNimNode(nnkArgList)
    for arg in args:
      var t = newNimNode(nnkTupleConstr)
      if arg.kind == nnkPrefix and arg[0].repr == "!":
        t.add(arg[1])
        t.add(newLit(false))
      else:
        t.add(arg)
        t.add(newLit(true))

      targs.add t

    result = quote do:
      loadHelper(`data`, `targs`)
  else:
    discard

# simple register, pass in the compName as a symbol, returns Option[MsgStream]
macro register*(compName:untyped):untyped =
  when defined(does_reload):
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
  else:
    result = quote do:
      none(MsgStream)

#register with the watcher and returns an Option[MsgStream]
# compName, saverProc, loaderProc are symbols, converted to strings
macro register*(compName:untyped, reloaderPath:string, saverProc:untyped, loaderProc:untyped):untyped =
  # var path = $self.get_path()
  #var stream = register_instance(bullet, path, save_bullets, setup_bullets) # returns Option[MsgStream]
  when defined(does_reload):
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
  else:
    result = quote do:
      none(MsgStream)


# if component A instances component B,
# A must register B as a dependency if it holds a reference to B
# component A must have a proc:
#   proc hot_dep_unload*(compName:string, isUnloading:bool) {.gdExport.}
macro register_dependencies*(compName:untyped, dependencies:varargs[untyped]):untyped =
  when defined(does_reload):
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
  else:
    discard