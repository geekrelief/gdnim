from sequtils import filterIt

# Dependencies
#requires "godot >= 0.8.1"
#requires "msgpack4nim"

type
  Task = tuple[task_name:string, description:string, task_proc: proc():void {.nimcall.}]

var tasks:seq[Task] = @[]

template task(name:untyped, desc:string, body:untyped):untyped =
  proc `name Task`() {.nimcall.} =
    body
  tasks.add((task_name: astToStr(name), description: desc, task_proc: `name Task`))

include "tasks.nim"

let params = commandLineParams()
if params.len == 0:
  echo "Call build with a task:"
  for i in 0..<tasks.len:
    echo "  ", tasks[i].task_name, " : ", tasks[i].description
  quit()


if params.len >= 1:
  let matches = tasks.filterIt(it.task_name == params[0])
  if matches.len == 1:
    matches[0].task_proc()