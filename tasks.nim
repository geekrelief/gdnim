import godotapigen
from sequtils import toSeq, filter, mapIt
import times
import anycase
import threadpool

const appDir = "app" #godot project directory
const compDir = "components" # your components that hot reload
# generated files
const dllDir = appDir & "/_dlls"
const gdnsDir = appDir & "/_gdns"
const tscnDir = appDir & "/_tscn" # only need to touch these

proc execOrQuit(command:string) =
  if execShellCmd(command) != 0: quit(QuitFailure)

task gdengine_update, "update the 3.2 custom branch with changes from upstream":
  var branches = @["3.2_script_data_error", "3.2_gdnative_unload", "3.2_filter_import"]

  var godotSrcPath = getEnv("GODOT_SRC_PATH")
  if godotSrcPath == "":
    echo "Please set GODOT_SRC_PATH env variable to godot source directory."
    quit()

  var projDir = getCurrentDir()
  setCurrentDir(godotSrcPath)

  execOrQuit("git checkout 3.2")
  execOrQuit("git pull")

  for branch in branches:
    execOrQuit(&"git checkout {branch}")
    execOrQuit("git rebase 3.2")

  execOrQuit("git branch -D 3.2_custom")
  execOrQuit("git checkout -b 3.2_custom 3.2")

  for branch in branches:
    execOrQuit(&"git merge {branch}")

  execOrQuit("git push origin :3.2_custom")
  execOrQuit("git push origin 3.2_custom")

  setCurrentDir(projDir)

task gdengine, "build the godot engine, default with debugging and tools args:\tupstream: updates the branch with branches in gdengine_upstream task\tclean: clean build\texport export build without tools\trelease: relead build without debugging":
  if "update" in args: gdengineUpdateTask()

  var godotSrcPath = getEnv("GODOT_SRC_PATH")
  if godotSrcPath == "":
    echo "Please set GODOT_SRC_PATH env variable to godot source directory."
    quit()

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
    if "release" in args :
      #flags = "target=release_debug debug_symbols=full vsproj=yes"
      flags = "target=release_debug"
      info &= "release"
    else:
      flags = "target=debug debug_symbols=full vsproj=yes"
      info &= "debug"

  var projDir = getCurrentDir()
  setCurrentDir(godotSrcPath)

  discard execShellCmd "git checkout 3.2_custom"

  if "clean" in args:
    echo "Cleaning godot engine"
    discard execShellCmd "git clean -fdx" # clean generated files
    discard execShellCmd &"scons -c {flags}"

  var threads = if "fast" in args: "11" else: "6"
  echo &"Compiling godot {info} threads:{threads}"
  discard execShellCmd &"scons -j{threads}  p=windows bits=64 {flags}"
  setCurrentDir(projDir)

task gd, "launches terminal with godot project\n-e option to open editor\nlast argument is a scene to open\n":
  var gdbin = if "debug" in getSharedFlags(): getEnv("GODOT_TOOLS_DEBUG_BIN") else: getEnv("GODOT_TOOLS_RELEASE_BIN")
  if gdbin == "":
    echo "Please set GODOT_TOOLS_DEBUG_BIN and/or GODOT_TOOLS_RELEASE_BIN to the path to the godot editor."
    quit(1)

  var curDir = getCurrentDir()
  var projDir = "app"

  var scn = ""
  if args.len == 1:
    scn = args[0] & ".tscn"

  discard execShellCmd &"wt -d {curDir} {gdbin} -e --path {projDir} {scn}"

task cleanapi, "clean generated api":
  removeDir "logs"
  removeDir "deps/godotapi"

task genapi, "generate the godot api bindings":
  let godotBin = if existsEnv "GODOT_BIN":
    getEnv "GODOT_BIN"
  else:
    echo "GODOT_BIN environment variable is not set"
    quit -1

  cleanapiTask()

  let apidir = "deps/godotapi"
  createDir apidir
  let cmd = &"{godotBin} --gdnative-generate-json-api {apidir}/api.json"
  if (execShellCmd cmd) != 0:
    echo &"Could not generate api with '{cmd}'"
    quit -1
  genApi(apidir, apidir / "api.json")

task watcher, "build the watcher dll":
  var flags = getSharedFlags()
  if ("force" in flags) or not fileExists(&"{dllDir}/watcher.dll") or (getLastModificationTime("watcher.nim") > getLastModificationTime(&"{dllDir}/watcher.dll")):
    echo execnim("--path:deps --path:deps/godot", flags, &"{dllDir}/watcher.dll", "watcher.nim")
  else:
    echo "Watcher is unchanged"

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

[node name="$2" type="Node"]
script = ExtResource( 1 )
"""

proc buildComp(compName:string, sharedFlags:string, buildSettings:Table[string, bool]):string {.gcsafe.} =
  let safeDllFilePath = &"{dllDir}/{compName}_safe.dll"
  let hotDllFilePath = &"{dllDir}/{compName}.dll"
  let nimFilePath = &"{compDir}/{compName}.nim"

  if not fileExists(nimFilePath):
    result &= &"Error compiling {nimFilePath} [Not Found]"
    return

  let gdns = &"{gdnsDir}/{compName}.gdns"
  if not fileExists(gdns):
    var f = open(gdns, fmWrite)
    f.write(gdns_template % [compName, compName.pascal, relativePath(dllDir, appDir)])
    f.close()
    echo &"generated {gdns}"

  let tscn = &"{tscnDir}/{compName}.tscn"
  if not fileExists(tscn):
    var f = open(tscn, fmWrite)
    f.write(tscn_template % [compName, compName.pascal, relativePath(gdnsDir, appDir)])
    f.close()
    echo &"generated {tscn}"

  if buildSettings["noCheck"] or
    (not buildSettings["newOnly"]) or
    (buildSettings["newOnly"] and (
      (not fileExists(hotDllFilePath) and not fileExists(safeDllFilePath)) or
      (fileExists(safeDllFilePath) and getLastModificationTime(nimFilePath) > getLastModificationTime(safeDllFilePath)) or
      (fileExists(hotDllFilePath) and not fileExists(safeDllFilePath) and getLastModificationTime(nimFilePath) > getLastModificationTime(hotDllFilePath))
    )):
    result &= &">>> Build {compName} <<<"
    result &= execnim("--path:deps --path:deps/godot --path:.", sharedFlags, &"{safeDllFilePath}", &"{nimFilePath}")

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

  var nospawn = "nospawn" in otherFlagsTable

  if not (compName == ""):
    compName = compName.snake
    echo buildComp(compName, sharedFlags, buildSettings)
  else:
    # compile all the comps
    if nospawn:
      for compFilename in walkFiles(&"{compDir}/*.nim"):
        echo buildComp(splitFile(compFilename)[1].snake, sharedFlags, buildSettings)
    else:
      var res = newSeq[FlowVar[string]]()
      for compFilename in walkFiles(&"{compDir}/*.nim"):
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

task help, "display list of tasks":
  echo "Call build with a task:"
  for i in 0..<tasks.len:
    echo "  ", tasks[i].task_name, " : ", tasks[i].description

task cleanbuild, "Rebuild all":
  cleandllTask()
  removeDir(pdbdir) # created if vcc and debug flags are used
  setFlag("force")
  setFlag("move")
  watcherTask()
  compTask()

task c, "Recompile all components":
  compTask()

task cm, "Recompile and move all components":
  setFlag("move")
  compTask()
