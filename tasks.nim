# nim says anycase is unused, but pascal and snake are from anycase
{.push warning[UnusedImport]: off.}
from sequtils import toSeq, filter, mapIt
import anycase, threadpool

const script_nim_template = """
import gdnim, godotapi / [$1]

gdnim $2 of $3:

  unload:
    save()

  reload:
    load()
"""

const tool_nim_template = """
import godot, godotapi / [editor_plugin, resource_loader]

#[
WARNING: GDNative reloading of tool scripts is broken.
If you enable and disable the plugin, or unfocus the editor window while
the plugin is enabled which will cause the plugin to reload, you might
get a crash. You also might get warnings about leaked resources, when the
plugin is enabled while the editor is closed.

As a workaround, gdnlib's reloadable flag is set to false, so the
plugin will not reload when the editor is unfocused. To see your
changes, close the editor and reopen after compilation.
]#

gdobj($2 of EditorPlugin, tool):

  method enter_tree() =
    discard

  method exit_tree() =
    discard
"""

const gdns_template = """
[gd_resource type="NativeScript" load_steps=2 format=2]

[ext_resource path="res://$3/$1.gdnlib" type="GDNativeLibrary" id=1]

[resource]
resource_name = "$2"
class_name = "$2"
library = ExtResource( 1 )
"""

const gdnlib_template = """
[general]

singleton=false
load_once=true
symbol_prefix="godot_"
reloadable=$4

[entry]

Android.arm64-v8a="res://$3/lib$1.so"
Android.armeabi="res://$3/lib$1.so"
Android.armeabi-v7a="res://$3/lib$1.so"
Android.x86="res://$3/lib$1.so"
Android.x86_64="res://$3/lib$1.so"
Windows.64 = "res://$3/$1.dll"
X11.64 = "res://$3/lib$1.so"
OSX.64 = "res://$3/$1.dylib"

[dependencies]

Android.arm64-v8a=[  ]
Android.armeabi=[  ]
Android.armeabi-v7a=[  ]
Android.x86=[  ]
Android.x86_64=[  ]
Windows.64=[  ]
X11.64=[  ]
OSX.64=[  ]
"""

const tscn_template = """
[gd_scene load_steps=2 format=2]

[ext_resource path="res://$3/$1.gdns" type="Script" id=1]

[node name="$2" type="$4"]
script = ExtResource( 1 )
"""

const plugin_cfg_template = """
[plugin]

name="$1"
description=""
author=""
version=""
script="$1.gdns"

"""
let does_reload = config.getSectionValue("Hot", "reload") == "on"

let appDir = config.getSectionValue("Dir", "app")
let compsDir = config.getSectionValue("Dir", "comps")
let depsDir = config.getSectionValue("Dir", "deps")
let depsGodotDir = config.getSectionValue("Dir", "deps_godot")
let gdpathFlags = &"--path:gdnim --path:{depsDir} --path:{depsDir}/{depsGodotDir} "

# generated files
let baseDllDir = config.getSectionValue("App", "dll")
let dllDir = appDir / baseDllDir
let gdnsDir = appDir / config.getSectionValue("App", "gdns")
let gdnlibDir = appDir / config.getSectionValue("App", "gdnlib")
let baseTscnDir = config.getSectionValue("App", "tscn")
let tscnDir = appDir / baseTscnDir

let gd_scons_flags = config.getSectionValue("Godot", "scons_flags")

let gd_src = expandTilde(config.getSectionValue("Godot", "src"))
let gd_base_branch = config.getSectionValue("Godot", "base_branch")
let gd_build_branch = config.getSectionValue("Godot", "build_branch")
let gd_branches = config.getSectionValue("Godot", "merge_branches").split(",")
let gd_platform = config.getSectionValue("Godot", "platform")

case gd_platform:
  of "windows", "android", "linuxbsd", "x11", "macosx": discard
  else: quit(&"Invalid build.ini: platform =\"{gd_platform}\"", QuitFailure)

#let gd_arch = config.getSectionValue("Godot", "arch")
let gd_bits = config.getSectionValue("Godot", "bits")
let gd_tools_debug_bin = expandTilde(config.getSectionValue("Godot", "tools_debug_bin"))
let gd_tools_release_bin = expandTilde(config.getSectionValue("Godot", "tools_release_bin"))

