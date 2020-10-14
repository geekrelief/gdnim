import msgpack4nim, tables
export msgpack4nim, tables

type
  OnBeforeReload* = proc() {.closure, gcsafe.}
  ReloadMeta = tuple[compName:string, parentPath:string, reloadProc: OnBeforeReload]

when defined(exportStorage):
  var reloadDataTable:Table[string, string]
  var reloadMetaTable:Table[string, ReloadMeta]

  proc `!`(s:string):string =
    # https://github.com/nim-lang/Nim/issues/15552
    # need to make a copy of anything stored in storage
    s & ""

  # --- implementation
  {.push nimcall, exportc, dynlib.}
  proc getReloadMetaTable*():Table[string, ReloadMeta] =
    reloadMetaTable

  proc putData*(id: string, data: string) =
    reloadDataTable[id] = data

  proc registerReloadMeta*(id: string, rmeta:ReloadMeta):string =
    var nid = !id #need to create a newString otherwise we'll get a crash on copy
    reloadMetaTable[nid] = (compName: !rmeta.compName , parentPath: !rmeta.parentPath, reloadProc: rmeta.reloadProc)
    var data = ""
    discard reloadDataTable.take(nid, data)
    result = data

else:

  import macros
  export macros
  {.push nimcall, importc, dynlib:"_dlls/storage.dll"}
  # used by Watcher
  proc getReloadMetaTable*():Table[string, ReloadMeta]

  #used by components
  proc putData*(id:string, data: string)
  proc registerReloadMeta*(id: string, rmeta:ReloadMeta):string

  proc `^`*(s:string):NimNode =
    ident(s)

  macro save*(args: varargs[typed]):untyped =
    #[
      #save(self.i, self.f, self.s) produces
      var b = MsgStream.init()
      b.pack(self.i)
      b.pack(self.f)
      b.pack(self.s)
      putData(self.compName, b.data)
      self.queue_free()
    ]#
    var stmts = newStmtList()
    stmts.add newVarStmt(^"b", newCall(newDotExpr(^"MsgStream", ^"init")))
    for arg in args:
      stmts.add newCall(newDotExpr(^"b", ^"pack"),
        newDotExpr(^"self", ^(arg[1].repr))
      )
    stmts.add newCall(^"putData",
      newDotExpr(^"self", ^"compName"),
      newDotExpr(^"b", ^"data")
    )
    stmts.add newCall(newDotExpr(^"self", ^"queue_free"))
    result = stmts

  macro load*(args: varargs[typed]):untyped =
    #[
      load(data, self.i, self.f)
      if data.len == 0: return
      var b = MsgStream.init(data)
      var i:int
      b.unpack(i)
      self.i = i
      var f:float
      b.unpack(f)
      self.f = f
    ]#
    var stmts = newStmtList()
    var data = args[0] # verify it's a string?
    if typeKind(getType(data)) != ntystring and data.kind == nnkIdent:
      raise newException(Exception,
        "storage.load first argument must be string containing MsgStream data")

    stmts.add newIfStmt(
      (nnkInfix.newTree(^"==", newDotExpr(data, ^"len"), newLit(0)),
        newStmtList(nnkReturnStmt.newTree(newEmptyNode())))
    )
    stmts.add newVarStmt(^"b", newCall(newDotExpr(^"MsgStream", ^"init"), data))
    for aprop in args[1..^1]:
      var prop = ^($aprop[1])
      var propType = ^($getType(aprop[1]))
      stmts.add(
        nnkVarSection.newTree( nnkIdentDefs.newTree(prop, propType, newEmptyNode())),
        newCall(newDotExpr(^"b", ^"unpack"), prop),
        newAssignment(newDotExpr(^"self", prop), prop)
      )
    #echo stmts.astGenRepr
    result = stmts