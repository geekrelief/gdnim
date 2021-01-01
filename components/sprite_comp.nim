import godot
import godotapi / [sprite, input_event_mouse_button, scene_tree, timer]
import hot
import strformat
import math, asyncdispatch

gdobj SpriteComp of Sprite:
  var startPos:Vector2 = vec2(600.0, 600.0)
  var radius:float = 350.0
  var speed:float = 0.01
  var elapsedTime:float
  var timer:Timer

  signal click()
  signal bclick(button_idx:int)
  signal bsclick(button_idx:int, shape_idx:int)

  method enter_tree() =
    discard register(sprite_comp)
    self.position = self.startPos
    self.timer = gdnew[Timer]()
    self.timer.one_shot = true
    self.add_child(self.timer)

  method ready() =
    var area2D = self.get_node("Area2D")
    discard area2D.connect("input_event", self, "on_area2d_input_event")
    discard self.connect("bsclick", self, "on_bsclick")

    registerFrameCallback(
      proc() =
        if hasPendingOperations():
          poll(0)
    )
    asyncCheck self.fireTimer()

  proc reload():seq[byte] {.gdExport.} =
    self.queue_free()

  proc on_area2d_input_event(viewport:Node, event:InputEvent, shape_idx:int) {.gdExport.} =
    ifis(event, InputEventMouseButton):
      if it.pressed:
        self.emit_signal("click")
        self.emit_signal("bclick", it.button_index.toVariant)
        self.emit_signal("bsclick", it.button_index.toVariant, shape_idx.toVariant)
        self.get_tree().set_input_as_handled()

  proc on_bsclick(button_idx:int, shape_idx:int) {.gdExport.} =
    print &"bsclick {button_idx = } {shape_idx = }"

  method process(delta:float64) =
    self.elapsedTime += delta
    var angle = self.elapsedTime * TAU * self.speed
    self.position = self.startPos + self.radius * vec2(cos(angle), sin(angle))

  proc rotate45() =
    self.rotation_degrees = self.rotation_degrees + 45

  proc fireTimer() {.async.} =
    await on_signal(self.get_tree().createTimer(1), "timeout")
    print "timeout sceneTree"

    var val = await on_signal(self, "bclick", int)
    print &"bclick {val = }"
    self.rotate45()

    var vals = await on_signal(self, "bsclick", tuple[button_idx:int, shape_idx:int])
    print &"bsclick {vals.button_idx = } {vals.shape_idx = }"
    self.rotate45()

    for c in "A LONG TIME AGO IN A GALAXY FAR, FAR AWAY":
      self.timer.start(0.05)
      await onSignal(self.timer, "timeout")
      print c

    var fast = false
    if fast: #nnkIfStmt
      self.timer.start(0.15)
      await on_signal(self.timer, "timeout")
      print "fast timeout"
    else: #nnkElseStmt
      self.timer.start(1.15)
      await on_signal(self.timer, "timeout")
      print "slow timeout"

    print "waiting for timeout 4 OR click"
    var f1 = on_signal(self.get_tree().createTimer(4), "timeout")
    var f2 = on_signal(self, "click")
    await f1 or f2
    if f1.finished:
      print "timeout or click: timeout"
    if f2.finished:
      print "timeout or click: click"
      self.rotate45()

    print "waiting for timeout 2 seconds AND click"
    await on_signal(self.get_tree().createTimer(2), "timeout") and on_signal(self, "click")
    print "timeout scene tree timer and click"
    self.rotate45()

    var c = 'b'
    case c:
      of 'a':
        print "case a, waiting for timeout"
        await on_signal(self.get_tree().createTimer(4), "timeout")
        print "tree timer timeout"
      else:
        print "case b, waiting for click"
        await on_signal(self, "click")
        print "click"
        self.rotate45()