var cwatch_interval = parseInt(config.getSectionValue("Build", "cwatch_interval"))
if cwatch_interval == 0: cwatch_interval = 300

let dllPrefix = case gd_platform
  of "android", "linuxbsd", "x11": "lib"
  else: ""

let dllExt = case gd_platform
  of "windows": "dll"
  of "android", "linuxbsd", "x11": "so"
  of "macosx": "dylib"
  else: "unknown platform"

proc genGdns(name: string, isTool: bool = false) =

  var comp = &"{compsDir}/{name}.nim"
  var gdns = &"{gdnsDir}/{name}.gdns"
  var gdnlib = &"{gdnlibDir}/{name}.gdnlib"
  if not fileExists(comp):
    # might be a tool or watcher
    comp = &"{compsDir}/tools/{name}.nim"
    if fileExists(comp):
      gdns = &"{appDir}/addons/{name}/{name}.gdns"
      gdnlib = &"{appDir}/addons/{name}/{name}.gdnlib"
    else:
      comp = &"gdnim/watcher.nim"
      gdns = &"{gdnsDir}/watcher.gdns"
      gdnlib = &"{gdnlibDir}/watcher.gdnlib"

  if fileExists(comp):
    if not fileExists(gdns):
      var f = open(gdns, fmWrite)
      f.write(gdns_template % [name, name.pascal, relativePath(parentDir(gdnlib), appDir)])
      f.close()
      echo &"generated {gdns}"
    if not fileExists(gdnlib):
      var f = open(gdnlib, fmWrite)
      var reloadable = not isTool
      f.write(gdnlib_template % [name, name.pascal, relativePath(dllDir, appDir), $reloadable])
      f.close()
      echo &"generated {gdnlib}"
  else:
    echo &"genGdns could not find {comp}"
    quit(QuitFailure)

proc execOrQuit(command: string) =
  if execShellCmd(command) != 0: quit(QuitFailure)

task gdengine_update, "update the 3.x custom branch with changes from upstream":

  var projDir = getCurrentDir()
  setCurrentDir(gd_src)

  execOrQuit(&"git checkout {gd_base_branch}")
  execOrQuit("git pull")

  for branch in gd_branches:
    execOrQuit(&"git checkout {branch}")
    execOrQuit(&"git rebase {gd_base_branch}")

  discard execShellCmd(&"git branch -D {gd_build_branch}")
  execOrQuit(&"git checkout -b {gd_build_branch} {gd_base_branch}")

  for branch in gd_branches:
    execOrQuit(&"git merge {branch}")

  if not ("keeplocal" in args):
    execOrQuit(&"git push --force origin {gd_build_branch}")

  setCurrentDir(projDir)

task gdengine, "build the godot engine, default does release build with tools. args:\n\tupdate: updates the branch with branches in gdengine_upstream task\n\tclean: clean build\n\texport: export build without tools\n\tdebug: generates debug build":
  if "update" in args: gdengineUpdateTask()

  # run scons --help to see godot flags
  var flags = ""
  var info = ""
  if "export" in args:
    info &= "export, "
    if "debug" in args:
      flags = "tools=no target=debug"
      info &= "debug"
    else:
      flags = "tools=no target=release"
      info &= "release"
  else:
    info &= "tools, "
    if "debug" in args:
      flags = "target=debug debug_symbols=yes"
      info &= "debug"
    else:
      flags = "target=release_debug"
      info &= "release"

  flags &= &" {gd_scons_flags}"

  var projDir = getCurrentDir()
  setCurrentDir(gd_src)

  discard execShellCmd &"git checkout {gd_build_branch}"

  if "clean" in args:
    echo "Cleaning godot engine"
    discard execShellCmd "git clean -fdx" # clean generated files
    discard execShellCmd &"scons -c {flags}"

  var threads = countProcessors()
  echo &"Compiling godot {info} scons -j{threads}  p={gd_platform} bits={gd_bits} {flags}"
  discard execShellCmd &"scons -j{threads}  p={gd_platform} bits={gd_bits} {flags}"
  setCurrentDir(projDir)

