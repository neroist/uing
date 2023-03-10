import std/random

import uing
from uing/rawui import nil

randomize()

var 
  histogram: Area
  handler: AreaHandler
  datapoints: array[10, Spinbox]
  colorButton: ColorButton
  currentPoint: int = -1

# some metrics

const
  xoffLeft = 20
  yoffTop = 20
  xoffRight = 20
  yoffBottom = 20
  pointRadius = 5

  colorWhite = 0x00FFFFFF
  colorBlack = 0x00000000
  colorDodgerBlue = 0x001E90FF
  
# helper to quickly set a brush color

proc setSolidBrush(brush: ptr DrawBrush; color: int; alpha: float) =
  brush.`type` = DrawBrushTypeSolid
  brush.r = ((color shr 16) and 0x000000FF) / 255
  brush.g = ((color shr 8) and 0x000000FF) / 255
  brush.b = ((color and 0x000000FF)) / 255
  brush.a = alpha

proc pointLocations(width: float; height: float; xs, ys: var array[10, float]) =
  var
    xincr = width / 9
    yincr = height / 100 

    n: int

  # 10 - 1 to make the last point be at the end
  for i in 0..<10:
    n = datapoints[i].value # get the value of the point
    n = 100 - n # because y=0 is the top but n=0 is the bottom, we need to flip
    xs[i] = xincr * float i
    ys[i] = yincr * float n

proc constructGraph(width, height: float; extend: bool): DrawPath =
  var
    xs: array[10, float]
    ys: array[10, float]

  pointLocations(width, height, xs, ys)

  result = newDrawPath(DrawFillModeWinding)
  result.newFigure(xs[0], ys[0])

  for i in 1..<10:
    result.lineTo(xs[i], ys[i])

  if extend:
    result.lineTo(width, height)
    result.lineTo(0, height)
    result.closeFigure()

  `end` result

func graphSize*(clientWidth, clientHeight: float): tuple[width, height: float] =
  result.width = clientWidth - xoffLeft - xoffRight
  result.height = clientHeight - yoffTop - yoffBottom

proc handlerDraw*(a: ptr AreaHandler; area: ptr rawui.Area; p: ptr AreaDrawParams) {.cdecl.} =  
  var 
    path: DrawPath
    brush: DrawBrush
    sp: DrawStrokeParams
    m: DrawMatrix

  var
    graphSize = graphSize(p.areaWidth, p.areaHeight) # figure out dimensions
    graphColor = colorButton.color

  # fill the area with white
  setSolidBrush(addr brush, colorWhite, 1.0)
  path = newDrawPath(DrawFillModeWinding)
  path.addRectangle(0, 0, p.areaWidth, p.areaHeight)
  `end` path
  p.context.fill(path, addr brush)
  free path

  # make a stroke for both the axes and the histogram line
  sp.cap = DrawLineCapFlat
  sp.join = DrawLineJoinMiter
  sp.thickness = 2
  sp.miterLimit = DrawDefaultMiterLimit

  # draw the axes
  setSolidBrush(addr brush, colorBlack, 1.0)
  path = newDrawPath(DrawFillModeWinding)
  path.newFigure(xoffLeft, yoffTop)
  path.lineTo(xoffLeft, yoffTop + graphSize.height)
  path.lineTo(xoffLeft + graphSize.width, yoffTop + graphSize.height)
  `end` path

  p.context.stroke(path, addr brush, addr sp)
  free path

  # now transform the coordinate space so (0, 0) is the top-left corner of the graph
  setIdentity(addr m)
  translate(addr m, xoffLeft, yoffTop)
  p.context.transform(addr m)

  # now get the color for the graph itself and set up the brush
  brush.`type` = DrawBrushTypeSolid
  brush.r = graphColor.r
  brush.g = graphColor.g
  brush.b = graphColor.b

  # we set brush.a below to different values for the fill and stroke
  # now create the fill for the graph below the graph line
  path = constructGraph(graphSize.width, graphSize.height, true)
  brush.a = graphColor.a / 2
  p.context.fill(path, addr(brush))
  free path

  # now draw the histogram line
  path = constructGraph(graphSize.width, graphSize.height, false)
  brush.a = graphColor.a
  p.context.stroke(path, addr brush, addr sp)
  free path

  # now draw the point being hovered over
  if currentPoint != -1:
    var
      xs: array[10, float]
      ys: array[10, float]

    pointLocations(graphSize.width, graphSize.height, xs, ys)

    path = newDrawPath(DrawFillModeWinding)
    path.newFigureWithArc(xs[currentPoint], ys[currentPoint],
                               pointRadius, 0, 6.23, # TODO pi
                               0)
    `end` path

    # use the same brush as for the histogram lines
    p.context.fill(path, addr brush)
    free path

func inPoint*(x, y, xtest, ytest: float): bool =
  let x = x - xoffLeft
  let y = y - yoffTop
  return (x >= xtest - pointRadius) and 
         (x <= xtest + pointRadius) and
         (y >= ytest - pointRadius) and 
         (y <= ytest + pointRadius)

proc handlerMouseEvent*(a: ptr AreaHandler; area: ptr rawui.Area; e: ptr AreaMouseEvent) {. cdecl .} =
  var
    graphSize = graphSize(e.areaWidth, e.areaHeight)

    xs: array[10, float]
    ys: array[10, float]

  pointLocations(graphSize.width, graphSize.height, xs, ys)

  for i in 0..<10:
    if inPoint(e.x, e.y, xs[i], ys[i]): 
      currentPoint = i
      break

    if i == 9: # not in a point
      currentPoint = -1

  histogram.queueRedrawAll()

proc main =
  handler.draw = handlerDraw
  handler.mouseEvent = handlerMouseEvent
  handler.mouseCrossed = proc (_: ptr AreaHandler, a: ptr rawui.Area, b: cint) {.cdecl.} = discard
  handler.dragBroken = proc (_: ptr AreaHandler, a: ptr rawui.Area) {.cdecl.} = discard
  handler.keyEvent = proc (_: ptr AreaHandler, a: ptr rawui.Area, b: ptr AreaKeyEvent): cint {.cdecl.} = cint 0

  var window = newWindow("libui-ng Histogram Example", 640, 480)
  window.margined = true

  var hbox = newHorizontalBox(true)
  window.child = hbox

  var vbox = newVerticalBox(true)
  hbox.add vbox

  for i in 0..<10:
    datapoints[i] = newSpinbox(0..100)
    datapoints[i].value = rand(100)
    datapoints[i].onchanged = proc (_: Spinbox) = histogram.queueRedrawAll()
    
    vbox.add datapoints[i]

  colorButton = newColorButton(proc (_: ColorButton) = histogram.queueRedrawAll())

  var brush: DrawBrush
  setSolidBrush(addr brush, colorDodgerBlue, 1.0)
  colorButton.setColor(brush.r, brush.g, brush.b, brush.a)
  vbox.add colorButton

  histogram = newArea(addr handler)

  hbox.add histogram, true

  show window
  mainLoop()

init()
main()
