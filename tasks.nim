import strformat
import godotapigen
from os import removeDir, removeFile, createDir, getEnv, existsEnv, execShellCmd, `/`

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
task cleandll, "clean the dlls":
  removeFile "app/_dlls/host.dll"
  removeFile "app/_dlls/component.dll"

task build, "build task":
  echo "build task"

task plugin, "plugin task":
  echo "plugin task calling buildTask "
  buildTask()