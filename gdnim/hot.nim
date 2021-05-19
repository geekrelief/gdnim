{.push hint[XDeclaredButNotUsed]: off.} # compName and createArgVar are used in macros
#{.push warning[UnreachableCode]: off.}
import macros, globals, strformat, strutils, os, sets, sequtils
import msgpack4nim, options, optionsutils
export msgpack4nim, options, optionsutils, sequtils

proc `^`*(s: string): NimNode {.inline.} =
  ident(s)

type
  GDNimDefect = object of Defect

func lineInfoMsg(p: NimNode, msg: string): string =
  var linfo = p.lineInfoObj()
  return &"{linfo.filename}({linfo.line},{linfo.column}) {msg}"

template gdnimDefect(msg: string) =
  raise newException(GDNimDefect, msg)

# packs arguments pass as a seq[byte]
# save(self.i, self.f, self.s)
macro save*(args: varargs[typed]): untyped =
  #[
    var b = MsgStream.init()
    b.pack(self.i)
    b.pack(self.f)
    b.pack(self.s)
    result = cast[seq[byte]](b.data)
  ]#
  when defined(does_reload):
    var stmts = newStmtList()
    var buffer = genSym(nskVar, "buffer")
    stmts.add newVarStmt(buffer, newCall(newDotExpr(^"MsgStream", ^"init")))
    for arg in args:
      stmts.add newCall(newDotExpr(buffer, ^"pack"), arg)
    stmts.add newAssignment(^"result",
      nnkCast.newTree(nnkBracketExpr.newTree(^"seq", ^"byte"), newDotExpr(buffer, ^"data")))

    result = stmts
  else:
    discard

# used by load to get type information on arg
macro createArgVar(unpackVar: untyped, arg: typed) =
  var typInst = arg.getTypeInst
  if typeKind(getType(arg)) == ntyRef:
    gdnimDefect(lineInfoMsg(unpackVar, &"load({arg.repr}) is ref type: {typInst}. Only primitives and object types allowed."))
  result = quote do:
    var `unpackVar`: `typInst`

#load takes a MsgStream or seq[byte] for loading
# symbol with '!' in front are loaded from the buffer, but not asssigned
# implementation note: takes in untyped args, but we need type information to create a variable
#   pass untyped to a macro that takes typed createArgVar
macro load*(data: typed, args: varargs[untyped]): untyped =
  # load(buffer, self.speed, !self.direction)
  when defined(does_reload):
    result = newStmtList()
    for arg in args:
      let isAssign = if arg.kind == nnkPrefix and arg[0].repr == "!": false else: true
      var isAssignNode = newLit(isAssign)
      var argNode: NimNode = if isAssign: arg else: arg[1]
      var unpackVar: NimNode = genSym(nskVar)

      result.add quote do:
        createArgVar(`unpackVar`, `argNode`)
        `data`.unpack(`unpackVar`)
        if `isAssignNode`:
          `argNode` = `unpackVar`
  else:
    discard

# simple register_instance, pass in the compName as a symbol, returns Option[MsgStream]
macro register_instance*(compName: untyped): untyped =
  when defined(does_reload):
    var compNameStr = newLit(compName.repr)
    result = quote do:
      var watcher = self.get_node("/root/Watcher")
      if watcher.isNil:
        raise newException(GDNimDefect, "Watcher not found")

      var bv = watcher.call("register_instance",
        `compNameStr`.toVariant,
        ($(self.get_path())).toVariant,
        ($(self.get_parent().get_path())).toVariant
      )
      var data: seq[byte]
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
macro register_dependencies*(compName: untyped, dependencies: varargs[untyped]): untyped =
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

## gdnim macro
  # parses for hot reloading,
  # produces a gdobj for godot-nim to parse
const compsDir {.strdefine.}: string = "components"
const depsDir {.strdefine.}: string = "deps"
var godotapiDir {.compileTime.}: string = depsDir & "/godotapi"

