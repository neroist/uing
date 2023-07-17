import std/colors

import uing

proc d2dSolidBrush*(brush: var DrawBrush, color: Color, alpha: float = 1) {.inline.} =
  brush.type = DrawBrushTypeSolid
  
  let (r, g, b) = color.extractRGB()
  (brush.r, brush.g, brush.b) = (r / 255, g / 255, b / 255)

  brush.a = alpha

proc d2dClear*(p: ptr AreaDrawParams, color: Color, alpha: float = 1) {.inline.} =
  let path = newDrawPath(DrawFillModeWinding)

  var brush: DrawBrush
  d2dSolidBrush(brush, color, alpha)

  path.addRectangle(
    0, 0,
    p.areaWidth, p.areaHeight
  )

  `end` path
  
  p.context.fill(path, addr brush)

  free path

proc setStops*(brush: var DrawBrush, stops: openArray[DrawBrushGradientStop]) =
  for idx, stop in stops:
    brush.stops[][idx] = stop
