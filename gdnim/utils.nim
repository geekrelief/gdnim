import godot, godotapi/objects, asyncdispatch, macros
export asyncdispatch

# helper to convert types and execute body, if object can be cast to type
# example: ifis(event, InputEventKey): print it.scancode
template ifis*(a:typed, T:typed, body:untyped):untyped =
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
# toV self.call("myfunc", 123, true, idx) -> self.call("myfunc", newVariant(123), newVariant(true), newVariant(idx))
macro toV*(callNode:untyped):untyped =
  result = callNode
  template errOut =
    raise newException(VariantDefect, "toV expects method call with arguments in brackets, toV self.call(\"myfunc\", [123, true, id])")
  if callNode.kind != nnkCall:
    errOut
  var vargsIdx:int = -1
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