proc classStyleToCompStyle(className: string): string =
  var s: string = className
  if s.len > 2 and s[^2].isDigit() and s.endsWith("D"):
    s[^1] = 'd'

  result = $(s[0].toLowerAscii())
  if s.len > 1:
    for c in s[1..^1]:
      if c.isUpperAscii() or c.isDigit():
        result.add('_')
        result.add(c.toLowerAscii())
      else:
        result.add(c)

  if result == "object": # keyword
    result = "objects"
  if result == "os": # to avoid clash with stdlib
    result = "gd_os"

# from godotapigen.nim
const standardTypes = toHashSet(
  ["bool", "cint", "int", "uint8", "int8", "uint16", "int16", "uint32", "int32",
   "uint64", "Error",
   "int64", "float32", "cfloat", "float64", "GodotString", "Vector2", "Rect2",
   "Vector3", "Transform2D", "Plane", "Quat", "AABB", "Basis", "Transform",
   "Color", "RID", "NodePath", "Dictionary", "Variant", "Array",
   "PoolByteArray", "PoolIntArray", "PoolRealArray", "PoolStringArray",
   "PoolVector2Array", "PoolVector3Array", "PoolColorArray"])

proc isGodotApi(name: string): bool =
  var classFilePath = godotapiDir&"/"&classStyleToCompStyle(name)&".nim"
  return fileExists(classFilePath)

proc isComponent(name: string): bool =
  var classFilePath = compsDir&"/"&classStyleToCompStyle(name)&".nim"
  return fileExists(classFilePath)

# checks if properties are not nil
# if properties are not nil, then run the body, else print a message of what properties failed nil.
# e.g. ifValid a, b, c, d: print "ok"
macro ifValid*(ps: varargs[typed], body: untyped): untyped =
  result = quote do: discard

  if ps.len > 1:
    for p in ps:
      var t = getType(p)
      var k = typekind(t)
      var linfo = p.lineInfoObj()

      if not (k == ntyRef):
        gdnimDefect(lineInfoMsg(p, &"notnil {p.repr}: used on non-ref type: {t}"))

    var b = nnkBracket.newNimNode()
    for p in ps:
      b.add nnkPar.newTree(newStrLitNode(p.repr), newCall(^"isNil", p))

    var lmsg = lineInfoMsg(ps, "not ifValid")
    result = when defined(verbose_nil_check):
      quote do:
        var np = filterIt(`b`, it[1] == true)
        if np.len == 0:
          `body`
        elif self.isInsideTree():
          once: # stop flooding
            print `lmsg` & " " & (unzip(np)[0].join(", "))
    else:
      quote do:
        var np = filterIt(`b`, it[1] == true)
        if np.len == 0:
          `body`
  else:
    var p = ps[0]
    var t = getType(p)
    var k = typekind(t)
    var linfo = p.lineInfoObj()

    if not (k == ntyRef):
      gdnimDefect(lineInfoMsg(p, &"notnil {p.repr}: used on non-ref type: {t}"))

    var lMsg = lineInfoMsg(p, &"not ifValid {p.repr}")
    result = when defined(verbose_nil_check):
      quote do:
        if not `p`.isNil:
          `body`
        elif self.isInsideTree():
          once: # stop flooding
            print `lMsg`
    else:
      quote do:
        if not `p`.isNil:
          `body`

#[
proc findComponentGDSuperClass(className:string):string =
  var baseClassName = className
  while not isGodotApi(baseClassName):
    var classFileName = classStyleToCompStyle(baseClassName)
    # open the component .nim and see if it defines a gdnim or gdobj
    # get the base class and repeat
    baseClassName = "something"
  result = baseClassName
]#

