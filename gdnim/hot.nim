import macros, strformat, strutils, os, sets
import msgpack4nim, options, optionsutils
export msgpack4nim, options, optionsutils

const does_reload* {.booldefine.}: bool = true
const is_tool* {.booldefine.}: bool = false

proc `^`(s:string):NimNode {.inline.} =
  ident(s)

type
  GDNimDefect = object of Defect
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

# loads args from buffer where args are tuples of properties and whether they should be assigned
macro loadHelper(data:typed, args:varargs[typed]):untyped =
  when defined(does_reload):
    var stmts = newStmtList()
    var buffer = data
    if getTypeInst(data).repr == "seq[byte]":
      buffer = genSym(nskVar, "buffer")
      stmts.add newVarStmt(buffer, newCall(newDotExpr(^"MsgStream", ^"init"), nnkCast.newTree(^"string", data)))

    for arg in args:
      var prop = arg[0]
      var isAssigned = arg[1]
      var unpackVar:NimNode = genSym(nskVar)
      var propType:NimNode = getTypeInst(prop)

      stmts.add quote do:
        var `unpackVar`:`propType`
        `buffer`.unpack(`unpackVar`)

      stmts.add case prop.kind
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

## gdnim macro
# parses for hot reloading,
# produces a gdobj for godot-nim to parse
const compsDir {.strdefine.}:string  = "components"
const depsDir {.strdefine.}:string  = "deps"
var godotapiDir {.compileTime.}:string = depsDir & "/godotapi"

proc classStyleToCompStyle(className: string): string =
  var s:string = className
  if s[^2].isDigit() and s.endsWith("D"):
    s[^1] = 'd'

  result = $(s[0].toLowerAscii())
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

proc gdnimDefect(msg:string) =
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

proc isGodotApi(name:string):bool =
  var classFilePath = godotapiDir&"/"&classStyleToCompStyle(name)&".nim"
  return fileExists(classFilePath)

proc isComponent(name:string):bool =
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

macro nilRef*(p:typed):untyped =
  var t = getType(p)
  var k = typekind(t)
  result = case k
    of ntyRef:
      var ap = p.copyNimTree()
      quote do:
        `ap` = nil
    else: quote do: discard
]#

