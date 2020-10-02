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
  var watchIntervalSeconds {.gdExport.}:float = 3
  var compName {.gdExport.}:string

  var isReady:bool
  var isReloading:bool
  var reloadFrames:int
  var watchElapsedSeconds:float
  var dllActualPath:string
  var dllHotPath:string
  var gdnsPath:string

  method ready*() =
    self.dllActualPath = &"{dllDir}/{self.compName}_actual.dll"
    self.dllHotPath = &"{dllDir}/{self.compName}.dll"
    self.gdnsPath = &"res://gdns/{self.compName}.gdns"

    if fileExists(self.dllActualPath) and resource_loader.exists(self.gdnsPath):
      print &"{self.dllActualPath} last mod time {$getLastModificationTime(self.dllActualPath)}"
      print &"{self.dllHotPath} last mod time {$getLastModificationTime(self.dllHotPath)}"
      self.createSprite()


  proc createSprite() =
    #create a sprite but don't add it to anything it should self destruct since there are no references
    #discard resource_loader.load("res://curve.tres")
    discard resource_loader.load(self.gdnsPath)
    self.isReady = true
    #[
    var gdns = resource_loader.load(self.gdnsPath)
    if not isNil(gdns):
      print &"{self.compName} loaded"
      self.isReady = true
      var texture = resource_loader.load("res://icon.png") as Texture
      var sprite = gdnew[Sprite]()
      sprite.texture = texture
      sprite.position = vec2(100, 100)
      sprite.name = "PluginSprite"
      sprite.setScript(gdns)
      self.call_deferred("add_child", toVariant(sprite))
    else:
      print &"{self.gdnsPath} failed to load"
    ]#

  proc destroySprite() =
    print "destroying PluginSprite should remove all references to gdns resource"
    #self.get_child(0).queue_free()

  proc checkResourceIsLoaded() =
    self.reloadFrames += 1
    #[
    if resource_loader.has_cached("res://curve.tres"):
      print &"curve still here {self.reloadFrames}"
    else:
      print &"curve not cached {self.reloadFrames}"
      self.isReady = false
    ]#

    if resource_loader.has_cached(self.gdnsPath):
      print &"{self.gdnsPath} is still in resource cache: frame time {self.reloadFrames}"
    else:
      print &"{self.gdnsPath} not in resource cache: frame time {self.reloadFrames}"
      try:
        copyFile(self.dllActualPath, self.dllHotPath)
        print &"copyFile {self.dllActualPath} to {self.dllHotPath} worked"
      except:
        print &"could not copyFile {self.dllActualPath} to {self.dllHotPath}"
      finally:
        self.isReady = false # stop printing

  method process*(delta: float64) =
    if not self.enableWatch or not self.isReady: return
    self.checkResourceIsLoaded()
    #[
    if self.isReloading:
      print &"{self.compName} dll copying actual to hot"
      copyFile(self.dllActualPath, self.dllHotPath)
      print &"{self.dllActualPath} last mod time {$getLastModificationTime(self.dllActualPath)}"
      print &"{self.dllHotPath} last mod time {$getLastModificationTime(self.dllHotPath)}"
      self.createSprite()
      self.isReloading = false
      #reload data
      return

    self.watchElapsedSeconds += delta
    if self.watchElapsedSeconds > self.watchIntervalSeconds:
      self.watchElapsedSeconds = 0.0

      if not self.isReloading and getLastModificationTime(self.dllActualPath) > getLastModificationTime(self.dllHotPath):
        print &"{self.dllActualPath}is newer than {self.dllHotPath}"
        # save data
        self.destroySprite()
        self.isReloading = true
        self.reloadFrames = 0
    ]#