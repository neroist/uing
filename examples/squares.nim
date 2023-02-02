# From https://ring-lang.github.io/doc1.14/libui.html#drawing-sample

import std/sugar

import uing
from uing/rawui import nil

# maybe add this to uing too?
proc rect(ctx: ptr DrawContext, x, y, width, height, r, g, b, a: float) = 
  var 
    brush: DrawBrush
    path = newDrawPath(DrawFillModeWinding)

  brush.r = cdouble r
  brush.g = cdouble g
  brush.b = cdouble b
  brush.a = cdouble a

  path.addRectangle(x, y, width, height)
  `end` path
  ctx.fill(path, addr brush)
  free path

proc drawHandler(a: ptr AreaHandler; area: ptr rawui.Area; p: ptr AreaDrawParams) {.cdecl.} =
  rect(p.context, 0, 0, p.areaWidth, p.areaHeight, 128/255, 128/255, 128/255, 1f)
  rect(p.context, 0, 0, 400, 400, 255/255, 255/255, 255/255, 1f)
  rect(p.context, 10, 10, 20, 20, 255/255, 0/255, 0/255, 1f)
  rect(p.context, 30, 30, 30, 30, 0/255, 255/255, 0/255, 1f)
  rect(p.context, 60, 60, 40, 40, 0/255, 0/255, 255/255, 1f)

proc main = 
  let window = newWindow("Drawing Sample", 420, 450)

  var handler: AreaHandler
  handler.draw = drawHandler
  handler.mouseEvent = (_: ptr AreaHandler, a: ptr rawui.Area, b: ptr AreaMouseEvent) {.cdecl.} => (discard)
  handler.mouseCrossed = (_: ptr AreaHandler, a: ptr rawui.Area, b: cint) {.cdecl.} => (discard)
  handler.dragBroken = (_: ptr AreaHandler, a: ptr rawui.Area) {.cdecl.} => (discard)
  handler.keyEvent = (_: ptr AreaHandler, a: ptr rawui.Area, b: ptr AreaKeyEvent) {.cdecl.} => cint 0

  let area = newArea(addr handler)
  window.child = area

  show window
  mainLoop()

when isMainModule:
  init()
  main()