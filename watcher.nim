import godot
import godotapi / [engine, node]
import godotapi / [resource_loader, texture, sprite, packed_scene, scene_tree, viewport, label]
import dynlib, locks
import times
import strformat
import os, threadpool
import strutils, strformat, times
import msgpack4nim
export msgpack4nim

const dllDir:string = "_dlls"

gdobj Watcher of Node:

  var enableWatch {.gdExport.}:bool = true
  var watchIntervalSeconds {.gdExport.}:float = 3
  var compName {.gdExport.}:string

  var isReady:bool
  var isReloading:bool
  var watchElapsedSeconds:float
  var dllSafePath:string
  var dllHotPath:string
  var gdnsPath:string

  var compData:string
  var compPreReloadCB: proc():string {.gcsafe, locks:0.}

  method enter_tree*() =
    self.dllSafePath = &"{dllDir}/{self.compName}_safe.dll"
    self.dllHotPath = &"{dllDir}/{self.compName}.dll"
    self.gdnsPath = &"res://gdns/{self.compName}.gdns"

    if fileExists(self.dllSafePath) and resource_loader.exists(self.gdnsPath):
      print &"{self.dllSafePath} last mod time {$getLastModificationTime(self.dllSafePath)}"
      print &"{self.dllHotPath} last mod time {$getLastModificationTime(self.dllHotPath)}"
      self.createSprite()


  proc setPreReloadCB*(cb:proc():string {.gcsafe, locks:0.}) =
    self.compPreReloadCB = cb

  proc takePostReload*():string =
    result = self.compData
    self.compData = ""


  proc createSprite() =
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
      #self.call_deferred("add_child", toVariant(sprite)) # call if in ready
      self.add_child(sprite)
    else:
      print &"{self.gdnsPath} failed to load"

  proc beforeReload() =
    print &"Watcher {self.dllSafePath}is newer than {self.dllHotPath}"
    #print "Watcher preping reload, saving data and destroying references to component"
    self.compData = self.compPreReloadCB()
    self.compPreReloadCB = nil
    #print "Watcher destroying PluginSprite should remove all references to gdns resource"
    self.get_child(0).queue_free()

  proc afterReload() =
    print "Watcher creatingSprite and restoring data"
    self.createSprite()

  method process*(delta: float64) =
    if not self.enableWatch or not self.isReady: return

    if self.isReloading:
      if not resource_loader.has_cached(self.gdnsPath):
        try:
          print &"Watcher {self.compName} dll copying safe to hot"
          copyFile(self.dllSafePath, self.dllHotPath)
          print &"Watcher Success! copyFile {self.dllSafePath} to {self.dllHotPath} worked!"
          self.afterReload()
        except:
          print &"Fail! could not copyFile {self.dllSafePath} to {self.dllHotPath}"
          self.isReady = false # could not copy the dll and reload the sprite

      self.isReloading = false
      return

    self.watchElapsedSeconds += delta
    if self.watchElapsedSeconds > self.watchIntervalSeconds:
      self.watchElapsedSeconds = 0.0

      if not self.isReloading and getLastModificationTime(self.dllSafePath) > getLastModificationTime(self.dllHotPath):
        self.beforeReload()
        self.isReloading = true