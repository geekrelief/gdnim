import godot
import godotapi / [engine, node]
import godotapi / [resource_loader, texture, sprite, packed_scene, scene_tree, viewport, label]
import dynlib, locks
import times
import strformat
import os, threadpool
import strutils, strformat, times

const dllDir:string = "_dlls"

gdobj Watcher of Node:

  var enableWatch {.gdExport.}:bool = true
  var watchIntervalSeconds {.gdExport.}:float = 1
  var compName {.gdExport.}:string

  var isReady:bool
  var watchElapsedSeconds:float
  var dllActualPath:string
  var dllHotPath:string
  var gdnsPath:string
  var isReloadInProgress:bool
  var compResource:Resource
  var compNode:Node

  method ready*() =
    self.dllActualPath = &"{dllDir}/{self.compName}.dll"
    self.dllHotPath = &"{dllDir}/{self.compName}_actual.dll"
    self.gdnsPath = &"gdns/{self.compName}.gdns"

    if fileExists(self.dllActualPath) and resource_loader.exists(self.gdnsPath):

      print &"{self.dllActualPath} last mod time {$getLastModificationTime(self.dllActualPath)}"
      print &"{self.dllHotPath} last mod time {$getLastModificationTime(self.dllHotPath)}"
      print &"{self.compName} exists"
      self.compResource = resource_loader.load(self.gdnsPath)
      if not isNil(self.compResource):
        self.isReady = true
        print &"{self.compName} loaded"
        self.testSpriteCreation()


  proc testSpriteCreation() =
    var texture = resource_loader.load("res://icon.png") as Texture
    var sprite = gdnew[Sprite]()
    sprite.texture = texture
    sprite.position = vec2(100, 100)
    sprite.name = "PluginSprite"
    sprite.setScript(self.compResource)
    #let root = self.getTree().root
    self.call_deferred("add_child", toVariant(sprite))


  method process*(delta: float64) =
    if not self.enableWatch or not self.isReady: return

    self.watchElapsedSeconds += delta
    if self.watchElapsedSeconds > self.watchIntervalSeconds:
      self.watchElapsedSeconds = 0.0
      #print "checking dll"

      #print &"{self.dllActualPath} last mod time {getLastModificationTime(self.dllActualPath)}"
      #print &"{self.dllHotPath} last mod time {getLastModificationTime(self.dllHotPath)}"
      if getLastModificationTime(self.dllActualPath) > getLastModificationTime(self.dllHotPath):
        print &"{self.dllActualPath}is newer than {self.dllHotPath}"
        #unload the component resource if it's loaded?
        #copyFile(dllActualFilename, dllHotFilename)

      #load the component from resource