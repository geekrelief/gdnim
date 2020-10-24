import macros
import msgpack4nim
export msgpack4nim

proc `^`*(s:string):NimNode {.inline.} =
  ident(s)

macro save*(args: varargs[typed]):untyped =
  #[
    #save(self.i, self.f, self.s) produces
    self.queue_free()
    var b = MsgStream.init()
    b.pack(self.i)
    b.pack(self.f)
    b.pack(self.s)
    cast[seq[byte]](b.data)
  ]#
  var stmts = newStmtList()
  stmts.add newCall(newDotExpr(^"self", ^"queue_free"))
  stmts.add newVarStmt(^"b", newCall(newDotExpr(^"MsgStream", ^"init")))
  for arg in args:
    stmts.add newCall(newDotExpr(^"b", ^"pack"),
      newDotExpr(^"self", ^(arg[1].repr))
    )
  stmts.add nnkCast.newTree(nnkBracketExpr.newTree(^"seq", ^"byte"), newDotExpr(^"b", ^"data"))

  result = stmts

macro load*(args: varargs[typed]):untyped =
  #[
    load(data, self.i)
    var w = self.get_node("/root/Watcher")
    if w.isNil:
      raise newException(Defect, "Watcher not found")

    var v = w.call("register_component",
      self.compName.toVariant,
      ($self.get_path()).toVariant), #savePath
      ($self.get_parent().get_path()).toVariant) #loadPath
    var data:seq[byte]
    discard fromVariant(data, v)
    if data.len == 0: return
    var b = MsgStream.init(cast[string](data))
    var i:int
    b.unpack(i)
    self.intVal = i
  ]#
  var stmts = newStmtList()
  stmts.add nnkVarSection.newTree(
    nnkIdentDefs.newTree(^"w", newEmptyNode(), newCall(newDotExpr(^"self", ^"get_node"), newLit("/root/Watcher")))
  )

  stmts.add newIfStmt(
    (newDotExpr(^"w", ^"isNil"), newStmtlist(nnkRaiseStmt.newTree(newCall(^"newException", ^"Defect", newLit("Watcher not found")))))
  )
  stmts.add nnkVarSection.newTree(
    nnkIdentDefs.newTree(^"v", newEmptyNode(),
      newCall(
        newDotExpr(^"w", ^"call"),
        newLit("register_component"),
        newDotExpr(newDotExpr(^"self", ^"compName"), ^"toVariant"),
        newDotExpr(nnkPar.newTree(nnkPrefix.newTree(^"$", newCall(newDotExpr(^"self", ^"get_path")))), ^"toVariant"),
        newDotExpr(nnkPar.newTree(nnkPrefix.newTree(^"$", newCall(newDotExpr(newCall(newDotExpr(^"self", ^"get_parent")),^"get_path")))), ^"toVariant")
      )
    )
  )
  stmts.add nnkVarSection.newTree(
    nnkIdentDefs.newTree(^"data", nnkBracketExpr.newTree(^"seq", ^"byte"), newEmptyNode())
  )
  stmts.add nnkDiscardStmt.newTree(
    newCall(^"fromVariant", ^"data", ^"v")
  )

  stmts.add newIfStmt(
    (nnkInfix.newTree(^"==", newDotExpr(^"data", ^"len"), newLit(0)),
      newStmtList(nnkReturnStmt.newTree(newEmptyNode())))
  )

  stmts.add newVarStmt(^"b", newCall(newDotExpr(^"MsgStream", ^"init"), nnkCast.newTree(^"string", ^"data")))

  for aprop in args:
    var prop = ^($aprop[1])
    var propType = ^($getType(aprop[1]))
    stmts.add(
      nnkVarSection.newTree( nnkIdentDefs.newTree(prop, propType, newEmptyNode())),
      newCall(newDotExpr(^"b", ^"unpack"), prop),
      newAssignment(newDotExpr(^"self", prop), prop)
    )
  #echo stmts.astGenRepr
  result = stmts