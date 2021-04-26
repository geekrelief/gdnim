{.push hint[XDeclaredButNotUsed]: off.} # compName and createVarArg are used in macros
import macros, strformat, strutils, os, sets
import msgpack4nim, options, optionsutils
export msgpack4nim, options, optionsutils

const does_reload* {.booldefine.}: bool = true
const is_tool* {.booldefine.}: bool = false

proc `^`(s: string): NimNode {.inline.} =
  ident(s)

type
  GDNimDefect = object of Defect
  HotReloadDefect = object of Defect

  #emitted by Watcher notice
  WatcherNoticeCode* = enum
    wncUnloading,
    wncReloaded,
    wncRegisterComp

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
    raise newException(HotReloadDefect, &"load({arg.repr}) is ref type: {typInst}. Only primitives and object types allowed.")
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

# simple register, pass in the compName as a symbol, returns Option[MsgStream]
macro register*(compName: untyped): untyped =
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
      var data: seq[byte]
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
macro register*(compName: untyped, reloaderPath: string, saverProc: untyped, loaderProc: untyped): untyped =
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
# component A must have a proc:
#   proc hot_depreload*(compName:string, isUnloading:bool) {.gdExport.}
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

proc gdnimDefect(msg: string) =
  raise newException(GDNimDefect, msg)

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
    gdnimDefect(&"Expected Godot class {baseClassName} at {baseClassFilePath}.")


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

  var onceNode: NimNode # wraps contents in a check to see if hasn't been reloaded
  var unloadNode: NimNode
  var reloadNode: NimNode
  var dependenciesNode: NimNode
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
        if callName.eqIdent("once"):
          onceNode = node[^1]
        elif callName.eqIdent("unload"):
          unloadNode = node[^1]
        elif callName.eqIdent("reload"):
          reloadNode = node[^1]
        elif callName.eqIdent(^"dependencies"):
          dependenciesNode = node[^1]
        else:
          gdObjBodyRest.add(node)
      of nnkMethodDef:
        if node[0].eqIdent("ready"):
          readyNode = node
        else:
          gdObjBodyRest.add(node)
      else:
        gdObjBodyRest.add(node)

  #generate
  if readyNode.isNil:
    readyNode = nnkMethodDef.newTree(^"ready", newEmptyNode(), newEmptyNode(),
      nnkFormalParams.newTree(newEmptyNode()), newEmptyNode(), newEmptyNode(), newStmtList())

  var readyBody = readyNode.body
  gdObjBody.add readyNode

  when defined(does_reload):
    # unload
    if unloadNode.isNil:
      unloadNode = newStmtlist()

    unloadNode.add quote do:
      self.queue_free()

    for prop in godotPropertyNames:
      var propIdent = ^prop
      unloadNode.add(
        quote do:
        self.`propIdent` = nil
      )
    for prop in typeUnknownPropertyNames:
      var propIdent = ^prop
      unloadNode.add(
        quote do:
        nilRef(self.`propIdent`)
      )

    gdObjBody.add(newProc(name = ^"hot_unload", params = @[nnkBracketExpr.newTree(^"seq", ^"byte")],
                          body = unloadNode, pragmas = nnkPragma.newTree(^"gdExport")))

    # dependencies
    var dependenciesCompNames: seq[string]
    if not dependenciesNode.isNil:
      var depreloadBody = newStmtList()
      var depreloadCase = nnkCaseStmt.newTree().add ^"compName"
      depreloadBody.add depreloadCase
      for section in dependenciesNode:
        case section.kind
          of nnkCall:
            var depName = section[0].strVal
            dependenciesCompNames.add depName
            var sectionStmts = section[1]
            var unloadStmts = newStmtList()
            for stmt in sectionStmts:
              if stmt.kind == nnkAsgn:
                if stmt[0].kind == nnkDotExpr:
                  var propName = stmt[0][1].strVal
                  if propName in godotPropertyNames or propName in compPropertyNames:
                    var propNameIdent = ^propName
                    unloadStmts.add quote do: self.`propNameIdent` = nil
              else:
                discard
            var ofBranch = nnkOfBranch.newTree().add newStrLitNode(depName)
            ofBranch.add newStmtList(quote do:
              if isUnloading:
                `unloadStmts`
              else:
                `sectionStmts`)
            depreloadCase.add ofBranch
          else:
            gdnimDefect(&"Unexpected {section.kind} in dependencies definition.")
      depreloadCase.add nnkElse.newTree(nnkDiscardStmt.newTree(newEmptyNode()))
      gdObjBody.add newProc(name = ^"hot_depreload",
        params = @[newEmptyNode(), newIdentDefs(^"compName", ^"string"), newIdentDefs(^"isUnloading", ^"bool")],
        body = depreloadBody, pragmas = nnkPragma.newTree(^"gdExport"))

    # reload
    if reloadNode.isNil:
      reloadNode = newStmtList()

    var dependencies = newEmptyNode()
    if dependenciesCompNames.len > 0:
      var rdepCall = nnkCall.newTree(^"register_dependencies", ^compName)
      var reloadInit = newStmtList()
      for depName in dependenciesCompNames:
        rdepCall.add ^depName
        reloadInit.add quote do:
          self.hot_depreload(`depName`, false)
      dependencies = quote do:
        `rdepCall`
        `reloadInit`

    if reloadNode.len > 0:
      # find load call in reloadNode
      var dataIdent = genSym(nskVar, "data")
      var compNameIdent = ^compName
      var reloadBody = quote do:
        var `dataIdent` = register(`compNameIdent`)
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
      readyBody.insert(0, reloadBody)

    # once
    if onceNode.isNil:
      onceNode = quote do:
        discard

    var isNewInstanceNode = quote do:
      var watcher = self.get_node("/root/Watcher")
      if watcher.isNil:
        raise newException(Defect, "Watcher not found")

      var is_new_instance = watcher.call("is_new_instance", ($(self.get_path())).toVariant).asBool()
      if is_new_instance:
        `onceNode`

    readyBody.insert(0, isNewInstanceNode)

  else: # not does_reload
    if not reloadNode.isNil and reloadNode.len > 0:
      # ignore load call in reloadNode
      # add everything else to ready method
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
      readyBody.insert(0, reloadBody)

    # once
    if onceNode.isNil:
      onceNode = quote do:
        discard

    readyBody.insert(0, onceNode)

    # add dependencies loading code into readyBody
    if not dependenciesNode.isNil:
      for section in dependenciesNode:
        case section.kind
          of nnkCall:
            for stmt in section[1]:
              readyBody.add stmt
          else:
            gdnimDefect(&"Unexpected {section.kind} in dependencies definition.\n\t{section.repr}")

  for stmt in gdObjBodyRest:
    gdObjBody.add stmt

  if godotModules.len > 0:
    result.insert(0, godotApiImports)
  if compModules.len > 0 and not defined(does_reload):
    result.insert(0, compModules)
  #echo &"{importedGdModules = }"
  #echo &"{importedCompModules = }"
  #echo result.repr