task term, "launches the terminal with cwatch, pass in another arg for second panel":
  if hostOS == "windows":
    var curDir = getCurrentDir()
    var second = ""
    if args.len == 1:
      second = &"cmd /k \".\\build.exe {args[0]}\""

    discard execShellCmd &"wt -d {curDir} ./build cwatch; split-pane -d {curDir} {second}"
  else:
    echo &"not implemented on {hostOS}"

task gd, "launches terminal with godot project\n\toptional argument 'debug' to launch debug godot editor":
  var gdbin = if "debug" in args: gd_tools_debug_bin else: gd_tools_release_bin

  echo &"{gdbin} --verbose -e --path {appDir}"
  discard execShellCmd &"{gdbin} --verbose -e --path {appDir}"

task play, "launches the project without editor\n\toptional argument 'debug' to launch debug godot editor":
  var gdbin = if "debug" in args: gd_tools_debug_bin else: gd_tools_release_bin

  var projDir = "app"

  echo &"{gdbin} --verbose --path {projDir}"
  discard execShellCmd &"{gdbin} --verbose --path {projDir}"

proc checkPrereq(packageName, sourceName: string, verbose: bool = true) =
  var (output, exitCode) = execCmdEx(&"nimble path {packageName}")
  if exitCode != 0:
    echo &"{packageName} is not installed. Installing."
    execOrQuit(&"nimble install {sourceName}")
  else:
    if verbose:
      echo &"{packageName} installed @ {output}"

task genapi, "generate the godot api bindings":
  execOrQuit(&"nim c -r {gdpathFlags} {depsDir}/genapi.nim --ini:{buildini}")
  var ext = if hostOS == "windows": ".exe" else: ""
  removeFile(&"{depsDir}/genapi{ext}")

task prereqs, "Install prerequisites, and calls genapi task":
  let packages = @[
    ("compiler", "compiler"),
    ("msgpack4nim", "msgpack4nim"),
    ("optionsutils", "https://github.com/PMunch/nim-optionsutils")
  ]
  for (packageName, sourceName) in packages:
    checkPrereq(packageName, sourceName)

  genapiTask()

proc buildWatcher(): string =
  {.cast(gcsafe).}:
    var flags = getSharedFlags()
    let dllPath = &"{dllDir}/{dllPrefix}watcher.{dllExt}"
    let watcherPath = "gdnim/watcher.nim"
    if ("force" in flags) or not fileExists(&"{dllPath}") or (getLastModificationTime(watcherPath) > getLastModificationTime(&"{dllPath}")):
      result = execnim(&"{gdpathFlags} --define:dllDir:{baseDllDir} --define:dllPrefix:{dllPrefix} --define:dllExt:{dllExt} --define:baseTscnDir:{baseTscnDir}", flags, &"{dllPath}", watcherPath)
    else:
      result = "Watcher is unchanged"

task watcher, "build the watcher dll":
  genGdns("watcher")
  echo buildWatcher()

# compiling with gcc, vcc spitting out warnings about incompatible pointer types with NimGodotObj, which was added for gc:arc
# include to include libgcc_s_seh-1.dll, libwinpthread-1.dll in the app/_dlls folder for project to run
const gccDlls = @["libgcc_s_seh-1", "libwinpthread-1"]

final:
  if hostOS == "windows":
    if taskCompilerFlagsTable["cc"] == allCompilerFlagsTable["gcc"]:
      var copyFromDeps = false
      var msg = ""
      for dll in gccDlls:
        if not fileExists(&"{dllDir}/{dll}.dll"):
          copyFromDeps = true
          msg &= &"--- Missing {dllDir}\\{dll}.dll! ---\n\tCopying from {depsDir}\\gcc\\windows\\{dll}.dll\n"
          copyFile(&"{depsDir}/gcc/windows/{dll}.dll", &"{dllDir}/{dll}.dll")
      if copyFromDeps:
        echo ">>> gcc dlls check <<<"
        echo msg
        echo "If the app fails to run with the dll(s), try copying from your gcc/bin directory"


task cleandll, "clean the dlls, arguments are component names, default all non-gcc dlls":
  var dllPaths: seq[string]
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

