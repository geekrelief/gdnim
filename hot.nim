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
  stmts.add newVarStmt(^"b", newCall(newDotExpr(^"MsgStream", ^"init")))
  for arg in args:
    stmts.add newCall(newDotExpr(^"b", ^"pack"),
      newDotExpr(^"self", ^(arg[1].repr))
    )
  stmts.add nnkCast.newTree(nnkBracketExpr.newTree(^"seq", ^"byte"), newDotExpr(^"b", ^"data"))

  result = stmts

macro load*(buffer:untyped, args: varargs[typed]):untyped =
  #[
    load(b, self.i)
    var i:int
    b.unpack(i)
    self.intVal = i
  ]#
  var stmts = newStmtList()
  for aprop in args:
    var prop = ^($aprop[1])
    var propType = ^($getType(aprop[1]))
    stmts.add(
      nnkVarSection.newTree( nnkIdentDefs.newTree(prop, propType, newEmptyNode())),
      newCall(newDotExpr(buffer, ^"unpack"), prop),
      newAssignment(newDotExpr(^"self", prop), prop)
    )
  #echo stmts.astGenRepr
  result = stmts

# simple register, pass in the compName as a symbol, returns MsgStream or exits proc
macro register*(compName:untyped):untyped =
  var blockStmt = nnkBlockStmt.newTree()
  blockStmt.add newEmptyNode()
  blockStmt.add newStmtList(
    newVarStmt(^"w", newCall(newDotExpr(^"self", ^"get_node"), newLit("/root/Watcher"))),
    newIfStmt((newDotExpr(^"w", ^"isNil"), newStmtList(nnkRaiseStmt.newTree(newCall(^"newException", ^"Defect", newLit("Watcher not found")))))),
    newStmtList(
      nnkVarSection.newTree(
        nnkIdentDefs.newTree(^"bv", newEmptyNode(),
          newCall(
            newDotExpr(^"w", ^"call"),
            newLit("register_component"),
            newDotExpr(newLit(compName.repr), ^"toVariant"),
            newDotExpr(nnkPar.newTree(nnkPrefix.newTree(^"$", newCall(newDotExpr(^"self", ^"get_path")))), ^"toVariant"),
            newDotExpr(nnkPar.newTree(nnkPrefix.newTree(^"$", newCall(newDotExpr(newCall(newDotExpr(^"self", ^"get_parent")),^"get_path")))), ^"toVariant")
          )
        )
      ),
      nnkVarSection.newTree(newIdentDefs(^"data", nnkBracketExpr.newTree(^"seq", ^"byte"))),
      nnkDiscardStmt.newTree(newCall(^"fromVariant", ^"data", ^"bv")),

      newIfStmt(
        (nnkInfix.newTree(^"==", newDotExpr(^"data", ^"len"), newLit(0)),
          newStmtList(nnkReturnStmt.newTree(newEmptyNode())))
      ),
      newCall(newDotExpr(^"MsgStream", ^"init"), nnkCast.newTree(^"string", ^"data"))
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
  var blockStmt = nnkBlockStmt.newTree()
  blockStmt.add newEmptyNode()
  blockStmt.add newStmtList(
    newVarStmt(^"w", newCall(newDotExpr(^"self", ^"get_node"), newLit("/root/Watcher"))),
    newIfStmt((newDotExpr(^"w", ^"isNil"), newStmtList(nnkRaiseStmt.newTree(newCall(^"newException", ^"Defect", newLit("Watcher not found")))))),
    newStmtList(
      newVarStmt(^"bv",
        newCall(newDotExpr(^"w", ^"call"), newLit("register_component"),
          newDotExpr(newLit(compName.repr), ^"toVariant"),
          newDotExpr(saverPath, ^"toVariant"),
          newDotExpr(loaderPath, ^"toVariant"),
          newDotExpr(newLit(saverProc.repr), ^"toVariant"),
          newDotExpr(newLit(loaderProc.repr), ^"toVariant"),
        )
      ),
      nnkVarSection.newTree(newIdentDefs(^"data", nnkBracketExpr.newTree(^"seq", ^"byte"))),
      nnkDiscardStmt.newTree(newCall(^"fromVariant", ^"data", ^"bv")),

      newIfStmt(
        (nnkInfix.newTree(^"==", newDotExpr(^"data", ^"len"), newLit(0)),
          newStmtList(nnkReturnStmt.newTree(newEmptyNode())))
      ),
      newCall(newDotExpr(^"MsgStream", ^"init"), nnkCast.newTree(^"string", ^"data"))
    )
  )
  result = blockStmt