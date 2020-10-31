import macros
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
  let watcher = genSym(nskVar, "w")
  let saveDataVariant = genSym(nskVar, "v")
  let saveData = genSym(nskVar, "data")
  var blockStmt = nnkBlockStmt.newTree()
  blockStmt.add newEmptyNode()
  blockStmt.add newStmtList(
    newVarStmt(watcher, newCall(newDotExpr(^"self", ^"get_node"), newLit("/root/Watcher"))),
    newIfStmt((newDotExpr(watcher, ^"isNil"), newStmtList(nnkRaiseStmt.newTree(newCall(^"newException", ^"Defect", newLit("Watcher not found")))))),
    newStmtList(
      nnkVarSection.newTree(
        nnkIdentDefs.newTree(saveDataVariant, newEmptyNode(),
          newCall(
            newDotExpr(watcher, ^"call"),
            newLit("register_component"),
            newDotExpr(newLit(compName.repr), ^"toVariant"),
            newDotExpr(nnkPar.newTree(nnkPrefix.newTree(^"$", newCall(newDotExpr(^"self", ^"get_path")))), ^"toVariant"),
            newDotExpr(nnkPar.newTree(nnkPrefix.newTree(^"$", newCall(newDotExpr(newCall(newDotExpr(^"self", ^"get_parent")),^"get_path")))), ^"toVariant")
          )
        )
      ),
      nnkVarSection.newTree(newIdentDefs(saveData, nnkBracketExpr.newTree(^"seq", ^"byte"))),
      nnkDiscardStmt.newTree(newCall(^"fromVariant", saveData, saveDataVariant)),

      nnkIfStmt.newTree(
        nnkElifBranch.newTree(
          nnkInfix.newTree(^"!=", newDotExpr(saveData, ^"len"), newLit(0)),
          newCall(^"some", newCall(newDotExpr(^"MsgStream", ^"init"), nnkCast.newTree(^"string", saveData)))
        ),
        nnkElse.newTree(newCall(^"none", ^"MsgStream"))
      )
    )
  )
  result = blockStmt


#register with the watcher and returns a MsgStream or exits proc
# compName, saverProc, loaderProc are symbols, converted to strings
macro register*(compName:untyped, saverPath:string, loaderPath:string, saverProc:untyped, loaderProc:untyped):untyped =
  # var path = $self.get_path()
  #var stream = register_component(bullet, path, path, save_bullets, setup_bullets) # returns from caller proc if there's no data
  #[
    block:
      var w = self.get_node("/root/Watcher")
      if w.isNil:
        raise newException(Defect, "Watcher not found")

      var bv = w.call("register_component",
        compName.toVariant,
        pathv, #savePath
        pathv, #loadPath,
        saverProc.toVariant,
        loaderProc.toVariant
      )
      var data:seq[byte]
      discard fromVariant(data, bv)
      if data.len == 0: return
      MsgStream.init(cast[string](data))
  ]#
  let watcher = genSym(nskVar, "w")
  let saveDataVariant = genSym(nskVar, "v")
  let saveData = genSym(nskVar, "data")
  var blockStmt = nnkBlockStmt.newTree()
  blockStmt.add newEmptyNode()
  blockStmt.add newStmtList(
    newVarStmt(watcher, newCall(newDotExpr(^"self", ^"get_node"), newLit("/root/Watcher"))),
    newIfStmt((newDotExpr(watcher, ^"isNil"), newStmtList(nnkRaiseStmt.newTree(newCall(^"newException", ^"Defect", newLit("Watcher not found")))))),
    newStmtList(
      newVarStmt(saveDataVariant,
        newCall(newDotExpr(watcher, ^"call"), newLit("register_component"),
          newDotExpr(newLit(compName.repr), ^"toVariant"),
          newDotExpr(saverPath, ^"toVariant"),
          newDotExpr(loaderPath, ^"toVariant"),
          newDotExpr(newLit(saverProc.repr), ^"toVariant"),
          newDotExpr(newLit(loaderProc.repr), ^"toVariant"),
        )
      ),
      nnkVarSection.newTree(newIdentDefs(saveData, nnkBracketExpr.newTree(^"seq", ^"byte"))),
      nnkDiscardStmt.newTree(newCall(^"fromVariant", saveData, saveDataVariant)),

      nnkIfStmt.newTree(
        nnkElifBranch.newTree(
          nnkInfix.newTree(^"!=", newDotExpr(saveData, ^"len"), newLit(0)),
          newCall(^"some", newCall(newDotExpr(^"MsgStream", ^"init"), nnkCast.newTree(^"string", saveData)))
        ),
        nnkElse.newTree(newCall(^"none", ^"MsgStream"))
      )
    )
  )
  result = blockStmt