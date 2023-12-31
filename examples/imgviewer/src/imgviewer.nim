import std/os

from uing/rawui import nil
import pixie
import uing

let
  image = readImage(paramStr(1))

proc rect(ctx: ptr DrawContext, x, y, width, height: float, r, g, b, a: uint8) {.inline.} = 
  var 
    brush: DrawBrush
    path = newDrawPath(DrawFillModeWinding)

  brush.r = cdouble (int(r)/255)
  brush.g = cdouble (int(g)/255)
  brush.b = cdouble (int(b)/255)
  brush.a = cdouble (int(a)/255)

  path.addRectangle(x, y, width, height)
  `end` path
  ctx.fill(path, addr brush)
  free path

proc drawHandler(a: ptr AreaHandler; area: ptr rawui.Area; p: ptr AreaDrawParams) {.cdecl.} =
  var 
    x, y: int
  
  for idx, pixel in image.data:
    rect(p.context, float x, float y, 1, 1, pixel.r, pixel.g, pixel.b, pixel.a)

    inc x

    if idx mod image.width == 0:
      inc y
      x = 0

proc main = 
  let window = newWindow("Image Viewer", image.width, image.height)
  window.margined = true
  # window.resizeable = false

  let box = newHorizontalBox(true)
  window.child = box

  var handler: AreaHandler
  handler.draw = drawHandler
  handler.mouseEvent = proc (_: ptr AreaHandler, a: ptr rawui.Area, b: ptr AreaMouseEvent) {.cdecl.} = discard
  handler.mouseCrossed = proc (_: ptr AreaHandler, a: ptr rawui.Area, b: cint) {.cdecl.} = discard
  handler.dragBroken = proc (_: ptr AreaHandler, a: ptr rawui.Area) {.cdecl.} = discard
  handler.keyEvent = proc (_: ptr AreaHandler, a: ptr rawui.Area, b: ptr AreaKeyEvent): cint {.cdecl.} = cint 0

  let area = newArea(addr handler)
  box.add area, true

  show window
  mainLoop()

init()
main()
