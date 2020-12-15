import godotapigen
from sequtils import toSeq, filter, mapIt
import times
import anycase
import threadpool
import strutils

const nim_template = """
import godot
import godotapi / [$3]
import hot

gdobj $2 of $4:

  method enter_tree() =
    discard register($1)

  proc reload():seq[byte] {.gdExport.} =
    self.queue_free()
"""

const gdns_template = """
[gd_resource type="NativeScript" load_steps=2 format=2]

[sub_resource type="GDNativeLibrary" id=1]
entry/Windows.64 = "res://$3/$1.dll"
dependency/Windows.64 = [  ]

[resource]
resource_name = "$2"
class_name = "$2"
library = SubResource( 1 )
"""

const tscn_template = """
[gd_scene load_steps=2 format=2]

[ext_resource path="res://$3/$1.gdns" type="Script" id=1]

[node name="$2" type="$4"]
script = ExtResource( 1 )
"""

let appDir = config.getSectionValue("Dir", "app")
let compsDir = config.getSectionValue("Dir", "comps")
let depsDir = config.getSectionValue("Dir", "deps")
let depsGodotDir = config.getSectionValue("Dir", "deps_godot")

# generated files
let baseDllDir = config.getSectionValue("App", "dll")
let dllDir = appDir / baseDllDir
let gdnsDir = appDir / config.getSectionValue("App", "gdns")
let tscnDir = appDir / config.getSectionValue("App", "tscn")

let gd_src = config.getSectionValue("Godot", "src")
let gd_base_branch = config.getSectionValue("Godot", "base_branch")
let gd_build_branch = config.getSectionValue("Godot", "build_branch")
let gd_branches = config.getSectionValue("Godot", "merge_branches").split(",")
let gd_platform = config.getSectionValue("Godot", "platform")
let gd_bits = config.getSectionValue("Godot", "bits")
let gd_bin = config.getSectionValue("Godot", "bin")
let gd_tools_debug_bin = config.getSectionValue("Godot", "tools_debug_bin")
let gd_tools_release_bin = config.getSectionValue("Godot", "tools_release_bin")


proc genGdns(name:string) =
  let gdns = &"{gdnsDir}/{name}.gdns"
  if not fileExists(gdns):
    var f = open(gdns, fmWrite)
    f.write(gdns_template % [name, name.pascal, relativePath(dllDir, appDir)])
    f.close()
    echo &"generated {gdns}"

proc execOrQuit(command:string) =
  if execShellCmd(command) != 0: quit(QuitFailure)

task prereqs, "Install prerequisites":
  execOrQuit("nimble install compiler")
  execOrQuit("nimble install anycase")
  execOrQuit("nimble install msgpack4nim")
  execOrQuit("nimble install https://github.com/PMunch/nim-optionsutils")

task gdengine_update, "update the 3.2 custom branch with changes from upstream":

  var godotSrcPath = getEnv("GODOT_SRC_PATH")
  if godotSrcPath == "":
    echo "Please set GODOT_SRC_PATH env variable to godot source directory."
    quit()

  var projDir = getCurrentDir()
  setCurrentDir(godotSrcPath)

  execOrQuit(&"git checkout {gd_base_branch}")
  execOrQuit("git pull")

  for branch in gd_branches:
    execOrQuit(&"git checkout {branch}")
    execOrQuit(&"git rebase {gd_base_branch}")

  execOrQuit(&"git branch -D {gd_build_branch}")
  execOrQuit(&"git checkout -b {gd_build_branch} {gd_base_branch}")

  for branch in gd_branches:
    execOrQuit(&"git merge {branch}")

  execOrQuit(&"git push origin :{gd_build_branch}")
  execOrQuit(&"git push origin {gd_build_branch}")

  setCurrentDir(projDir)

task gdengine, "build the godot engine, default with debugging and tools args:\n\tupdate: updates the branch with branches in gdengine_upstream task\n\tclean: clean build\n\texport export build without tools\n\trelease: relead build without debugging":
  if "update" in args: gdengineUpdateTask()

  # run scons --help to see godot flags
  var flags = ""
  var info = ""
  if "export" in args:
    info &= "export, "
    if "release" in args:
      flags = "tools=no target=release"
      info &= "release"
    else:
      flags = "tools=no target=debug"
      info &= "debug"
  else:
    info &= "tools, "
    if "debug" in args :
      flags = "target=debug debug_symbols=full vsproj=yes"
      info &= "debug"
    else:
      flags = "target=release_debug"
      info &= "release"

  var projDir = getCurrentDir()
  setCurrentDir(gd_src)

  discard execShellCmd &"git checkout {gd_build_branch}"

  if "clean" in args:
    echo "Cleaning godot engine"
    discard execShellCmd "git clean -fdx" # clean generated files
    discard execShellCmd &"scons -c {flags}"

  var threads = countProcessors()
  echo &"Compiling godot {info} threads:{threads}"
  discard execShellCmd &"scons -j{threads}  p={gd_platform} bits={gd_bits} {flags}"
  setCurrentDir(projDir)

