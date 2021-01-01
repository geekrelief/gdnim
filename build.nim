from sequtils import filterIt
import os, osproc, tables, parseopt, strutils, strformat, parsecfg

# Dependencies
#requires "godot >= 0.8.1"
#requires "msgpack4nim"

type
  Task = tuple[task_name:string, description:string, task_proc: proc():void {.nimcall.}]

var tasks:seq[Task] = @[]

template task(name:untyped, desc:string, body:untyped):untyped =
  proc `name Task`() {.nimcall.} =
    echo ">>>> Task: ", astToStr(name), " <<<<"
    body
  tasks.add((task_name: astToStr(name), description: desc, task_proc: `name Task`))

# special task that's executed after build finishes
var innerFinalTask:proc()
proc finalTask() =
  if not(innerFinalTask.isNil):
    innerFinalTask()

tasks.add((task_name: "final", description: "executed after build finishes, specified with 'final:' instead of 'task:'", task_proc: finalTask))

template final(body:untyped):untyped =
  innerFinalTask = proc() {.nimcall.} =
    body

let allCompilerFlagsTable = {
  "release":"--d:danger",
  "force":"--forceBuild:on",
  "cc":"--cc:tcc", # doesn't work with threads:on
  # compiles that fastest, clean compile output, does not work with threads:on
  "tcc":"--cc:tcc",
  # clean compile output, needs gcc dlls, produces large dlls by default, use strip
  "gcc":"--cc:gcc --threads:on --tlsEmulation:off",
  "gcc_strip": "--passL:\"-s\"",
  # smallest dlls, godot uses same compiler, disable warnings, slow, lots of compile artifacts
  "vcc":"--cc:vcc --passC=\"/wd4133\" --threads:on --tlsEmulation:off",
  "lib":"--app:lib --noMain",
  "debug":"--debugger:native --stackTrace:on",
  "arc":"--gc:arc", # using arc with async will cause memory leaks, async generates cycles arc cannot collect
  "orc":"--gc:orc", #crashes with --d:useMalloc, will collect async cycles
  "useMalloc":"--d:useMalloc", #crashes with --d:useMalloc, will collect async cycles
  "realtime":"--d:useRealtimeGC",
  "mute":"--warning[LockLevel]:off --hint[Processing]:off",
  "parallel":"--parallelBuild:0"
}.toTable

#stable tcc config, vcc crashes with arc or orc
var taskCompilerFlagsTable = {
  "mute":"--warning[LockLevel]:off --hint[Processing]:off",
  "parallel":"--parallelBuild:0",
  "release":"--d:danger",
  #"debug":"--debugger:native --stackTrace:on",
  #"gc":"--gc:orc",
  "gc":"--gc:arc",
  #"gc":"--d:useRealtimeGc",
  "useMalloc":"--d:useMalloc",
  "lib":"--app:lib --noMain",
  # compiles that fastest, clean compile output, does not work with threads:on
  "cc":"--cc:tcc"
  # clean compile output, needs gcc dlls, produces large dlls by default, use strip
  #"cc":"--cc:gcc --threads:on --tlsEmulation:off"
  # vcc smallest dlls, godot uses same compiler, disable warnings, slow, lots of compile artifacts
  #"cc":"--cc:vcc --passC=\"/wd4133\" --threads:on --tlsEmulation:off"
}.toTable

var otherFlagsTable:Table[string, string]

proc setFlag(flag:string, val:string = "") =
  case flag:
    of "release":
      taskCompilerFlagsTable.del("debug")
      taskCompilerFlagsTable["release"] = allCompilerFlagsTable["release"]
    of "debug":
      taskCompilerFlagsTable.del("release")
      taskCompilerFlagsTable["debug"] = allCompilerFlagsTable["debug"]
    of "gcc", "vcc", "tcc":
      taskCompilerFlagsTable.del("cc")
      taskCompilerFlagsTable["cc"] = allCompilerFlagsTable[flag]
    of "arc", "orc", "realtime":
      taskCompilerFlagsTable.del("gc")
      taskCompilerFlagsTable["gc"] = allCompilerFlagsTable[flag]
    of "nocheck", "nc":
      otherFlagsTable["nocheck"] = "on"
    else:
      if allCompilerFlagsTable.haskey(flag) or taskCompilerFlagsTable.haskey(flag):
        if val == "on" or val == "":
          taskCompilerFlagsTable[flag] = allCompilerFlagsTable[flag]
        else:
          taskCompilerFlagsTable.del(flag)
      else:
        otherFlagsTable[flag] = val

var config = loadConfig("build.ini")
setFlag(config.getSectionValue("Compiler", "cc"))
if config.getSectionValue("Compiler", "cc") == "gcc":
  setFlag("gcc_strip", config.getSectionValue("GCC", "strip"))

setFlag("debug", config.getSectionValue("Compiler", "debug"))
setFlag(config.getSectionValue("Compiler", "gc"))
case config.getSectionValue("Compiler", "gc"):
  of "arc", "orc":
    setFlag("useMalloc", config.getSectionValue("Compiler", "useMalloc"))
  else: discard

var taskName = ""
var compName = ""
var args:seq[string]

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
    else:
      setFlag(key, val)
  of cmdArgument:
    if taskName == "":
      taskName = key
    else:
      args.add key

proc getSharedFlags():string =
  var sharedFlags = ""
  for key in taskCompilerFlagsTable.keys:
    sharedFlags &= taskCompilerFlagsTable[key] & " "
  sharedFlags

proc customizeFormatFlags(projNim:string, sharedFlags:string):string =
  var flags = sharedFlags
  if ("vcc" in flags) and ("debug" in flags):
    let vcc_pdbdir = config.getSectionValue("VCC", "pdbdir")
    createDir(vcc_pdbdir)
    var filename = splitFile(projNim)[1]
    flags &= &"--passC=\"/Fd{vcc_pdbdir}/{filename}.pdb\"" #https://docs.microsoft.com/en-us/cpp/build/reference/fd-program-database-file-name?view=vs-2019
  flags

proc execnim(otherFlags:string, sharedFlags:string, outputPath:string, projNim:string):string =
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