from sequtils import filterIt
import os, osproc, times, tables, parseopt, strutils, strformat, parsecfg, terminal

# Dependencies
#requires "godot >= 0.8.1"
#requires "msgpack4nim"

var buildini: string = "build.ini"

type
  Task = tuple[task_name: string, description: string, task_proc: proc(): void {.nimcall.}]
  BuildSettings = tuple[sharedFlags: string, settingsTable: Table[string, bool]]

var tasks: seq[Task] = @[]

template task(name: untyped, desc: string, body: untyped): untyped =
  proc `name Task`() {.nimcall.} =
    echo ">>>> Task: ", astToStr(name), " <<<<"
    body
  tasks.add((task_name: astToStr(name), description: desc, task_proc: `name Task`))

# special task that's executed after build finishes
var innerFinalTask: proc()
proc finalTask() =
  if not(innerFinalTask.isNil):
    innerFinalTask()

tasks.add((task_name: "final", description: "executed after build finishes, specified with 'final:' instead of 'task:'", task_proc: finalTask))

template final(body: untyped): untyped =
  innerFinalTask = proc() {.nimcall.} =
    body

let allCompilerFlagsTable = {
  "force": "--forceBuild:on",
  "lib": "--app:lib --noMain",
  "mute": "--warning[LockLevel]:off --hint[Processing]:off",
  "parallel": "--parallelBuild:0",
  "incremental": "--incremental:on",
  # cc
  "cc": "--cc:tcc",                                      # doesn't work with threads:on
  # compiles fastest, clean compile output, does not work with threads:on
  "tcc": "--cc:tcc",
  # clean compile output, needs gcc dlls, produces large dlls by default, use strip
  "gcc": "--cc:gcc --threads:on --tlsEmulation:off",
  "gcc_strip": "--d:strip",                              # same as "--passL:\"-s\"", # removes debug symbols
  "gcc_flto": "--passC:-flto",                           # https://gcc.gnu.org/wiki/LinkTimeOptimization
  "mingw": "-d:mingw",
  # smallest dlls, godot uses same compiler, disable warnings, slow, lots of compile artifacts
  "vcc": "--cc:vcc --passC=\"/wd4133\" --threads:on --tlsEmulation:off",
  "clang": "--cc:clang --threads:on --tlsEmulation:off", # default toolchain for android
  # gc
  "arc": "--gc:arc",                                     # using arc with async will cause memory leaks, async generates cycles arc cannot collect
  "orc": "--gc:orc",                                     #crashes with --d:useMalloc, will collect async cycles
  "refc": "--gc:refc",
  "useMalloc": "--d:useMalloc",                          # use C memory primitives
  # build_kind
  "danger": "--d:danger",
  "release": "--d:release",
  "debug": "--debugger:native --stackTrace:on",
  "diagnostic": "--d:danger --debugger:native",          #for dumpincludes
  # hot
  "reload": "--d:does_reload",
  # android
  "android": "--os:android -d:androidNDK",
  # cpu archedture
  "arm64": "--cpu:arm64",
  "x86_64": "--cpu:amd64",
}.toTable

#stable gcc config
var taskCompilerFlagsTable = {
  "lib": "--app:lib --noMain",
  "mute": "--warning[LockLevel]:off --hint[Processing]:off --hint[ConvFromXtoItselfNotNeeded]:off",
  "parallel": "--parallelBuild:0",
  "cc": "--cc:gcc",
  "gc": "--gc:orc",
  "build_kind": "--d:danger",
  "reload": "--d:does_reload",
}.toTable

var otherFlagsTable: Table[string, string]

proc configError(errMsg: string, prescription: string) =
  stderr.setForegroundColor(fgRed, true)
  stderr.styledWrite(&"{buildini} error: ", fgRed, errMsg)
  stderr.styledWrite("\n  Expected: ", fgWhite, prescription)
  quit()

proc setFlag(flag: string, val: string = "on")
var taskName = ""
var compName = ""
var args: seq[string]