macro gdnim*(ast:varargs[untyped]) =
  result = newStmtList()
  var astInfix = ast[0]
  var compName = classStyleToCompStyle(astInfix[1].strVal)
  var baseClassName = astInfix[2].strVal
  var baseClassFileName = classStyleToCompStyle(baseClassName)
  var baseClassFilePath = godotapiDir&"/"&baseClassFileName&".nim"
  var gdObjBody = newStmtList()
  if fileExists(baseClassFilePath):
    var gdobj = nnkCommand.newTree(^"gdobj", astInfix)
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

  var unloadNode:NimNode
  var reloadNode:NimNode
  var dependenciesNode:NimNode
  var enterTreeNode:NimNode

  var astBody = ast[^1]
  # parse
  var gdObjBodyRest = newStmtList()
  for node in astBody:
    case node.kind
      of nnkCommand:
        var commandName = node[0]
        if commandName == ^"godotapi":
          for godotModule in node[1..^1]:
            var cGodotModule = ^(classStyleToCompStyle(godotModule.repr))
            godotModules.add cGodotModule
        else:
          gdObjBody.add(node)
      of nnkVarSection:
        var identDef = node[0]
        var name:string
        case identDef[0].kind
          of nnkIdent:
            name = identDef[0].strVal
          of nnkPragmaExpr:
            name = identDef[0][0].strVal
          else:
            gdnimDefect(&"Unhandled node kind {identDef[0].kind}: {lineInfo(identDef)}\n{node.astGenRepr}")

        var typName:string
        if not (identDef[1].kind == nnkEmpty):
          typName = identDef[1].repr
        else:
          if identDef[2].kind == nnkEmpty:
            gdnimDefect(&"Unknown type for field {name}: {lineInfo(identDef)}\n{identDef[1].repr}")
          else:
            typeUnknownPropertyNames.incl name
            gdObjBody.add(node)
            continue

        if typName in standardTypes:
          gdObjBody.add(node)
        else:
          var filename = classStyleToCompStyle(typName)
          if isGodotApi(typName):
            gdObjBody.add(node)
            if filename notin importedGdModules:
              importedGdModules.incl filename
              godotModules.add ^filename
              godotPropertyNames.incl name
          elif isComponent(typName):
            # need to replace the type of the property with gd base class
            # if defined(does_reload):
            if filename notin importedCompModules:
              importedCompModules.incl filename
              compModules.add ^filename
              compPropertyNames.incl name
          else:
            typeUnknownPropertyNames.incl name
            gdObjBody.add(node)
      of nnkCall:
        var callName = node[0]
        if callName == ^"unload":
          unloadNode = node[^1]
        elif callName == ^"reload":
          reloadNode = node[^1]
        elif callName == ^"dependencies":
          dependenciesNode = node[^1]
        else:
          gdObjBodyRest.add(node)
      of nnkMethodDef:
        if node[0] == ^"enter_tree":
          enterTreeNode = node
        else:
          gdObjBodyRest.add(node)
      else:
        gdObjBodyRest.add(node)

  #generate
  when defined(does_reload):
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

  var dependenciesCompNames:seq[string]
  if not dependenciesNode.isNil:
    var depreloadBody = newStmtList()
    var depreloadCase = nnkCaseStmt.newTree().add ^"compName"
    depreloadBody.add depreloadCase
    for section in dependenciesNode:
      case section.kind
        of nnkCall:
          var compName = section[0].strVal
          dependenciesCompNames.add compName
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
          var ofBranch = nnkOfBranch.newTree().add newStrLitNode(compName)
          ofBranch.add newStmtList(quote do:
                        if isUnloading:
                          `unloadStmts`
                        else:
                          `sectionStmts`)
          depreloadCase.add ofBranch
        else:
          gdnimDefect(&"Unexpected {section.kind} in dependencies definition.")
    depreloadCase.add nnkElse.newTree(nnkDiscardStmt.newTree(newEmptyNode()))
    var hot_depreload = newProc(name = ^"hot_depreload",
      params = @[newEmptyNode(), newIdentDefs(^"compName", ^"string"), newIdentDefs(^"isUnloading", ^"bool")],
      body = depreloadBody, pragmas = nnkPragma.newTree(^"gdExport"))
    gdObjBody.add(hot_depreload)

  when defined(does_reload):
    if reloadNode.isNil:
      reloadNode = newStmtList()

    if not reloadNode.isNil:
      if enterTreeNode.isNil:
        enterTreeNode = nnkMethodDef.newTree(^"enter_tree", newEmptyNode(), newEmptyNode(),
          nnkFormalParams.newTree(newEmptyNode()), newEmptyNode(), newEmptyNode(), newStmtList())
      var enterTreeBody = enterTreeNode.body
      # find load call in reloadNode
      var reloadBody = newStmtList()
      for node in reloadNode:
        case node.kind:
          of nnkCall:
            if node[0] == ^"load":
              var compNameIdent = ^compName
              reloadBody.add quote do:
                var data = register(`compNameIdent`)
                data?.`node`
            else:
              reloadBody.add node
          else:
              reloadBody.add node
      enterTreeBody.insert(0, reloadBody)

      if dependenciesCompNames.len > 0:
        var rdepCall = nnkCall.newTree(^"register_dependencies", ^compName)
        var reloadInit = newStmtList()
        for dcompName in dependenciesCompNames:
          rdepCall.add ^dcompName
          reloadInit.add quote do:
            self.hot_depreload(`dcompName`, false)
        reloadBody
          .add(rdepCall)
          .add(reloadInit)
      gdObjBody.add enterTreeNode
  else:
    gdnimDefect("need to implement when not reload, initializations")

  for stmt in gdObjBodyRest:
    gdObjBody.add stmt

  if godotModules.len > 0:
    result.insert(0, godotApiImports)
  if compModules.len > 0 and not defined(does_reload):
    result.insert(0, compModules)
  #echo &"{importedGdModules = }"
  #echo &"{importedCompModules = }"
  #echo result.repr