macro gdnim*(ast: varargs[untyped]) =
  result = newStmtList()
  var astInfix = ast[0]
  var compName = classStyleToCompStyle(astInfix[1].strVal)
  var baseClassName = astInfix[2].strVal
  var baseClassFileName = classStyleToCompStyle(baseClassName)
  var baseClassFilePath = godotapiDir&"/"&baseClassFileName&".nim"
  var gdObjBody = newStmtList()
  if fileExists(baseClassFilePath):
    var gdobj = nnkCommand.newTree(^"gdobj", astInfix)
    if ast[1].kind == nnkIdent and ast[1].eqIdent("tool"):
      gdobj.add ast[1]

    gdobj.add gdObjBody
    result.add gdobj
  else:
    gdnimDefect(lineInfoMsg(ast, &"Expected Godot class {baseClassName} at {baseClassFilePath}."))


  var typeUnknownPropertyNames = initHashSet[string]()

  var importedGdModules = initHashSet[string]()
  var godotPropertyNames = initHashSet[string]()
  var godotModules = newNimNode(nnkBracket)
  var godotApiImports = nnkImportStmt.newTree(infix(^"godotapi", "/", godotModules))

  importedGdModules.incl baseClassFileName
  godotModules.add ^baseClassFileName

  var importedCompModules = initHashSet[string]()
  var compPropertyNames = initHashSet[string]()
  var compModules = newNimNode(nnkImportStmt)

  var firstNode: NimNode # first incarnation. wraps contents in a check to see if hasn't been reloaded
  var unloadNode: NimNode
  var reloadNode: NimNode
  var dependenciesNode: NimNode
  var enterTreeNode: NimNode
  var readyNode: NimNode

  var astBody = ast[^1]
  # parse
  var gdObjBodyRest = newStmtList()
  for node in astBody:
    case node.kind
      of nnkCommand:
        var commandName = node[0]
        if commandName.eqIdent("godotapi"):
          for godotModule in node[1..^1]:
            var cGodotModule = ^(classStyleToCompStyle(godotModule.repr))
            godotModules.add cGodotModule
        else:
          gdObjBody.add(node)
      of nnkVarSection:
        gdObjBody.add(node)
        for identDef in node:
          var name: string
          case identDef[0].kind
            of nnkIdent:
              name = identDef[0].strVal
            of nnkPragmaExpr:
              name = identDef[0][0].strVal
            else:
              gdnimDefect(&"Unhandled node kind {identDef[0].kind}: {lineInfo(identDef)}\n{node.astGenRepr}")

          var typName: string
          if not (identDef[1].kind == nnkEmpty):
            typName = identDef[1].repr
          else:
            if identDef[2].kind == nnkEmpty:
              gdnimDefect(&"Unknown type for field {name}: {lineInfo(identDef)}\n{identDef[1].repr}")
            else:
              typeUnknownPropertyNames.incl name
              continue

          if typName notin standardTypes:
            var filename = classStyleToCompStyle(typName)
            if isGodotApi(typName):
              if filename notin importedGdModules:
                importedGdModules.incl filename
                godotModules.add ^filename
                godotPropertyNames.incl name
            elif isComponent(typName):
              # need to replace the type of the property with gd base class
              # when defined(does_reload):
              if filename notin importedCompModules:
                importedCompModules.incl filename
                compModules.add ^filename
                compPropertyNames.incl name
            else:
              typeUnknownPropertyNames.incl name
      of nnkCall:
        var callName = node[0]
        if callName.eqIdent("first"):
          firstNode = node[^1]
        elif callName.eqIdent("unload"):
          unloadNode = node[^1]
        elif callName.eqIdent("reload"):
          reloadNode = node[^1]
        elif callName.eqIdent("dependencies"):
          dependenciesNode = node[^1]
        else:
          gdObjBodyRest.add(node)
      of nnkMethodDef:
        if node[0].eqIdent("enter_tree"):
          enterTreeNode = node
        elif node[0].eqIdent("ready"):
          readyNode = node
        else:
          gdObjBodyRest.add(node)
      else:
        gdObjBodyRest.add(node)

  #generate
  if enterTreeNode.isNil:
    enterTreeNode = nnkMethodDef.newTree(^"enter_tree", newEmptyNode(), newEmptyNode(),
      nnkFormalParams.newTree(newEmptyNode()), newEmptyNode(), newEmptyNode(), newStmtList())

  var enterTreeBody = enterTreeNode.body
  gdObjBody.add enterTreeNode

  if readyNode.isNil:
    readyNode = nnkMethodDef.newTree(^"ready", newEmptyNode(), newEmptyNode(),
      nnkFormalParams.newTree(newEmptyNode()), newEmptyNode(), newEmptyNode(), newStmtList())

  var readyBody = readyNode.body
  gdObjBody.add readyNode

  readyBody.add quote do:
    if self.hasMeta(HotMetaPositionInParent):
      var positionInParent = self.getMeta(HotMetaPositionInParent).asInt()
      toV self.getParent().callDeferred("move_child", [self, positionInParent])
    self.setMeta(HotMetaIsReloading, false.toVariant())


  when defined(does_reload):
    # unload
    if unloadNode.isNil:
      unloadNode = newStmtlist()

    unloadNode.add quote do:
      self.setMeta(HotMetaIsReloading, true.toVariant())
      self.setMeta(HotMetaPositionInParent, self.getPositionInParent().toVariant())

    gdObjBody.add(newProc(name = ^HotUnload, params = @[nnkBracketExpr.newTree(^"seq", ^"byte")],
                          body = unloadNode, pragmas = nnkPragma.newTree(^"gdExport")))

    # dependencies
    var dependenciesCompNames: seq[string]
    if not dependenciesNode.isNil:
      for section in dependenciesNode:
        case section.kind
          of nnkIdent:
            dependenciesCompNames.add section.strVal
          else:
            gdnimDefect(&"Unexpected {section.kind} in dependencies definition.")

    # reload
    if reloadNode.isNil:
      reloadNode = newStmtList()

    var dependencies = newEmptyNode()
    if dependenciesCompNames.len > 0:
      var rdepCall = nnkCall.newTree(^"register_dependencies", ^compName)
      for depName in dependenciesCompNames:
        rdepCall.add ^depName
      dependencies = quote do:
        `rdepCall`

    if reloadNode.len > 0:
      # find load call in reloadNode
      var dataIdent = genSym(nskVar, "data")
      var compNameIdent = ^compName
      var reloadBody = quote do:
        var `dataIdent` = register_instance(`compNameIdent`)
        `dependencies`
      for node in reloadNode:
        case node.kind:
          of nnkCall:
            if node[0].eqIdent("load"):
              reloadBody.add nnkInfix.newTree(^"?.", dataIdent, node)
            else:
              reloadBody.add node
          else:
            reloadBody.add node
      enterTreeBody.insert(0, reloadBody)

    # first
    if firstNode.isNil:
      firstNode = quote do:
        discard

    var isNewInstanceNode = quote do:
      if isNewInstance(self):
        `firstNode`

    enterTreeBody.insert(0, isNewInstanceNode)

  else: # not does_reload
    if not reloadNode.isNil and reloadNode.len > 0:
      # ignore load call in reloadNode
      # add everything else to enter_tree method
      var reloadBody = newStmtList()
      for node in reloadNode:
        case node.kind:
          of nnkCall:
            if node[0].eqIdent("load"):
              discard
            else:
              reloadBody.add node
          else:
            reloadBody.add node
      enterTreeBody.insert(0, reloadBody)

    # first
    if firstNode.isNil:
      firstNode = quote do:
        discard

    enterTreeBody.insert(0, firstNode)

    # ignore dependencies section, when not reloading

  for stmt in gdObjBodyRest:
    gdObjBody.add stmt

  if godotModules.len > 0:
    result.insert(0, godotApiImports)
  if compModules.len > 0 and not defined(does_reload):
    result.insert(0, compModules)
  #echo &"{importedGdModules = }"
  #echo &"{importedCompModules = }"
  #echo result.repr