proc getBuildSettings(): BuildSettings =
  result.sharedFlags = getSharedFlags()
  var settingsTable: Table[string, bool]
  settingsTable["move"] = "move" in otherFlagsTable
  settingsTable["newOnly"] = "force" notin result.sharedFlags
  settingsTable["noCheck"] = "nocheck" in otherFlagsTable
  settingsTable["noReload"] = "reload" notin result.sharedFlags
  result.settingsTable = settingsTable

proc safeDllFilePath(compName: string): string =
  &"{dllDir}/{dllPrefix}{compName}_safe.{dllExt}"
proc hotDllFilePath(compName: string): string =
  &"{dllDir}/{dllPrefix}{compName}.{dllExt}"
proc nimFilePath(compName: string): string =
  var nimFilePath = &"{compsDir}/{compName}.nim"
  if not fileExists(nimFilePath):
    nimFilePath = &"{compsDir}/tools/{compName}.nim"
  nimFilePath
proc gdnsFilePath(compName: string): string =
  &"{gdnsDir}/{compName}.gdns"
proc gdnlibFilePath(compName: string): string =
  &"{gdnlibDir}/{compName}.gdnlib"
proc tscnFilePath(compName: string): string =
  &"{tscnDir}/{compName}.tscn"

proc shouldBuild(compName: string, buildSettings: BuildSettings): bool =
  let safe = safeDllFilePath(compName)
  let hot = hotDllFilePath(compName)
  let nim = nimFilePath(compName)
  result = buildSettings.settingsTable["noCheck"] or
    (not buildSettings.settingsTable["newOnly"]) or
    (buildSettings.settingsTable["newOnly"] and (
      (not fileExists(hot) and not fileExists(safe)) or
      (fileExists(safe) and getLastModificationTime(nim) > getLastModificationTime(safe)) or
      (fileExists(hot) and not fileExists(safe) and getLastModificationTime(nim) > getLastModificationTime(hot)) or
      (fileExists(safe) and buildSettings.settingsTable["move"])
    ))

proc buildComp(compName: string, buildSettings: BuildSettings): string =
  {.cast(gcsafe).}:
    let safe = safeDllFilePath(compName)
    let hot = hotDllFilePath(compName)
    let nim = nimFilePath(compName)

    if not fileExists(nim):
      result &= &"Error: '{compName}' not found in components or components/tools"
      return

    genGdns(compName)

    if shouldBuild(compName, buildSettings):
      result &= &">>> Build {compName} <<<\n"
      result &= execnim(&"{gdpathFlags} --skipParentCfg:on --path:.", buildSettings.sharedFlags, &"{safe}", &"{nim}")

    if fileExists(safe) and getLastModificationTime(nim) < getLastModificationTime(safe) and
      (not fileExists(hot) or buildSettings.settingsTable["move"]) or (fileExists(safe) and buildSettings.settingsTable["noReload"]):
      moveFile(safe, hot)
      result &= ">>> dll moved safe to hot <<<"

proc buildAllComps(res: var seq[FlowVar[string]], buildSettings: BuildSettings): int =
  var count = 0
  echo "building components: "
  for compPath in walkFiles(&"{compsDir}/*.nim"):
    inc count
    var compName = splitFile(compPath)[1].snake
    if shouldBuild(compName, buildSettings):
      echo "  " & compName
      res.add(spawn buildComp(compName, buildSettings))
  for compPath in walkFiles(&"{compsDir}/tools/*.nim"):
    inc count
    var compName = splitFile(compPath)[1].snake
    if shouldBuild(compName, buildSettings):
      echo "  " & compName
      res.add(spawn buildComp(compName, buildSettings))
  count


