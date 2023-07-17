import std/strutils
import std/colors
import std/math

from uing/rawui import nil
import uing

import ./d2d

proc drawOriginal(p: ptr AreaDrawParams)
proc drawArcs*(p: ptr AreaDrawParams)
proc drawD2DW8QS*(p: ptr AreaDrawParams)
proc drawD2DSimpleApp*(p: ptr AreaDrawParams)
# proc drawD2DSolidBrush*(p: ptr AreaDrawParams)
# proc drawD2DLinearBrush*(p: ptr AreaDrawParams)
# proc drawD2DGradientBrush*(p: ptr AreaDrawParams)
# proc drawD2DPathGeometries*(p: ptr AreaDrawParams)
# proc drawD2DGeometryGroup*(p: ptr AreaDrawParams)
# proc drawD2DRotate*(p: ptr AreaDrawParams)
# proc drawD2DScale*(p: ptr AreaDrawParams)
# proc drawD2DSkew*(p: ptr AreaDrawParams)
# proc drawD2DTranslate*(p: ptr AreaDrawParams)
# proc drawD2DMultiTransforms*(p: ptr AreaDrawParams)
# proc drawD2DComplexShape*(p: ptr AreaDrawParams)
# proc drawCSArc*(p: ptr AreaDrawParams)
# proc drawCSArcNegative*(p: ptr AreaDrawParams)
# proc drawCSClip*(p: ptr AreaDrawParams)
# proc drawCSCurveRectangle*(p: ptr AreaDrawParams)
# proc drawCSCurveTo*(p: ptr AreaDrawParams)
# proc drawCSDash*(p: ptr AreaDrawParams)
# proc drawCSFillAndStroke2*(p: ptr AreaDrawParams)
# proc drawCSFillStyle*(p: ptr AreaDrawParams)
# proc drawCSMultiCaps*(p: ptr AreaDrawParams)
# proc drawCSRoundRect*(p: ptr AreaDrawParams)
# proc drawCSSetLineCap*(p: ptr AreaDrawParams)
# proc drawCSSetLineJoin*(p: ptr AreaDrawParams)
# proc drawQ2DCreateWindowGC*(p: ptr AreaDrawParams)

const drawings = {
  "Original uiArea test": drawOriginal,
  "Arc test": drawArcs,
  "Direct2D: Direct2D Quickstart for Windows 8": drawD2DW8QS,
  "Direct2D: Creating a Simple Direct2D Application": drawD2DSimpleApp,
  # "Direct2D: How to Create a Solid Color Brush": drawD2DSolidBrush,
  # "Direct2D: How to Create a Linear Gradient Brush": drawD2DLinearBrush,
  # "Direct2D: How to Create a Radial Gradient Brush": drawD2DGradientBrush,
  # "Direct2D: Path Geometries Overview": drawD2DPathGeometries,
  # "Direct2D: How to Create Geometry Groups": drawD2DGeometryGroup,
  # "Direct2D: How to Rotate an Object": drawD2DRotate,
  # "Direct2D: How to Scale an Object": drawD2DScale,
  # "Direct2D: How to Skew an Object": drawD2DSkew,
  # "Direct2D: How to Translate an Object": drawD2DTranslate,
  # "Direct2D: How to Apply Multiple Transforms to an Object": drawD2DMultiTransforms,
  # "Direct2D: How to Draw and Fill a Complex Shape": drawD2DComplexShape,
  # "cairo samples: arc": drawCSArc,
  # "cairo samples: arc negative": drawCSArcNegative,
  # "cairo samples: clip": drawCSClip,
  # "cairo samples: curve rectangle": drawCSCurveRectangle,
  # "cairo samples: curve to": drawCSCurveTo,
  # "cairo samples: dash": drawCSDash,
  # "cairo samples: fill and stroke2": drawCSFillAndStroke2,
  # "cairo samples: fill style": drawCSFillStyle,
  # "cairo samples: multi segment caps": drawCSMultiCaps,
  # "cairo samples: rounded rectangle": drawCSRoundRect,
  # "cairo samples: set line cap": drawCSSetLineCap,
  # "cairo samples: set line join": drawCSSetLineJoin,
  # "Quartz 2D PG: Creating a Window Graphics Context in Mac OS X": drawQ2DCreateWindowGC
}