var p = initOptParser(commandLineParams().join(" "))
for kind, key, val in p.getopt():
  case kind
  of cmdEnd: doAssert(false) # Doesn't happen with getopt()
  of cmdShortOption, cmdLongOption:
    case key
    of "f":
      setFlag("force")
    of "m":
      setFlag("move")
    of "ini":
      buildini = val
    else:
      setFlag(key, val)
  of cmdArgument:
    if taskName == "":
      taskName = key
    else:
      args.add key

echo &"config file: {buildini}"
var config = loadConfig(buildini)

setFlag("reload", config.getSectionValue("Hot", "reload"))
setFlag("build_kind", config.getSectionValue("Compiler", "build_kind"))

if config.getSectionValue("Godot", "platform") == "android":
  setFlag("cc", "clang")
else:
  setFlag("cc", config.getSectionValue("Compiler", "cc"))
if config.getSectionValue("Compiler", "cc") in ["gcc", "clang"]:
  var build_kind = config.getSectionValue("Compiler", "build_kind")
  if build_kind notin ["debug", "diagnostic"]:
    setFlag("gcc_strip", config.getSectionValue("GCC", "strip"))

  setFlag("gcc_flto", config.getSectionValue("GCC", "flto"))

setFlag("gc", config.getSectionValue("Compiler", "gc"))
case config.getSectionValue("Compiler", "gc"):
  of "arc", "orc":
    setFlag("useMalloc", config.getSectionValue("Compiler", "useMalloc"))
  else: discard

setFlag("incremental", config.getSectionValue("Compiler", "incremental"))

if config.getSectionValue("Godot", "platform") == "android":
  setFlag("arch", config.getSectionValue("Godot", "arch"))
  setFlag("os", config.getSectionValue("Godot", "platform"))
  setFlag("api_level", config.getSectionValue("Android", "api_level"))

func hostCpuToAndroid(arch: string): string =
  case arch:
    of "i386": result = "i686"
    of "amd64": result = "x86_64"
    else: result = arch

proc findNDK(target: string) =
  const env = "ANDROID_NDK_ROOT"
  var ndkRoot: string
  if existsEnv(env):
    ndkRoot = getEnv(env)
  else:
    configError(&"NDK not found", &"set \"{env}\" to NDK root")

  let ndkBin = ndkRoot / "toolchains" / "llvm" / "prebuilt" / &"linux-{hostCpuToAndroid(hostCPU)}" / "bin"
  let clang = ndkBin / &"{target}-clang"
  try:
    if fpUserExec notin getFileInfo(clang).permissions:
      raise newException(OSError, "")
  except:
    configError(&"no invalid NDK found", &"please check \"{clang}\" point to a valid NDK")

  let sep = if hostOS == "windows": ";" else: ":"
  let path = getEnv("PATH")
  putEnv("PATH", &"{ndkBin}{sep}{path}")

proc setFlag(flag: string, val: string) =
  case flag:
    of "build_kind":
      if val in ["danger", "release", "debug", "diagnostic"]:
        taskCompilerFlagsTable.del("build_kind")
        taskCompilerFlagsTable["build_kind"] = allCompilerFlagsTable[val]
      else:
        configError(&"build_kind = \"{val}\"", "danger, release, debug, or diagnostic")
    of "cc":
      if val in ["gcc", "vcc", "tcc", "clang", "mingw"]:
        taskCompilerFlagsTable.del("cc")
        taskCompilerFlagsTable["cc"] = allCompilerFlagsTable[val]
      else:
        configError(&"cc = \"{val}\"", "gcc, vcc, or tcc")
    of "gc":
      if val in ["arc", "orc", "refc"]:
        taskCompilerFlagsTable.del("gc")
        taskCompilerFlagsTable["gc"] = allCompilerFlagsTable[val]
      else:
        configError(&"gc = \"{val}\"", "orc, arc, or refc")
    of "nocheck", "nc":
      otherFlagsTable["nocheck"] = "on"
    of "os":
      taskCompilerFlagsTable["os"] = allCompilerFlagsTable[val]
    of "arch":
      taskCompilerFlagsTable["arch"] = allCompilerFlagsTable[val]
    of "api_level":
      var target: string
      case config.getSectionValue("Godot", "arch"):
        of "arm": target = &"armv7a-linux-androideabi{val}"
        of "arm64": target = &"aarch64-linux-android{val}"
        of "x86": target = &"i686-linux-android{val}"
        of "x86_64", "x64": target = &"x86_64-linux-android{val}"
      taskCompilerFlagsTable["cCompilerFlags"] = &"--passC:\"-target {target}\""
      taskCompilerFlagsTable["linkerFlags"] = &"--passL:\"-target {target}\""
      findNDK(target)
    else:
      if allCompilerFlagsTable.haskey(flag) or taskCompilerFlagsTable.haskey(flag):
        if val == "on":
          taskCompilerFlagsTable[flag] = allCompilerFlagsTable[flag]
        else:
          taskCompilerFlagsTable.del(flag)
      else:
        otherFlagsTable[flag] = val

