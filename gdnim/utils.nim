import godot, godotapi/objects, asyncdispatch
export asyncdispatch

# helper to convert types and execute body, if object can be cast to type
# example: ifis(event, InputEventKey): print it.scancode
template ifis*(a:typed, T:typed, body:untyped):untyped =
  if a of T:
    var it {.inject.} = a as T
    body

# auto conversion of parameters to Variants for emit_signal
proc emit*(obj:Object, sig:string, args:varargs[Variant, `newVariant`]) =
  obj.emit_signal(sig, args)

# starts polling for asyncdispatch
template startPolling*() =
  registerFrameCallback(
    proc() =
      if hasPendingOperations():
        poll(0)
  )