var 
  swallowKeys: Checkbox
  swallowMouse: Checkbox
  which: Combobox

proc drawOriginal(p: ptr AreaDrawParams) =
  var
    path: DrawPath
    brush: DrawBrush
    sp: DrawStrokeParams

  sp.dashes = nil
  sp.numDashes = 0
  sp.dashPhase = 0

  brush.type = DrawBrushTypeSolid
  brush.a = 1
  brush.r = 1

  path = newDrawPath(DrawFillModeWinding)
  path.newFigure(p.clipX + 5, p.clipY + 5)
  path.lineTo((p.clipX + p.clipWidth) - 5, (p.clipY + p.clipHeight) - 5)
  `end` path

  sp.cap = DrawLineCapFlat
  sp.join = DrawLineJoinMiter
  sp.thickness = 1
  sp.miterLimit = DrawDefaultMiterLimit

  p.context.stroke(path, addr brush, addr sp)

  free path

  # ---

  brush.r = 0
  brush.g = 0
  brush.b = 0.75
  path = newDrawPath(DrawFillModeWinding)
  path.newFigure(p.clipX, p.clipY)
  path.lineTo(p.clipX + p.clipWidth, p.clipY)
  path.lineTo(50, 150)
  path.lineTo(50, 50)
  path.closeFigure()
  `end` path

  sp.cap = DrawLineCapFlat
  sp.join = DrawLineJoinRound
  sp.thickness = 5
  p.context.stroke(path, addr brush, addr sp)

  free path

  # ---

  brush.r = 0
  brush.g = 0.75
  brush.b = 0
  brush.a = 0.5
  path = newDrawPath(DrawFillModeWinding)
  path.addRectangle(120, 80, 50, 50)
  `end` path

  p.context.fill(path, addr brush)

  free path

  # ---

  brush.a = 1
  brush.r = 0
  brush.g = 0.5
  brush.b = 0
  path = newDrawPath(DrawFillModeWinding)
  path.newFigure(5.5, 10.5)
  path.lineTo(5.5, 50.5)
  `end` path

  sp.cap = DrawLineCapFlat
  sp.join = DrawLineJoinMiter
  sp.thickness = 1
  sp.miterLimit = DrawDefaultMiterLimit
  p.context.stroke(path, addr brush, addr sp)

  free path

  # ---

  brush.r = 0.5
  brush.g = 0.75
  brush.b = 0
  path = newDrawPath(DrawFillModeWinding)
  path.newFigure(400, 100)
  path.arcTo(400, 100,
    50,
    30 * (PI / 180),
    300 * (PI / 180),
    0)
  # the sweep test below doubles as a clockwise test so a checkbox isn't needed anymore
  path.lineTo(400, 100)
  path.newFigureWithArc(
    510, 100,
    50,
    30 * (PI / 180),
    300 * (PI / 180),
    0)
  path.closeFigure()
  # and now with 330 to make sure sweeps work properly
  path.newFigure(400, 210)
  path.arcTo(
    400, 210,
    50,
    30 * (PI / 180),
    330 * (PI / 180),
    0);
  path.lineTo(400, 210)
  path.newFigureWithArc(
    510, 210,
    50,
    30 * (PI / 180),
    330 * (PI / 180),
    0)
  path.closeFigure()
  `end` path

  sp.cap = DrawLineCapFlat
  sp.join = DrawLineJoinMiter
  sp.thickness = 1
  sp.miterLimit = DrawDefaultMiterLimit
  p.context.stroke(path, addr brush, addr sp)

  free path

  # ---

  brush.r = 0
  brush.g = 0.5
  brush.b = 0.75
  path = newDrawPath(DrawFillModeWinding)
  path.newFigure(300, 300)
  path.bezierTo(
    350, 320,
    310, 390,
    435, 372)
  `end` path

  sp.cap = DrawLineCapFlat
  sp.join = DrawLineJoinMiter
  sp.thickness = 1
  sp.miterLimit = DrawDefaultMiterLimit
  p.context.stroke(path, addr brush, addr sp)

  free path

