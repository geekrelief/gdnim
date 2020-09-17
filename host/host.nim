import godot
import godotapi / [engine, node]
import godotapi / [resource_loader, packed_scene, scene_tree, viewport]
import dynlib, locks
import times
import strformat
import os, threadpool

var watchChan:Channel[bool]
var loadChan:Channel[bool]
watchChan.open()
loadChan.open()

{.pragma: ff, gcsafe, cdecl.}
type
  #FFFunc = proc() {.ff.}
  LibProc = proc() {.ff.}
  LibStartFunc = proc() {.ff.}
  LibStopFunc = proc() {.ff.}
  LibSumFunc = proc(n:Node, a,b:int):int {.ff.}
  LibSetSumFunc = proc(n:Node, f:LibSumFunc) {.ff.}
  #GDNativeInitFunc = proc(options: ptr GDNativeInitOptions) {.ff.}
  #GDNativeScriptInitFunc = proc(handle:pointer) {.ff.}
  #PTestFunc = proc() {.ff}
  #StopFunc = proc():bool {.ff.}

var hotdll {.threadvar.}:LibHandle

proc globalSumFunc(a, b:int):int {.ff.} =
  echo "globalSumFunc"
  a * b

proc fileWatcher(path:string) =
  var lastTime = getLastModificationTime(path)
  while true:
    if existsFile(path):
      if lastTime < getLastModificationTime(path):
        print "dll changed!"
        watchChan.send(true)
        let loaded = loadChan.recv()
        if loaded:
          print "confirmed loaded"
          lastTime = getLastModificationTime(path)
    sleep(400)


gdobj Host of Node:

  var dllPath = "_dlls/component.dll" # should be loaded from a file or directory

  proc loaddll() =
    print "loaddll"
    if hotdll != nil:
      (cast[LibStopFunc](hotdll.symAddr("stop")))()
      unloadLib(hotdll)
      print "unloaded dll"

    hotdll = loadLib(self.dllPath)
    assert(hotdll != nil, "dll is nil")

    (cast[LibStartFunc](hotdll.symAddr("NimMain")))() #call this before accessing any nim procs otherwise you'll crash
    #(cast[LibSetSumFunc](hotdll.symAddr("setSum")))(globalSumFunc)
    (cast[LibSetSumFunc](hotdll.symAddr("setSum")))(Node self, cast[LibSumFunc](memberSumFunc))
    #(cast[LibStartFunc](hotdll.symAddr("start")))()

    #echo (cast[LibSumFunc](hotdll.symAddr("start")))(4,5)

  method ready*() =
    #print os.getCurrentDir()
    self.loaddll()
    spawn fileWatcher(self.dllPath)

  method process*(delta: float64) =
    let tried = watchChan.tryRecv()
    if tried.dataAvailable:
      if tried.msg:
        self.loaddll()
        loadChan.send(true)

  proc memberSumFunc*(a, b:int):int =
    echo "memberSumFunc"
    print "haha I did it!"

    let scene = load("res://main.tscn") as PackedScene
    let root = self.getTree().root
    root.call_deferred("add_child", toVariant(scene.instance()))
    result = a * b