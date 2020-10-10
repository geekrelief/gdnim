import strformat, strutils
import godotapigen
from sequtils import toSeq, filter, mapIt
import os
import times

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


# compiling with gcc, vcc spitting out warnings about incompatible pointer types with NimGodotObj, which was added for gc:arc
# include to include libgcc_s_seh-1.dll, libwinpthread-1.dll in the app/_dlls folder for project to run
const gccDlls = @["libgcc_s_seh-1", "libwinpthread-1"]

proc checkGccDlls() =
  for dll in gccDlls:
    if not fileExists(&"app/_dlls/{dll}.dll"):
      echo "Missing app/_dlls/{dll}.dll, please copy from gcc/bin"

task cleandll, "clean the dlls, arguments are component names, default all non-gcc dlls":
  let dllDir = "app/_dlls"
  var dllPaths:seq[string]
  if commandLineParams().len > 1:
    dllPaths = commandLineParams()[1..^1].mapIt(&"{dllDir}/{it}.dll")
    dllPaths &= commandLineParams()[1..^1].mapIt(&"{dllDir}/{it}_safe.dll")
  else:
    dllPaths = toSeq(walkFiles(&"{dllDir}/*.dll"))
      .filterIt splitFile(it)[1] notin gccDlls

  for dllPath in dllPaths:
    echo &"rm {dllPath}"
    removeFile dllPath
  checkGccDlls()

#testing
task host, "build the host dll":
  checkGccDlls()
  discard execShellCmd "nim c --path:deps --path:deps/godot --path:host --app:lib --noMain --gc:arc --d:useMalloc --threads:on --tlsEmulation:off --warning[LockLevel]:off --hint[Processing]:off --o:app/_dlls/host.dll gonim.nim"

#testing
task test_comp, "build the component(s) dll":
  checkGccDlls()
  discard execShellCmd "nim c --path:deps --path:deps/godot --app:lib --noMain --gc:arc --d:useMalloc --threads:on --tlsEmulation:off --warning[LockLevel]:off --hint[Processing]:off --o:app/_dlls/component.dll components/component.nim"

task watcher, "build the watcher dll":
  checkGccDlls()
  discard execShellCmd "nim c --path:deps --path:deps/godot --app:lib --noMain --gc:arc --d:useMalloc --threads:on --tlsEmulation:off --warning[LockLevel]:off --hint[Processing]:off --o:app/_dlls/watcher.dll watcher.nim"

# components generator
const gdns_template = """
[gd_resource type="NativeScript" load_steps=2 format=2]

[sub_resource type="GDNativeLibrary" id=1]
entry/Windows.64 = "res://_dlls/$1.dll"
dependency/Windows.64 = [  ]

[resource]
resource_name = "$2"
class_name = "$2"
library = SubResource( 1 )
"""

# components are named {compName}_safe.dll and
# are loaded by the watcher.dll via resources. At runtime, the watcher.dll will copy
# the {compName}_safe.dll to the {compName}.dll and monitor the _dlls
# folder to see if _safe.dll is rebuilt.
task comp, "build component and generate a gdns file":
  let params = commandLineParams()
  if params.len < 2:
    echo "comp needs a component name\n  .\\build gencomp (comp_name)"
    quit()
  let compName = params[1]

  let safeDllFilePath = &"app/_dlls/{compName}_safe.dll"
  let hotDllFilePath = &"app/_dlls/{compName}.dll"
  let nimFilePath = &"components/{compName}.nim"
  if not fileExists(nimFilePath):
    echo &"Error compiling {nimFilePath} [Not Found]"
    quit()

  let gdns = &"app/gdns/{compName}.gdns"
  if not fileExists(gdns):
    var gdnsContent = gdns_template % [compName, compName.capitalizeAscii]
    var f = open(gdns, fmWrite)
    f.write(gdnsContent)
    f.close()
    echo &"generated {gdns}"

  if not fileExists(safeDllFilePath) or getLastModificationTime(nimFilePath) > getLastModificationTime(safeDllFilePath):
    discard execShellCmd &"nim c --path:deps --path:deps/godot --path:. --app:lib --noMain --gc:arc --d:useMalloc --threads:on --tlsEmulation:off --warning[LockLevel]:off --hint[Processing]:off --o:{safeDllFilePath} {nimFilePath}"

  if fileExists(safeDllFilePath) and getLastModificationTime(nimFilePath) < getLastModificationTime(safeDllFilePath) and
    (not fileExists(hotDllFilePath) or (params.len == 3 and params[2] == "-f")):
    echo "move safe to hot"
    moveFile(safeDllFilePath, hotDllFilePath)