proc drawArcs(p: ptr AreaDrawParams) = 
  var
    path: DrawPath
    start, step: float = 20
    rad: float = 25
    x, y: float = start + rad
    angle: float # = 0
    add: float = (2 * PI) / 12
    brush: DrawBrush
    sp: DrawStrokeParams

  sp.dashes = nil
  sp.numDashes = 0
  sp.dashPhase = 0

  path = newDrawPath(DrawFillModeWinding)

  for _ in 0..12:
    path.newFigureWithArc(
      x, y,
      rad,
      0, angle,
      0
    )

    angle += add
    x += 2 * rad + step

  y += 2 * rad + step
  x = start + rad
  angle = 0

  for _ in 0..12:
    path.newFigure(x, y)
    path.arcTo(
      x, y,
      rad,
      0, angle,
      0
    )

    angle += add
    x += 2 * rad + step

  y += 2 * rad + step
  x = start + rad
  angle = 0

  for _ in 0..12:
    path.newFigureWithArc(
      x, y,
      rad,
      (PI / 4), angle,
      0
    )

    angle += add
    x += 2 * rad + step

  y += 2 * rad + step
  x = start + rad
  angle = 0

  for _ in 0..12:
    path.newFigure(x, y)
    path.arcTo(
      x, y,
      rad,
      (PI / 4), angle,
      0
    )

    angle += add
    x += 2 * rad + step

  y += 2 * rad + step
  x = start + rad
  angle = 0

  for _ in 0..12:
    path.newFigureWithArc(
      x, y,
      rad,
      PI + (PI / 5), angle,
      0
    )

    angle += add
    x += 2 * rad + step

  y += 2 * rad + step
  x = start + rad
  angle = 0

  for _ in 0..12:
    path.newFigure(x, y)
    path.arcTo(
      x, y,
      rad,
      PI + (PI / 5), angle,
      0
    )

    angle += add
    x += 2 * rad + step

  `end` path

  brush.type = DrawBrushTypeSolid
  brush.r = 0
  brush.g = 0
  brush.b = 0
  brush.a = 1
  sp.cap = DrawLineCapFlat
  sp.join = DrawLineJoinMiter
  sp.thickness = 1
  sp.miterLimit = DrawDefaultMiterLimit
  p.context.stroke(path, addr brush, addr sp)

  free path

proc drawD2DW8QS(p: ptr AreaDrawParams) = 
  var 
    path: DrawPath
    brush: DrawBrush

  path = newDrawPath(DrawFillModeWinding)
  d2dSolidBrush(brush, colBlack)

  path.addRectangle(
    100, 100,
    (p.areaWidth - 100) - 100, 
    (p.areaHeight - 100) - 100
  )

  `end` path
  
  p.context.fill(path, addr brush)

  free path