task gd, "launches terminal with godot project\n\toptional argument for scene to open":
  var gdbin = if "debug" in getSharedFlags(): gd_tools_debug_bin else: gd_tools_release_bin

  var curDir = getCurrentDir()
  var projDir = "app"

  var scn = ""
  if args.len == 1:
    scn = args[0] & ".tscn"

  discard execShellCmd &"wt -d {curDir} {gdbin} -e --path {projDir} {scn}"

task cleanapi, "clean generated api":
  removeDir "logs"
  removeDir(depsDir / "godotapi")

task genapi, "generate the godot api bindings":
  cleanapiTask()

  let apidir = depsDir / "godotapi"
  createDir apidir
  let cmd = &"{gd_bin} --gdnative-generate-json-api {apidir}/api.json"
  if (execShellCmd cmd) != 0:
    echo &"Could not generate api with '{cmd}'"
    quit -1
  genApi(apidir, apidir / "api.json")
  removeFile(apidir / "api.json")

proc buildWatcher():string =
  {.cast(gcsafe).}:
    var flags = getSharedFlags()
    if ("force" in flags) or not fileExists(&"{dllDir}/watcher.dll") or (getLastModificationTime("watcher.nim") > getLastModificationTime(&"{dllDir}/watcher.dll")):
      result = execnim(&"--path:{depsDir} --path:{depsDir}/{depsGodotDir} --define:dllDir:{baseDllDir}", flags, &"{dllDir}/watcher.dll", "watcher.nim")
    else:
      result = "Watcher is unchanged"

task watcher, "build the watcher dll":
  genGdns("watcher")
  echo buildWatcher()

# compiling with gcc, vcc spitting out warnings about incompatible pointer types with NimGodotObj, which was added for gc:arc
# include to include libgcc_s_seh-1.dll, libwinpthread-1.dll in the app/_dlls folder for project to run
const gccDlls = @["libgcc_s_seh-1", "libwinpthread-1"]

final:
  if taskCompilerFlagsTable["cc"] == allCompilerFlagsTable["gcc"]:
    echo ">>> gcc dlls check <<<"
    for dll in gccDlls:
      if not fileExists(&"{dllDir}/{dll}.dll"):
        echo &"Missing {dllDir}/{dll}.dll, please copy from gcc/bin"


task cleandll, "clean the dlls, arguments are component names, default all non-gcc dlls":
  var dllPaths:seq[string]
  if args.len > 1:
    var seqDllPaths = args.mapIt(toSeq(walkFiles(&"{dllDir}/{it}*.*")))
    for paths in seqDllPaths:
      dllPaths &= paths
  else:
    dllPaths = toSeq(walkFiles(&"{dllDir}/*.*"))

  dllPaths = dllPaths.filterIt(splitFile(it)[1] notin gccDlls)

  for dllPath in dllPaths:
    echo &"rm {dllPath}"
    removeFile dllPath

task gencomp, "generate a component template (nim, gdns, tscn files), pass in the component name and  base class name in snake case:":
  var compName = args[0]
  var compClassName = compName.pascal
  var baseClassModuleName = args[1].tolower
  var baseClassName = baseClassModuleName.pascal
  if baseClassName.endsWith("1d") or baseClassName.endsWith("2d") or baseClassName.endsWith("3d"):
    baseClassName[^1] = 'D'

  let nim = &"{compsDir}/{compName}.nim"
  if not fileExists(nim):
    var f = open(nim, fmWrite)
    f.write(nim_template % [compName, compClassName, baseClassModuleName, baseClassName])
    f.close()
    echo &"generated {nim}"

  genGdns(compName)

  let tscn = &"{tscnDir}/{compName}.tscn"
  if not fileExists(tscn):
    var f = open(tscn, fmWrite)
    f.write(tscn_template % [compName, compClassName, relativePath(gdnsDir, appDir), baseClassName])
    f.close()
    echo &"generated {tscn}"


