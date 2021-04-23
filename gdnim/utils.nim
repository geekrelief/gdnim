import godot, godotapi/[resource_loader, packed_scene],
  os, asyncdispatch, macros, strformat
from strutils import contains
export asyncdispatch,
  resource_loader, packed_scene

# find the scene at runtime, returns the first resource that matches sceneName
proc findScene*(sceneName: string): string =
  var tscnFilename = &"{sceneName}.tscn"
  var matches: seq[string]
  for f in walkDirRec("."):
    if f.contains(tscnFilename):
      matches.add move(&"res://{f}")
  if matches.len == 1:
    return matches[0]
  if matches.len == 0:
    raise newException(IOError, &"Scene resource for {sceneName} could not be found!")
  if matches.len > 1:
    raise newException(IOError, &"Multiple resources found with {sceneName}:\n\t{matches}")

proc loadScene*(compName: string): PackedScene =
  load(findScene(compName)) as PackedScene

# helper to convert types and execute body, if object can be cast to type
# example: ifis(event, InputEventKey): print it.scancode
template ifis*(a: typed, T: typed, body: untyped): untyped =
  if a of T:
    var it {.inject.} = a as T
    body

# starts polling for asyncdispatch
template startPolling*() =
  registerFrameCallback(
    proc() =
    if hasPendingOperations():
      poll(0)
  )

type
  VariantDefect* = object of Defect
 # converts bracket surrounded parameters of a method call to Variants
 # toV self.call("myfunc", [123, true, idx]) -> self.call("myfunc", newVariant(123), newVariant(true), newVariant(idx))
macro toV*(callNode: untyped): untyped =
  result = callNode
  template errOut =
    raise newException(VariantDefect, "toV expects method call with arguments in brackets, toV self.call(\"myfunc\", [123, true, id])")
  if callNode.kind != nnkCall:
    errOut
  var vargsIdx: int = -1
  for i in 0..<callNode.len:
    var arg = callNode[i]
    if arg.kind == nnkBracket:
      vargsIdx = i
  if vargsIdx == -1:
    errOut
  var vargs = callNode[vargsIdx]
  callNode.del(vargsIdx)
  for i in 0..<vargs.len:
    callNode.add newCall("newVariant", vargs[i])
