import strformat, strutils
import godotapigen
from sequtils import toSeq, filter
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

task cleandll, "clean the dlls":
  var dlls = toSeq(walkFiles("app/_dlls/*.dll"))
    .filterIt splitFile(it)[1] notin gccDlls
  for dll in dlls:
    echo &"rm {dll}"
    removeFile dll
  checkGccDlls()

task host, "build the host dll":
  checkGccDlls()
  discard execShellCmd "nim c --path:deps --path:deps/godot --path:host --app:lib --noMain --gc:arc --d:useMalloc --threads:on --tlsEmulation:off --warning[LockLevel]:off --hint[Processing]:off --o:app/_dlls/host.dll gonim.nim"

task comp, "build the component(s) dll":
  checkGccDlls()
  discard execShellCmd "nim c --path:deps --path:deps/godot --app:lib --noMain --gc:arc --d:useMalloc --threads:on --tlsEmulation:off --warning[LockLevel]:off --hint[Processing]:off --o:app/_dlls/component.dll components/component.nim"

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

proc checkGdns(compName:string) =
  let gdns = &"app/gdns/{compName}.gdns"
  if not fileExists(gdns):
    var gdnsContent = gdns_template % [compName, compName.capitalizeAscii]
    var f = open(gdns, fmWrite)
    f.write(gdnsContent)
    f.close()
    echo &"generated {gdns}"

proc checkCompDll(compName:string) =
  let dllFilePath = &"app/_dlls/{compName}_actual.dll"
  let hotdllFilePath = &"app/_dlls/{compName}.dll"
  let nimFilePath = &"components/{compName}.nim"
  if not fileExists(nimFilePath):
    echo &"Error compiling {nimFilePath} [Not Found]"
    quit()
  checkGdns(compName)
  if not fileExists(dllFilePath) or getLastModificationTime(nimFilePath) > getLastModificationTime(dllFilePath):
    let res = execShellCmd &"nim c --path:deps --path:deps/godot --app:lib --noMain --gc:arc --d:useMalloc --threads:on --tlsEmulation:off --warning[LockLevel]:off --hint[Processing]:off --o:{dllFilePath} {nimFilePath}"
    if res == 0 and not fileExists(hotdllFilePath):
      copyFile(dllFilePath, hotdllFilePath)

task gencomp, "generate a component":
  let params = commandLineParams()
  if params.len != 2:
    echo "gencomp needs a component name\n  .\\build gencomp (comp_name)"
    quit()
  let compName = params[1]
  checkCompDll(compName)