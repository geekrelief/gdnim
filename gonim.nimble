import strformat
import strutils

# Package

version       = "0.1.0"
author        = "geekrelief"
description   = "godot-nim stub for windows with hotreloading dlls and nimscript"
license       = "MIT"

# Dependencies
#requires "godot >= 0.8.1"
requires "compiler >= 1.2.6"

task cleanapi, "clean generated api":
  rmDir("logs")
  rmDir("deps/godotapi")
  rmFile("deps/genapi.exe")

task genapi, "generate the godot api bindings":
  let godotBin = if existsEnv("GODOT_BIN"):
    getEnv("GODOT_BIN")
  else:
    echo "GODOT_BIN environment variable is not set"
    quit(-1)
  #echo godotBin

  cleanapiTask()

  let apidir = "deps/godotapi"
  mkdir apidir
  exec &"{godotBin} --gdnative-generate-json-api {apidir}/api.json"
  exec &"nimble c --path:deps/godot deps/genapi" #requires from gonim.nimble, why isn't --path:deps/godot recognized in genapi.nim.cfg?
  exec &"""{findExe "deps/genapi"} {apidir} {apidir}/api.json"""

# compiling with gcc, vcc spitting out warnings about incompatible pointer types with NimGodotObj, which was added for gc:arc
# include to include libgcc_s_seh-1.dll, libwinpthread-1.dll in the app/_dlls folder for project to run
task cleandll, "clean the dlls":
  rmFile("app/_dlls/host.dll")
  rmFile("app/_dlls/component.dll")

proc checkGccDlls() =
  var errCount:int = 0
  if not fileExists("app/_dlls/libgcc_s_seh-1.dll"):
    echo "Missing app/_dlls/libgcc_s_seh-1.dll, please copy from gcc/bin"
    inc errCount
  if not fileExists("app/_dlls/libwinpthread-1.dll"):
    echo "Missing app/_dlls/libwinpthread-1.dll, please copy from gcc/bin"
    inc errCount
  if errCount == 0:
    echo "gcc dlls check passed!"


task host, "build the host dll":
  exec &"nim c --o:app/_dlls/host.dll gonim.nim"
  checkGccDlls()

task comp, "build the component(s) dll":
  exec &"nim c --skipParentCfg --path:deps --path:deps/godot --app:lib --noMain --warning[LockLevel]:off --gc:arc --d:useMalloc --threads:on --tlsEmulation:off --o:app/_dlls/component.dll components/component.nim"
  checkGccDlls()