task gencomp, "generate a component template (nim, gdns, gdnlib, tscn files), pass in the component name and  base class name in snake case\n\tUsage: ./build gencomp [notscn] comp_name base_node":

  var compName: string
  var baseClassModuleName: string
  case args.len:
    of 2:
      compName = args[0]
      baseClassModuleName = args[1].tolower
    of 3:
      compName = args[1]
      baseClassModuleName = args[2].tolower
    else:
      echo "Usage: ./build gencomp [notscn] comp_name base_node"
      echo "Example: ./build gencomp player kinematic_body_2d"
      echo "Example without tscn: ./build gencomp notscn effect animated_sprite"
      quit()

  var compClassName = compName.pascal
  var baseClassName = baseClassModuleName.pascal
  if baseClassName[^2].isDigit and baseClassName.endsWith("d"):
    baseClassName[^1] = 'D'

  baseClassModuleName = case baseClassModuleName:
    of "object": "objects"
    else: baseClassModuleName

  var classFilename = &"{depsDir}/godotapi/{baseClassModuleName}.nim"
  if not fileExists(classFilename):
    echo &"Error generating component. Could not find {classFilename}!"
    quit()

  let nim = &"{compsDir}/{compName}.nim"
  if not fileExists(nim):
    var f = open(nim, fmWrite)
    f.write(script_nim_template % [baseClassModuleName, compClassName, baseClassName])
    f.close()
    echo &"generated {nim}"
  else:
    echo &"{nim} already exists"

  if "notscn" notin args[0]:
    let tscn = &"{tscnDir}/{compName}.tscn"
    if not fileExists(tscn):
      var f = open(tscn, fmWrite)
      f.write(tscn_template % [compName, compClassName, relativePath(gdnsDir, appDir), baseClassName])
      f.close()
      echo &"generated {tscn}"
    else:
      echo &"{tscn} already exists"

  genGdns(compName)

  var buildSettings = getBuildSettings()
  echo &"building {compName}"
  echo buildComp(compName, buildSettings)


task delcomp, "delete a component, removes the nim, gdns, gdnlib, tscn, and dlls associated with the component":
  if args.len != 1:
    echo "Usage: ./build delcomp comp_name"
    quit()

  var compName = args[0]
  var files = @[nimFilePath(compName),
              gdnsFilePath(compName),
              gdnlibFilePath(compName),
              tscnFilePath(compName)]
  for dllFile in walkFiles(&"{dllDir}/{dllPrefix}{compName}*"):
    files.add dllFile

  for filepath in files:
    if fileExists(filepath):
      echo &"removing {filepath}"
      removeFile(filepath)

# components are named {compName}_safe.dll and
# are loaded by the watcher.dll via resources. At runtime, the watcher.dll will copy
# the {compName}_safe.dll to the {compName}.dll and monitor the _dlls
# folder to see if _safe.dll is rebuilt.
task comp, "build component and generate a gdns and a gdnlib files\n\tno component name means all components are rebuilt\n\tmove safe to hot with 'move' or 'm' flag (e.g.) build -m target\n\t--force or --f force rebuilds\n\t--nocheck or --nc skips compile without dll check but not force rebuilt":
  var buildSettings = getBuildSettings()

  if not (compName == ""):
    compName = compName.snake
    echo buildComp(compName, buildSettings)
  else:
    # compile all the comps
    var res = newSeq[FlowVar[string]]()
    discard buildAllComps(res, buildSettings)
    sync()
    for f in res:
      echo ^f

task gentool, "generate a tool / editor plugin scaffold":
  if args.len != 1:
    echo "Usage: ./build gentool tool_name"
    quit()

  var compName = args[0]
  var compClassName = compName.pascal

  let nim = &"{compsDir}/tools/{compName}.nim"
  if not fileExists(nim):
    var f = open(nim, fmWrite)
    f.write(tool_nim_template % [compName, compClassName])
    f.close()
    echo &"generated {nim}"
  else:
    echo &"{nim} already exists"

  let cfg = &"{appDir}/addons/{compName}/plugin.cfg"
  if not fileExists(cfg):
    createDir(&"{appDir}/addons/{compName}")
    var f = open(cfg, fmWrite)
    f.write(plugin_cfg_template % [compName])
    f.close()
    echo &"generated {cfg}"
  else:
    echo &"{cfg} already exists"

  genGdns(compName, isTool = true)

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

  var startTime = getTime()
  var res = newSeq[FlowVar[string]]()

  # watcher task
  var watcherFile = tscnDir / "watcher.tscn"
  var watcherLineEditFile = tscnDir / "watcher_lineedit.tscn"

  var compileCount = 0
  if does_reload:
    compileCount = 1
    echo "building watcher"
    if not fileExists(watcherFile):
      copyFile(depsDir / "watcher/watcher.tscn", watcherFile)
    if not fileExists(watcherLineEditFile):
      copyFile(depsDir / "watcher/watcher_lineedit.tscn", watcherLineEditFile)
    genGdns("watcher")
    res.add(spawn buildWatcher())
  else: # remove the watcher
    echo "removing watcher"
    removeFile(watcherFile)
    removeFile(watcherLineEditFile)
    removeFile(gdnsDir / "watcher.gdns")
    removeFile(gdnlibDir / "watcher.gdnlib")

  # comp task
  compileCount += buildAllComps(res, getBuildSettings())
  sync()

  var successes = 0
  var failures: seq[string]
  for f in res:
    var output = ^f
    if "[SuccessX]" in output:
      inc successes
    else:
      failures.add output

  if successes == compileCount:
    var parts = toParts(getTime() - startTime)
    var timeStr = ""
    timeStr &= (if parts[Minutes] > 0: $parts[Minutes] & " minutes " else: "")
    timeStr &= (if parts[Seconds] > 0: $parts[Seconds] & "." & $parts[Milliseconds] & " seconds " else: "")
    echo "=== Build OK! === ", timeStr
  else:
    echo "=== >>> Build Failed >>> ==="
    for f in failures:
      echo f
    echo "=== <<< Build Failed <<< ==="