proc genNimCfg() =
  echo "Generating nim.cfg"
  var depsDir = config.getSectionValue("Dir", "deps")
  var depsGodotDir = config.getSectionValue("Dir", "deps_godot")
  var nimCfg = open("nim.cfg", fmWrite)
  nimCfg.write("""
# This file is autogenerated by "build.nim" from build.ini's settings.
# It's used by nimsuggest for autocompletion.
""")
  nimCfg.write(&"--path:\"{depsDir}\"\n--path:\"{depsDir}/{depsGodotDir}\"")
  #[
  # nimsuggest is too slow if the entire api is imported
  nimCfg.write("\n# Importing godotapi for nimsuggest")
  for gdapiFilename in walkFiles(&"{depsDir}/godotapi/*.nim"):
    var gdapi = splitFile(gdapiFilename)[1]
    nimCfg.write(&"\n--import:\"godotapi/{gdapi}\"")
  ]#
  nimCfg.close()

if not fileExists("nim.cfg"):
  genNimCfg()
elif getLastModificationTime("build.ini") > getLastModificationTime("nim.cfg"):
  # check if we should regenerate
  var paths: seq[string]
  paths.add config.getSectionValue("Dir", "deps")
  paths.add config.getSectionValue("Dir", "deps_godot")

  var nimCfg = open("nim.cfg").readAll().split("\n")[2..3].join(" ")
  var np = initOptParser(nimCfg)
  for kind, key, val in np.getopt():
    case kind
    of cmdLongOption:
      case key
      of "path":
        if not (val in paths):
          genNimCfg()
          break
      else:
        discard
    else: discard

proc getSharedFlags(): string =
  var sharedFlags = ""
  for key in taskCompilerFlagsTable.keys:
    sharedFlags &= taskCompilerFlagsTable[key] & " "
  sharedFlags

proc customizeFormatFlags(projNim: string, sharedFlags: string): string =
  var flags = sharedFlags
  if ("vcc" in flags) and ("debug" in flags):
    let vcc_pdbdir = config.getSectionValue("VCC", "pdbdir")
    createDir(vcc_pdbdir)
    var filename = splitFile(projNim)[1]
    flags &= &"--passC=\"/Fd{vcc_pdbdir}/{filename}.pdb\"" #https://docs.microsoft.com/en-us/cpp/build/reference/fd-program-database-file-name?view=vs-2019
  flags

proc execnim(otherFlags: string, sharedFlags: string, outputPath: string, projNim: string): string =
  var flags = customizeFormatFlags(projNim, sharedFlags)
  var projName = splitFile(projNim)[1]
  execProcess &"nim c {otherFlags} --nimcache:.nimcache/{projName} {flags} --o:{outputPath} {projNim}"

include "tasks.nim"

var matches = tasks.filterIt(it.task_name == taskName)
if matches.len == 0: # no match assume it's a compName
  compName = taskName
  taskName = "comp"
  matches = tasks.filterIt(it.task_name == taskName)
if matches.len == 1:
  matches[0].task_proc()

finalTask()
