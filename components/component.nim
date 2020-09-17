import godot
import godotapi / [node]
#import godotapi / [resource_loader, packed_scene]
import os
import threadpool

#import mainpanel
#import fpscounter
#import buttoncounter

{.pragma: ex, cdecl, exportc, dynlib.}

var isAlive:bool = true
var endFlowVar:FlowVar[bool]

proc sum*(n:Node, a, b:int):int {.gcsafe, cdecl.} =
  a + b

type
  SumFunc = proc(n:Node, a,b:int):int {.gcsafe, cdecl.}

var globalNode:Node
var globalSumFunc:SumFunc = sum
var localSumFunc {.threadvar.}:SumFunc

proc setSum*(n:Node, sf:SumFunc) {.ex.} =
  globalNode = n
  globalSumFunc = sf
  discard sf(n, 1, 3)
  #discard globalSumFunc(1, 2)

proc otherThread():bool {.thread.}

proc start*() {.ex.} =
  #print "starting thread"
  echo "mainlib: starting otherthread"
  endFlowVar = spawn otherthread()
  #let scene = load("res://main.tscn") as PackedScene
  #self.getTree().getParent().addChild(scene.instance())
  #sum(a, b)

proc otherthread():bool {.thread.} =
  #{.gcsafe.}:
    #localSumFunc = globalSumFunc

  while true:
    #print "ok!"
    #echo "otherthread: sum(4,5) = ", localSumFunc(4, 5)
    sleep(1000)
    if not isAlive:
      #print "terminating"
      echo "otherthread: terminating"
      return true

proc stopThreads*():bool {.ex.} =
  isAlive = false
  return ^endFlowVar

proc stop*() {.ex.} =
  echo "mainLib stop"
  discard stopThreads()