from sequtils import filterIt
import os, tables, parseopt, strutils, strformat

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
  "cc":"--cc:tcc",
  # compiles that fastest, clean compile output, less perfomant?
  "tcc":"--cc:tcc",
  # clean compile output, needs gcc dlls, produces large dlls
  "gcc":"--cc:gcc",
  # smallest dlls, godot uses same compiler, disable warnings, slow, lots of compile artifacts
  "vcc":"--cc:vcc --passC=\"/wd4133\"",
  "lib":"--app:lib --noMain",
  "debug":"--debugger:native --stackTrace:on",
  "arc":"--gc:arc --d:useMalloc",
  "orc":"--gc:orc --d:useMalloc", #crash, avoid for now
  "mute":"--warning[LockLevel]:off --hint[Processing]:off"
}.toTable

#stable tcc config, vcc crashes with arc or orc
var taskCompilerFlagsTable = {
  "lib":"--app:lib --noMain",
  "cc":"--cc:tcc",
  "release":"--d:danger",
  "gc":"--gc:arc --d:useMalloc",
  "mute":"--warning[LockLevel]:off --hint[Processing]:off"
}.toTable

var otherFlagsTable:Table[string, string]

proc setFlag(flag:string, val:string = "") =
  case flag:
    of "release":
      taskCompilerFlagsTable.del("debug")
      taskCompilerFlagsTable["release"] = allCompilerFlagsTable["release"]
    of "gcc", "vcc", "tcc":
      taskCompilerFlagsTable.del("cc")
      taskCompilerFlagsTable["cc"] = allCompilerFlagsTable[flag]
    of "arc", "orc":
      taskCompilerFlagsTable.del("gc")
      taskCompilerFlagsTable["gc"] = allCompilerFlagsTable[flag]
    else:
      if allCompilerFlagsTable.haskey(flag) or taskCompilerFlagsTable.haskey(flag):
        if val == "on" or val == "":
          taskCompilerFlagsTable[flag] = allCompilerFlagsTable[flag]
        else:
          taskCompilerFlagsTable.del(flag)
      else:
        otherFlagsTable[flag] = val

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


proc execnim(otherFlags:string, outputPath:string, projNim:string) =
  var sharedFlags = ""
  for key in taskCompilerFlagsTable.keys:
    sharedFlags &= taskCompilerFlagsTable[key] & " "

  discard execShellCmd &"nim c {otherFlags} {sharedFlags} --o:{outputPath} {projNim}"

include "tasks.nim"

var matches = tasks.filterIt(it.task_name == taskName)
if matches.len == 0: # no match assume it's a compName
  compName = taskName
  taskName = "comp"
  matches = tasks.filterIt(it.task_name == taskName)
if matches.len == 1:
  matches[0].task_proc()

finalTask()