proc buildComp(compName:string, sharedFlags:string, buildSettings:Table[string, bool]):string =
  {.cast(gcsafe).}:
    let safeDllFilePath = &"{dllDir}/{compName}_safe.dll"
    let hotDllFilePath = &"{dllDir}/{compName}.dll"
    let nimFilePath = &"{compsDir}/{compName}.nim"

    if not fileExists(nimFilePath):
      result &= &"Error compiling {nimFilePath} [Not Found]"
      return

    if buildSettings["noCheck"] or
      (not buildSettings["newOnly"]) or
      (buildSettings["newOnly"] and (
        (not fileExists(hotDllFilePath) and not fileExists(safeDllFilePath)) or
        (fileExists(safeDllFilePath) and getLastModificationTime(nimFilePath) > getLastModificationTime(safeDllFilePath)) or
        (fileExists(hotDllFilePath) and not fileExists(safeDllFilePath) and getLastModificationTime(nimFilePath) > getLastModificationTime(hotDllFilePath))
      )):
      result &= &">>> Build {compName} <<<"
      result &= execnim(&"--path:{depsDir} --path:{depsDir}/{depsGodotDir} --path:.", sharedFlags, &"{safeDllFilePath}", &"{nimFilePath}")

    if fileExists(safeDllFilePath) and getLastModificationTime(nimFilePath) < getLastModificationTime(safeDllFilePath) and
      (not fileExists(hotDllFilePath) or buildSettings["move"]):
      moveFile(safeDllFilePath, hotDllFilePath)
      result &= ">>> dll moved safe to hot <<<"

# components are named {compName}_safe.dll and
# are loaded by the watcher.dll via resources. At runtime, the watcher.dll will copy
# the {compName}_safe.dll to the {compName}.dll and monitor the _dlls
# folder to see if _safe.dll is rebuilt.
task comp, "build component and generate a gdns file\n\tno component name means all components are rebuilt\n\tmove safe to hot with 'move' or 'm' flag (e.g.) build -m target\n\t--force or --f force rebuilds\n\t--nocheck or --nc skips compile without dll check but not force rebuilt":
  var sharedFlags = getSharedFlags()
  var buildSettings: Table[string, bool]
  buildSettings["move"] = "move" in otherFlagsTable
  buildSettings["newOnly"] = not ("force" in sharedFlags)
  buildSettings["noCheck"] = "nocheck" in otherFlagsTable

  if not (compName == ""):
    compName = compName.snake
    echo buildComp(compName, sharedFlags, buildSettings)
  else:
    # compile all the comps
    var res = newSeq[FlowVar[string]]()
    for compFilename in walkFiles(&"{compsDir}/*.nim"):
      res.add(spawn buildComp(splitFile(compFilename)[1].snake, sharedFlags, buildSettings))
    sync()
    for f in res:
      echo ^f

task flags, "display the flags used for compiling components":
  echo ">>> Task  compiler flags <<<"
  for flag in taskCompilerFlagsTable.keys:
    echo &"\t{flag} {taskCompilerFlagsTable[flag]}"
  echo ">>> Other flags <<<"
  for flag in otherFlagsTable.keys:
    echo &"\t{flag} {otherFlagsTable[flag]}"

task cleanbuild, "Rebuild all":
  cleandllTask()
  # created if vcc and debug flags are used
  removeDir(config.getSectionValue("VCC", "pdbdir"))
  setFlag("force")
  setFlag("move")

  var startTime = cpuTime()
  # watcher task
  genGdns("watcher")

  var res = newSeq[FlowVar[string]]()

  res.add(spawn buildWatcher())

  var compileCount = 1

  # comp task
  var sharedFlags = getSharedFlags()
  var buildSettings: Table[string, bool]
  buildSettings["move"] = "move" in otherFlagsTable
  buildSettings["newOnly"] = not ("force" in sharedFlags)
  buildSettings["noCheck"] = "nocheck" in otherFlagsTable

  for compFilename in walkFiles(&"{compsDir}/*.nim"):
    inc compileCount
    res.add(spawn buildComp(splitFile(compFilename)[1].snake, sharedFlags, buildSettings))
  sync()

  var successes = 0
  var failures:seq[string]
  for f in res:
    var output = ^f
    if "[SuccessX]" in output:
      inc successes
    else:
      failures.add output

  if successes == compileCount:
    echo "=== Build OK! === ", cpuTime() - startTime, " seconds"
  else:
    echo "=== >>> Build Failed >>> ==="
    for f in failures:
      echo f
    echo "=== <<< Build Failed <<< ==="

task help, "display list of tasks":
  echo "Call build with a task:"
  for i in 0..<tasks.len:
    echo "  ", tasks[i].task_name, " : ", tasks[i].description