task init, "creates a new clean branch from master for a new project, pass in the new branch name as an argument":
  if args.len != 1:
    echo "Usage: ./build init branch_name"
    quit()
  var branch_name = args[0]
  execOrQuit(&"git checkout -b {branch_name} master")

  for dir in [compsDir, gdnsDir, gdnlibDir, tscnDir, appDir / "addons", appDir / "gdscripts"]:
    execOrQuit(&"git rm {dir}/*")

  execOrQuit(&"git rm {appDir}/scenes/main.tscn")

  for f in walkFiles(&"{appDir}/*.png.*"):
    if "icon.png" notin f:
      execOrQuit(&"git rm {f}")

  removeDir(dllDir)
  for dir in [dllDir, compsDir, gdnsDir, gdnlibDir, tscnDir]:
    createDir(dir)

  # setup watcher
  var watcherFile = tscnDir / "watcher.tscn"
  var watcherLineEditFile = tscnDir / "watcher_lineedit.tscn"
  if not fileExists(watcherFile):
    copyFile(depsDir / "watcher/watcher.tscn", watcherFile)
  if not fileExists(watcherLineEditFile):
    copyFile(depsDir / "watcher/watcher_lineedit.tscn", watcherLineEditFile)
  genGdns("watcher")

  copyFile(depsDir / "app/project.godot", appDir / "project.godot")

  execOrQuit(&"git add app/")
  execOrQuit(&"git commit -m \"init {branch_name}\"")


task cwatch, "Monitors the components folder for changes to recompile.":
  echo "Monitoring components for changes.  Ctrl+C to stop"
  var lastTimes = newTable[string, Time]()
  for compPath in walkFiles(&"{compsDir}/*.nim"):
    lastTimes[compPath] = getLastModificationTime(compPath)

  var buildSettings = getBuildSettings()

  while true:
    for compPath in walkFiles(&"{compsDir}/*.nim"):
      var curLastTime = getLastModificationTime(compPath)
      if curLastTime > lastTimes[compPath]:
        lastTimes[compPath] = curLastTime
        var compFilename = splitFile(compPath)[1].snake
        echo &"-- Recompiling {compFilename} --"
        echo buildComp(compFilename, buildSettings)
    sleep cwatch_interval

task diagnostic, "Displays code that contributes to your dll size. Pass in the comp name as an argument: ./build diagnostic comp_name":
  checkPrereq("dumpincludes", "https://github.com/treeform/dumpincludes", false)
  if config.getSectionValue("Compiler", "build_kind") != "diagnostic":
    echo "Dlls must be compiled with Compiler.build_kind == \"diagnostic\""
    quit()
  execOrQuit(&"dumpincludes -f:{dllDir}/{args[0]}.{dllExt}")

task help, "display list of tasks":
  echo "Call build with a task:"
  for i in 0..<tasks.len:
    echo "  ", tasks[i].task_name, " : ", tasks[i].description

  echo "\nAdditional flags"
  echo "  --ini:build.ini : sets the config file"