proc drawD2DSimpleApp(p: ptr AreaDrawParams) =
  var
    path: DrawPath
    lightSlateGray, cornflowerBlue: DrawBrush
    sp: DrawStrokeParams

  sp.dashes = nil
  sp.numDashes = 0
  sp.dashPhase = 0

  d2dSolidBrush(lightSlateGray, colLightSlateGray)
  d2dSolidBrush(cornflowerBlue, colCornflowerBlue)

  d2dClear(p, colWhite)

  sp.thickness = 0.5
  sp.cap = DrawLineCapFlat
  sp.join = DrawLineJoinMiter
  sp.miterLimit = DrawDefaultMiterLimit

  for x in countup(0, int (p.areaWidth - 1), 10):
    path = newDrawPath(DrawFillModeWinding)
    path.newFigure(float x, 0)
    path.lineTo(float x, p.areaHeight)
    `end` path

    p.context.stroke(path, addr lightSlateGray, addr sp)
    free path
  
  for y in countup(0, int (p.areaHeight - 1), 10):
    path = newDrawPath(DrawFillModeWinding)
    path.newFigure(0, float y)
    path.lineTo(p.areaWidth, float y)
    `end` path
    
    p.context.stroke(path, addr lightSlateGray, addr sp)
    free path

  var
    left = (p.areaWidth / 2) - 50
    right = (p.areaWidth / 2) + 50
    top = (p.areaHeight / 2) - 50
    bottom = (p.areaHeight / 2) + 50
 
  path = newDrawPath(DrawFillModeWinding);
  path.addRectangle(left, top, right - left, bottom - top);
  `end` path

  p.context.fill(path, addr lightSlateGray);
  free path

  left = (p.areaWidth / 2) - 100
  right = (p.areaWidth / 2) + 100
  top = (p.areaHeight / 2) - 100
  bottom = (p.areaHeight / 2) + 100

  path = newDrawPath(DrawFillModeWinding);
  path.addRectangle(left, top, right - left, bottom - top);
  `end` path

  sp.thickness = 1.0;
  p.context.stroke(path, addr cornflowerBlue, addr sp);
  free path
  
proc handlerDraw(ah: ptr AreaHandler; area: ptr rawui.Area; p: ptr AreaDrawParams) {.cdecl.} = 
  # idx 1 is the proc
  drawings[which.selected][1](p)

proc handlerMouseEvent(ah: ptr AreaHandler; area: ptr rawui.Area; e: ptr AreaMouseEvent) {.cdecl.} = 
  if not swallowMouse.checked:
    return
  
  echo "mouse ($1, $2):($3, $4) down:$5 up:$6 count:$7 mods:$8 held:$9" % [
    $e.x,
    $e.y,
    $e.areaWidth,
    $e.areaHeight,
    $ bool(e.down),
    $ bool(e.up),
    $ bool(e.count),
    $ e.modifiers,
    $ bool(e.held1To64)
  ]

proc handlerMouseCrossed(ah: ptr AreaHandler; area: ptr rawui.Area; left: cint) {.cdecl.} = 
  if not swallowMouse.checked:
    return
  
  echo "mouse crossed ", left

proc handlerDragBroken(ah: ptr AreaHandler; area: ptr rawui.Area) {.cdecl.} = 
  if not swallowMouse.checked:
    return
  
  echo "drag broken"

proc handlerKeyEvent(ah: ptr AreaHandler; area: ptr rawui.Area; e: ptr AreaKeyEvent): cint {.cdecl.} = 
  if not swallowKeys.checked:
    return
  
  echo "key key:$1 extkey:$2 mod:$3 mods:$4 up:$5" % [
    "'" & e.key & "'\0",
    $e.extKey,
    $e.modifier,
    $e.modifiers,
    $ bool(e.up)
  ]

  return cint swallowKeys.checked

proc main() =
  var
    area: Area
    handler: AreaHandler

  let window = newWindow("Drawings", 800, 600)
  window.margined = true
  
  let box = newVerticalBox()
  window.child = box

  let hbox = newHorizontalBox()
  box.add(hbox)

  which = newCombobox([]) do (_: ComboBox):
    area.queueRedrawAll()
  
  for drawing in drawings:
    which.add drawing[0]
  
  which.selected = 0
  hbox.add which, true

  area = newArea(addr handler)
  box.add area, true

  let hbox2 = newHorizontalBox()
  box.add hbox2

  swallowKeys = newCheckbox("Consider key events handled")
  hbox2.add swallowKeys

  swallowMouse = newCheckbox("Consider mouse events handled")
  hbox2.add swallowMouse, true

  let enableArea = newCheckbox("Enable Area") do (c: Checkbox):
    if c.checked:
      enable area
    else:
      disable area
  enableArea.checked = true
  hbox2.add enableArea

  handler.draw = handlerDraw
  handler.mouseEvent = handlerMouseEvent
  handler.mouseCrossed = handlerMouseCrossed
  handler.dragBroken = handlerDragBroken
  handler.keyEvent = handlerKeyEvent

  show window
  mainLoop()

init()
main()
