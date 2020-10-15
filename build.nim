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



let allflagsTable = {
  "release":"--d:danger",
  "force":"--forceBuild:on",
  "cc":"--cc:gcc",
  "gcc":"--cc:gcc",
  "vcc":"--cc:vcc",
  "lib":"--app:lib --noMain",
  "debug":"--debugger:native --stackTrace:on",
  "arc":"--gc:arc --d:useMalloc",
  "mute":"--warning[LockLevel]:off --hint[Processing]:off"
}.toTable

var taskFlagsTable = {
  "lib":"--app:lib --noMain",
  "cc":"--cc:vcc",
  #"debug":"--debugger:native --stackTrace:on",
  "release":"--d:danger",
  "arc":"--gc:arc --d:useMalloc",
  "mute":"--warning[LockLevel]:off --hint[Processing]:off"
}.toTable

proc setFlag(flag:string, state:bool = true) =
  case flag:
    of "release":
      taskFlagsTable.del("debug")
      taskFlagsTable["release"] = allFlagsTable["release"]
    of "gcc":
      taskFlagsTable.del("cc")
      taskFlagsTable["cc"] = allFlagsTable["gcc"]
    of "vcc":
      taskFlagsTable.del("cc")
      taskFlagsTable["cc"] = allFlagsTable["vcc"]
    else:
      if allFlagsTable.haskey(flag):
        if state:
            taskFlagsTable[flag] = allFlagsTable[flag]
        else:
          case flag:
          of "arc", "lib": discard # cannot disable these
          else:
            taskFlagsTable.del(flag)


var taskName = ""
var args:seq[string]

var p = initOptParser(commandLineParams().join(" "))
for kind, key, val in p.getopt():
  case kind
  of cmdEnd: doAssert(false) # Doesn't happen with getopt()
  of cmdShortOption, cmdLongOption:
    case key
    of "f", "force":
      setFlag("force")
    of "release", "gcc":
      setFlag(key)
    else:
      var state = true
      if val == "off": state = false
      setFlag(key, state)
  of cmdArgument:
    if taskName == "":
      taskName = key
    else:
      args.add key


proc execnim(otherFlags:string, outputPath:string, projNim:string) =
  var sharedFlags = ""
  for key in taskFlagsTable.keys:
    sharedFlags &= taskFlagsTable[key] & " "

  discard execShellCmd &"nim c {otherFlags} {sharedFlags} --o:{outputPath} {projNim}"


include "tasks.nim"


let params = commandLineParams()
if params.len == 0:
  echo "Call build with a task:"
  for i in 0..<tasks.len:
    echo "  ", tasks[i].task_name, " : ", tasks[i].description
  quit()


var matches = tasks.filterIt(it.task_name == taskName)
if matches.len == 0: # no match assume it's a compName
  args = taskName & args
  taskName = "comp"
  matches = tasks.filterIt(it.task_name == taskName)
if matches.len == 1:
  matches[0].task_proc()