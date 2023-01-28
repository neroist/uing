import std/times

import uing/rawui

type
  Widget* = ref object of RootRef ## abstract Widget base class.
    internalImpl*: pointer

func impl*(w: Widget): ptr[Control] = cast[ptr Control](w.internalImpl)

proc init*() =
  var 
    o: rawui.InitOptions
    err = rawui.init(addr o)

  if err != nil:
    let msg = $err

    freeInitError(err)
    raise newException(ValueError, msg)

proc quit* = rawui.quit()

proc mainLoop*() =
  rawui.main()
  rawui.uninit()

proc pollingMainLoop*(poll: proc(timeout: int); timeout: int) =
  ## Can be used to merge an async event loop with UI's event loop.
  ## Implemented using timeouts and polling because that's the only
  ## thing that truely composes.
  
  rawui.mainSteps()

  while true:
    poll(timeout)
    discard rawui.mainStep(0) # != 0: break

  rawui.uninit()

template newFinal(result) =
  #proc finalize(x: type(result)) {.nimcall.} =
  #  controlDestroy(x.impl)
  new(result) #, finalize)

#[
template voidCallback(name, supertyp, basetyp, on) {.dirty.} =
  proc name(w: ptr rawui.supertyp; data: pointer) {.cdecl.} =
    let widget = cast[basetyp](data)
    if widget.on != nil: widget.on()

template intCallback(name, supertyp, basetyp, on) {.dirty.} =
  proc name(w: ptr rawui.supertyp; data: pointer) {.cdecl.} =
    let widget = cast[basetyp](data)
    if widget.on != nil: widget.on(widget.value)
]#

template genCallback(name, typ, on) {. dirty .} =
  proc name(w: ptr rawui.typ; data: pointer) {.cdecl.} =
    let widget = cast[typ](data)
    if widget.on != nil: widget.on(widget)
  
template genImplProcs(t: untyped) {.dirty.}=
  type `Raw t` = ptr[rawui.t]
  func impl*(b: t): `Raw t` = cast[`Raw t`](b.internalImpl)
  func `impl=`*(b: t, r: `Raw t`) = b.internalImpl = pointer(r)


# -------------------- Non-Widgets --------------------------------------

# -------- funcs --------

proc timer*(milliseconds: int; f: proc (data: pointer): cint {.cdecl.}; data: pointer) = 
  rawui.timer(cint milliseconds, f, data)

proc free*(str: string) = rawui.freeText(str) 

# -------- Font Descriptor --------

export TextWeight, TextItalic, TextStretch

type
  FontDescriptor* = ref object # thinking of renaming to "Font"
    family*  : string
    size*    : float
    weight*  : TextWeight
    italic*  : TextItalic
    stretch* : TextStretch

    internalImpl: pointer

genImplProcs(FontDescriptor)

proc loadControlFont*(f: FontDescriptor) = loadControlFont f.impl
proc free*(f: FontDescriptor) = freeFontDescriptor f.impl

proc newFontDescriptor*(
  family: string, 
  size: float | int, 
  weight: TextWeight = TextWeightNormal, 
  italic: TextItalic = TextItalicNormal, 
  stretch: TextStretch = TextStretchNormal): FontDescriptor =
  newFinal result

  proc impl: RawFontDescriptor =
    var font = rawui.FontDescriptor(
      family: cstring family,
      size: float size, 
      weight: weight,
      italic: italic,
      stretch: stretch
    )

    return font.addr

  result.impl = impl()

# -------- Area --------

type
  Area* = ref object of Widget
    handler: AreaHandler

export 
  WindowResizeEdge, 
  Modifiers, 
  ExtKey, 
  AreaDrawParams, 
  AreaMouseEvent, 
  AreaKeyEvent,
  AreaHandler

genImplProcs(Area)

proc `size=`*(a: Area, size: tuple[width, height: int]) = areaSetSize(a.impl, cint size.width, cint size.height)
proc queueRedrawAll*(a: Area) = areaQueueRedrawAll(a.impl)
proc beginUserWindowMove*(a: Area) = areaBeginUserWindowMove(a.impl)
proc beginUserWindowResize*(a: Area; edge: WindowResizeEdge) = areaBeginUserWindowResize(a.impl, edge)
proc newArea*(ah: ptr AreaHandler): Area =
  newFinal result
  result.handler = ah[]
  result.impl = rawui.newArea(ah)
  
proc newScrollingArea*(ah: ptr AreaHandler; width: int; height: int): Area =
  newFinal result
  result.impl = rawui.newScrollingArea(ah, cint width, cint height)

# -------- Drawing --------

type
  DrawPath* = ref object
    internalImpl: pointer
  
  DrawMatrix* = ref object
    m11*, m12*, m21*, m22*, m31*, m32*: float

    internalImpl: pointer

export DrawFillMode, DrawBrushType, DrawLineCap, DrawLineJoin

genImplProcs(DrawPath)
genImplProcs(DrawMatrix)

proc newDrawPath*(fillMode: DrawFillMode): DrawPath =
  newFinal result
  result.impl = rawui.drawNewPath(fillMode)

proc free*(p: DrawPath) = drawFreePath(p.impl)

proc newFigure*(p: DrawPath; x: float; y: float) = drawPathNewFigure(p.impl, cdouble x, cdouble y)

proc newFigureWithArc*(p: DrawPath; xCenter, yCenter, radius, startAngle, sweep: float; negative: int) = 
  drawPathNewFigureWithArc(
    p.impl, cdouble xCenter, cdouble yCenter, cdouble radius, cdouble startAngle, cdouble sweep, 
    cint negative
  )

proc lineTo*(p: DrawPath; x, y: float) = drawPathLineTo(p.impl, cdouble x, cdouble y)

proc arcTo*(p: DrawPath; xCenter, yCenter, radius, startAngle, sweep: float; negative: int) =
  drawPathArcTo(p.impl, cdouble xCenter, cdouble yCenter, cdouble radius, cdouble startAngle, cdouble sweep, cint negative)

proc bezierTo*(p: DrawPath; c1x, c1y, c2x, c2y, endX, endY: float) =
  drawPathBezierTo(p.impl, cdouble c1x, cdouble c1y, cdouble c2x, cdouble c2y, cdouble endX, cdouble endY)

proc closeFigure*(p: DrawPath) = drawPathCloseFigure(p.impl)

proc addRectangle*(p: DrawPath; x, y, width, height: float) =
  drawPathAddRectangle(p.impl, cdouble x, cdouble y, cdouble width, cdouble height)

proc ended*(p: DrawPath): bool = bool drawPathEnded(p.impl)
proc `end`*(p: DrawPath) = drawPathEnd(p.impl)

proc stroke*(c: ptr DrawContext; path: DrawPath; b: ptr DrawBrush; p: ptr DrawStrokeParams) = 
  rawui.drawStroke(c, path.impl, b, p)

proc fill*(c: ptr DrawContext; path: DrawPath; b: ptr DrawBrush) =
  rawui.drawFill(c, path.impl, b)

proc setIdentity*(m: DrawMatrix) = drawMatrixSetIdentity(m.impl)

proc translate*(m: DrawMatrix; x, y: float) = drawMatrixTranslate(m.impl, cdouble x, cdouble y)

proc scale*(m: DrawMatrix; xCenter, yCenter, x, y: float) = 
  drawMatrixScale(m.impl, cdouble xCenter, cdouble yCenter, cdouble x, cdouble y)

proc rotate*(m: DrawMatrix; x, y, amount: float) =
  drawMatrixRotate(m.impl, cdouble x, cdouble y, cdouble amount)

proc skew*(m: DrawMatrix; x, y, xamount, yamount: float) =
  drawMatrixSkew(m.impl, cdouble x, cdouble y, cdouble xamount, cdouble yamount)

proc multiply*(dest: DrawMatrix; src: DrawMatrix) = drawMatrixMultiply(dest.impl, src.impl)

proc invertible*(m: DrawMatrix): bool = bool drawMatrixInvertible(m.impl)

proc invert*(m: DrawMatrix): int = int drawMatrixInvert(m.impl)

proc transformPoint*(m: DrawMatrix): tuple[x, y: float] =
  var x, y: cdouble

  drawMatrixTransformPoint(m.impl, addr x, addr y)
  result = (x: float x, y: float y)

proc transformSize*(m: DrawMatrix): tuple [x, y: float] =
  var x, y: cdouble

  drawMatrixTransformSize(m.impl, addr x, addr y)
  result = (x: float x, y: float y)

# -------- Attributes --------

type
  Attribute* = ref object
    internalImpl: pointer

  AttributedString* = ref object
    internalImpl: pointer

export AttributeType

genImplProcs(Attribute)
genImplProcs(AttributedString)

proc newAttributedString*(initialString: string): AttributedString =
  newFinal result
  result.impl = rawui.newAttributedString(cstring initialString)

proc free*(a: AttributedString) = freeAttributedString(a.impl)

proc `$`*(s: AttributedString): string =
  $attributedStringString(s.impl) 

proc len*(s: AttributedString): BiggestUInt =
  BiggestUInt attributedStringLen(s.impl) 

proc addUnattributed*(s: AttributedString; str: string) =
  attributedStringAppendUnattributed(s.impl, cstring str)

proc insertAtUnattributed*(s: AttributedString; str: string; at: BiggestUInt) =
  attributedStringInsertAtUnattributed(s.impl, cstring str, csize_t at)

proc delete*(s: AttributedString; start, `end`: BiggestUInt) =
  attributedStringDelete(s.impl, csize_t start, csize_t `end`)

proc setAttribute*(s: AttributedString; a: Attribute; start, `end`: BiggestUInt) =
  attributedStringSetAttribute(s.impl, a.impl, csize_t start, csize_t `end`)

proc forEachAttribute*(s: AttributedString; f: rawui.AttributedStringForEachAttributeFunc; data: pointer) =
  attributedStringForEachAttribute(s.impl, f, data)

proc numGraphemes*(s: AttributedString): BiggestUInt =
  attributedStringNumGraphemes(s.impl)

proc byteIndexToGrapheme*(s: AttributedString; pos: BiggestUInt): BiggestUInt =
  attributedStringByteIndexToGrapheme(s.impl, csize_t pos)

proc graphemeToByteIndex*(s: AttributedString; pos: BiggestUInt): BiggestUInt = 
  attributedStringGraphemeToByteIndex(s.impl, csize_t pos)

# attribute 

proc free*(a: Attribute) = freeAttribute(a.impl)

proc getType*(a: Attribute): AttributeType = attributeGetType(a.impl)

proc newFamilyAttribute*(family: string): Attribute = 
  newFinal result
  result.impl = rawui.newFamilyAttribute(cstring family)

proc family*(a: Attribute): string =
  $attributeFamily(a.impl)

proc newSizeAttribute*(size: float): Attribute =
  newFinal result
  result.impl = rawui.newSizeAttribute(cdouble size)

proc size*(a: Attribute): float =
  float rawui.attributeSize(a.impl) 


export TextWeight, TextItalic

proc newWeightAttribute*(weight: TextWeight): Attribute =
  newFinal result
  result.impl = rawui.newWeightAttribute(weight)

proc weight*(a: Attribute): TextWeight =
  attributeWeight(a.impl)

proc newItalicAttribute*(italic: TextItalic): Attribute =
  newFinal result
  result.impl = rawui.newItalicAttribute(italic)

proc italic*(a: Attribute): TextItalic =
  attributeItalic(a.impl)


export TextStretch

proc newStretchAttribute*(stretch: TextStretch): Attribute =
  newFinal result
  result.impl = rawui.newStretchAttribute(stretch)

proc stretch*(a: Attribute): TextStretch =
  attributeStretch(a.impl)

proc newColorAttribute*(r: cdouble; g: cdouble; b: cdouble; a: cdouble): Attribute =
  newFinal result
  result.impl = rawui.newColorAttribute(r, g, b, a)

proc color*(a: Attribute): tuple[r, g, b, alpha: float] =
  var r, g, b, alpha: cdouble

  attributeColor(a.impl, addr r, addr g, addr b, addr alpha)
  result = (r: float r, g: float g, b: float b, alpha: float alpha)

proc newBackgroundAttribute*(r, g, b, a: float): Attribute =
  newFinal result
  result.impl = rawui.newBackgroundAttribute(cdouble r, cdouble g, cdouble b, cdouble a)


export Underline, UnderlineColor

proc newUnderlineAttribute*(u: Underline): Attribute =
  newFinal result
  result.impl = rawui.newUnderlineAttribute(u)

proc underline*(a: Attribute): Underline =
  attributeUnderline(a.impl)

proc newUnderlineColorAttribute*(u: UnderlineColor; r, g, b, a: float): Attribute =
  newFinal result
  result.impl = rawui.newUnderlineColorAttribute(u, cdouble r, cdouble g, cdouble b, cdouble a)

proc underlineColor*(a: Attribute): tuple[u: UnderlineColor, r, g, b, alpha: float] = 
  var r, g, b, alpha: cdouble
  var u: UnderlineColor

  attributeUnderlineColor(a.impl, addr u, addr r, addr g, addr b, addr alpha)
  result = (u: u, r: float r, g: float g, b: float b, alpha: float alpha)


# -------- Open Type Features --------

type
  OpenTypeFeatures* = ref object
    internalImpl: pointer

genImplProcs(OpenTypeFeatures)

proc newOpenTypeFeatures*(): OpenTypeFeatures =
  newFinal result
  result.impl = rawui.newOpenTypeFeatures()

proc free*(otf: OpenTypeFeatures) = freeOpenTypeFeatures(otf.impl)

#proc features*(otf: OpenTypeFeatures) =
#  freeOpenTypeFeatures(otf.impl)

proc clone*(otf: OpenTypeFeatures): OpenTypeFeatures =
  newFinal result
  result.impl = openTypeFeaturesClone(otf.impl)

proc add*(otf: OpenTypeFeatures; a, b, c, d: char, value: uint32) =
  openTypeFeaturesAdd(otf.impl, a, b, d, d, value)

proc remove*(otf: OpenTypeFeatures; a, b, c, d: char) =
  openTypeFeaturesRemove(otf.impl, a, b, d, d)

proc get*(otf: OpenTypeFeatures; a, b, c, d: char, value: var uint32): bool =
  bool openTypeFeaturesGet(otf.impl, a, b, d, c, addr value)

proc forEach*(otf: OpenTypeFeatures; f: rawui.OpenTypeFeaturesForEachFunc; data: pointer) =
  openTypeFeaturesForEach(otf.impl, f, data)

proc newFeaturesAttribute*(otf: OpenTypeFeatures): Attribute =
  newFinal result
  result.impl = rawui.newFeaturesAttribute(otf.impl)

proc features*(a: Attribute): OpenTypeFeatures =
  newFinal result
  result.impl = rawui.attributeFeatures(a.impl)

# -------- Draw Text --------
type
  DrawTextLayout* = ref object
    internalImpl: pointer

export DrawTextAlign, DrawTextLayoutParams

genImplProcs(DrawTextLayout)

proc newDrawTextLayout*(params: ptr DrawTextLayoutParams): DrawTextLayout =
  newFinal result
  result.impl = drawNewTextLayout(params)

proc free*(tl: DrawTextLayout) =
  drawFreeTextLayout(tl.impl)

proc drawText*(c: ptr DrawContext; tl: DrawTextLayout; x, y: float) =
  rawui.drawText(c, tl.impl, cdouble x, cdouble y)

proc extents*(tl: DrawTextLayout): tuple[width, height: float] =
  var w, h: cdouble

  drawTextLayoutExtents(tl.impl, addr w, addr h)
  result = (width: float w, height: float h)

# ------------------- Button --------------------------------------
type
  Button* = ref object of Widget
    ## A widget that visually represents a button to be clicked by the user to trigger an action.
    
    onclick*: proc (sender: Button) ## callback for when the button is clicked.

genCallback wrapOnClick, Button, onclick

genImplProcs(Button)

proc text*(b: Button): string =
  ## Returns the button label text.
  
  $buttonText(b.impl)

proc `text=`*(b: Button; text: string) =
  ## Sets the button label text.
  ## 
  ## `b`: Button instance
  ## 
  ## `text`: Label text

  buttonSetText(b.impl, text)

proc newButton*(text: string; onclick: proc(sender: Button) = nil): Button =
  ## Creates and returns a new button.
  ## 
  ## `text`: Button label text
  ## 
  ## `onclick`: callback for when the button is clicked.

  newFinal(result)
  result.impl = rawui.newButton(text)
  result.onclick = onclick
  result.impl.buttonOnClicked(wrapOnClick, cast[pointer](result))

# ------------------------ RadioButtons ----------------------------

type
  RadioButtons* = ref object of Widget
    onSelected*: proc(sender: RadioButtons) 

genCallback(wrapOnRadioButtonClick, RadioButtons, onSelected)

genImplProcs(RadioButtons)

proc add*(r: RadioButtons; items: varargs[string]) = 
  for text in items:
    radioButtonsAppend(r.impl, cstring text)

proc radioButtonsSelected*(r: RadioButtons): int =
  radioButtonsSelected(r.impl)

proc selected*(r: RadioButtons): int =
  radioButtonsSelected(r.impl)

proc `selected=`*(r: RadioButtons, index: int) =
  radioButtonsSetSelected(r.impl, cint index)

proc newRadioButtons*(onSelected: proc(sender: RadioButtons)  = nil): RadioButtons =
  newFinal(result)
  result.impl = rawui.newRadioButtons()
  result.onSelected = onSelected
  result.impl.radioButtonsOnSelected(wrapOnRadioButtonClick, cast[pointer](result))

# ----------------- Window -------------------------------------------

type
  Window* = ref object of Widget
    ## A Widget that represents a top-level window.
    ## 
    ## A window contains exactly one child widget that occupies the entire window.
    ## 
    ## .. note:: Many of the Window methods should be regarded as mere hints.
    ##    The underlying system may override these or even choose to ignore them
    ##    completely. This is especially true for many Unix systems.
    ## 
    ## .. warning:: A Window can NOT be a child of another Widget.

    onclosing*: proc (sender: Window): bool
    onfocuschanged*: proc(sender: Window)
    child: Widget
    
genImplProcs(Window)

proc title*(w: Window): string =
  ## Returns the window title.
  ## 
  ## `w`: Window instance.

  $windowTitle(w.impl)

proc `title=`*(w: Window; text: string) =
  ## Returns the window title.
  ## 
  ## .. note:: This method is merely a hint and may be ignored on unix platforms.
  ## 
  ## 
  ## `w`: Window instance.
  ## 
  ## `title`: Window title text.
  
  windowSetTitle(w.impl, text)

proc contentSize*(window: Window): tuple[width, height: int] = 
  ## Gets the window content size.
  ## 
  ## .. note:: The content size does NOT include window decorations like menus or title bars.
  ## 
  ## 
  ## `window`: Window instance.

  var w, h: cint
  windowContentSize(window.impl, addr w, addr h)

  result = (width: int w, height: int h)

proc `contentSize=`*(window: Window, size: tuple[width, height: int]) = 
  ## Gets the window content size.
  ## 
  ## .. note:: The content size does NOT include window decorations like menus or title bars.
  ## 
  ## .. note:: This method is merely a hint and may be ignored by the system.
  ## 
  ## 
  ## `window`: Window instance.
  ## 
  ## `size.width`: Window content width to set.
  ## 
  ## `size.height`:  Window content height to set.
  
  windowSetContentSize(window.impl, cint size.width, cint size.height)

proc fullscreen*(w: Window): bool = 
  ## Returns whether or not the window is full screen.
  ## 
  ## `w`: Window instance.
  
  bool windowFullscreen(w.impl)

proc `fullscreen=`*(w: Window, fullscreen: bool) = 
  ## Returns whether or not the window is full screen.
  ## 
  ## .. note:: This method is merely a hint and may be ignored by the system.
  ## 
  ## 
  ## `w`: Window instance.
  ## 
  ## `fullscreen`: `true` to make window full screen, `false` otherwise.
  
  windowSetFullscreen(w.impl, cint fullscreen)

proc focused*(w: Window): bool = 
  ## Returns whether or not the window is focused.
  ## 
  ## `w`: Window instance.
  
  bool windowFocused(w.impl)

proc borderless*(w: Window): bool =
  ## Returns whether or not the window is borderless.
  ## 
  ## `w`: Window instance.

  bool windowBorderless(w.impl)

proc `borderless=`*(w: Window, borderless: bool) = 
  ## Returns whether or not the window is full screen.
  ## 
  ## .. note:: This method is merely a hint and may be ignored by the system.
  ## 
  ## 
  ## `w`: Window instance.
  ## 
  ## `borderless`: `true` to make window borderless, `false` otherwise.

  windowSetBorderless(w.impl, cint borderless)

proc resizeable*(w: Window): bool = 
  ## Returns whether or not the window is user resizeable.
  ## 
  ## `w`: Window instance.
  
  bool windowResizeable(w.impl)

proc `resizeable=`*(w: Window, resizeable: bool) = 
  ## Sets whether or not the window is user resizeable.
  ## 
  ## .. note:: This method is merely a hint and may be ignored by the system.
  ## 
  ## 
  ## `w`: Window instance.
  ## 
  ## `resizeable`: `true` to make window resizable, `false` otherwise.

  windowSetResizeable(w.impl, cint resizeable)

#proc destroy*(w: Window) =
#  ## this needs to be called if the callback passed to addQuitItem returns
#  ## true. Don't ask...
#
#  controlDestroy(w.impl)

proc margined*(w: Window): bool = 
  ## Returns whether or not the window has a margin.i
  ## 
  ## `w`: Window instance.
  
  windowMargined(w.impl) != 0

proc `margined=`*(w: Window; x: bool) = 
  ## Sets whether or not the window has a margin.
  ## The margin size is determined by the OS defaults.
  ## 
  ## `w`: Window instance.
  ## 
  ## `margined`: `true` to set a window margin, `false` otherwise.

  windowSetMargined(w.impl, cint(x))

proc child*(w: Window): Widget = w.child

proc `child=`*(w: Window; child: Widget) =
  ##  Sets the window's child.
  ## 
  ## `w`: Window instance.
  ## 
  ## `child`: Widget to be made child.

  windowSetChild(w.impl, child.impl)
  w.child = child

proc openFile*(parent: Window): string =
  let x = openFile(parent.impl)
  result = $x
  if x != nil: freeText(x)

proc openFolder*(parent: Window): string =
  let x = openFolder(parent.impl)
  result = $x
  if x != nil: freeText(x)

proc saveFile*(parent: Window): string =
  let x = saveFile(parent.impl)
  result = $x
  if x != nil: freeText(x)

proc msgBox*(parent: Window; title, desc: string) =
  msgBox(parent.impl, title, desc)

proc msgBoxError*(parent: Window; title, desc: string) =
  msgBoxError(parent.impl, title, desc)

proc error*(parent: Window; title, desc: string) =
  ## Alias for `msgBoxError`

  msgBoxError(parent, title, desc)

proc onClosingWrapper(rw: ptr rawui.Window; data: pointer): cint {.cdecl.} =
  let w = cast[Window](data)
  if w.onclosing != nil:
    if w.onclosing(w):
      controlDestroy(w.impl)
      rawui.quit()
      system.quit()

genCallback wrapOnFocusChangedWrapper, Window, onfocuschanged

proc newWindow*(title: string; width, height: int; hasMenubar: bool = false, onfocuschanged: proc (sender: Window) = nil): Window =
  ## Creates and returns a new Window.
  ## 
  ## `title`: Window title text.
  ## 
  ## `width`: Window width.
  ## 
  ## `height`: Window height.
  ## 
  ## `hasMenubar`: Whether or not the window should display a menu bar.
  ## 
  ## `onfocuschanged`: Callback for when the window focus changes.

  newFinal(result)
  result.impl = rawui.newWindow(title, cint width, cint height,
                                cint hasMenubar)
  result.onfocuschanged = onfocuschanged
  result.onclosing = proc (_: Window): bool = return true
  windowOnFocusChanged(result.impl, wrapOnFocusChangedWrapper, cast[pointer](result))
  windowOnClosing(result.impl, onClosingWrapper, cast[pointer](result))


# ------------------------- Box ------------------------------------------

type
  Box* = ref object of Widget
    ## A boxlike container that holds a group of widgets.
    ##  
    ## The contained widgets are arranged to be displayed either horizontally or
    ## vertically next to each other.
    
    children*: seq[Widget] ## The widgets contained within the box.
    
genImplProcs(Box)

proc add*(b: Box; child: Widget; stretchy = false) =
  ## Appends a widget to the box.
  ## 
  ## Stretchy items expand to use the remaining space within the box.
  ## In the case of multiple stretchy items the space is shared equally.
  ## 
  ## `b`: Box instance.
  ## 
  ## `child`: widget instance to append.
  ## 
  ## `stretchy`: `true` to stretch widget,`false` otherwise. Default is `false`.

  boxAppend(b.impl, child.impl, cint(stretchy))
  b.children.add child

proc add*(c: Box; items: openArray[Widget]; stretchy = false) = 
  ## Adds multiple widgets to the box

  for item in items:
    c.add item, stretchy

proc delete*(b: Box; index: int) = 
  ## Removes the widget at `index` from the box.
  ## 
  ## .. note:: The widget is neither destroyed nor freed.
  ## 
  ## 
  ## `b`: Box instance.
  ## 
  ## `index`: Index of widget to be removed.
  
  boxDelete(b.impl, index.cint)
  b.children.del index

proc padded*(b: Box): bool = 
  ## Returns whether or not widgets within the box are padded.
  ## 
  ## Padding is defined as space between individual widgets.
  ## 
  ## `b`: Box instance.

  bool boxPadded(b.impl)

proc `padded=`*(b: Box; x: bool) = 
  ## Sets whether or not widgets within the box are padded.
  ## 
  ## Padding is defined as space between individual widgets.
  ## The padding size is determined by the OS defaults.
  ## 
  ## `b`: Box instance.
  ## 
  ## `padded : `true` to make widgets padded, `false` otherwise.

  boxSetPadded(b.impl, x.cint)

proc newHorizontalBox*(padded = false): Box =
  ## Creates and returns a new horizontal box.
  ## 
  ## Widgets within the box are placed next to each other horizontally.
  ## 
  ## `padded`: `true` to make widgets padded, `false` otherwise.

  newFinal(result)
  result.impl = rawui.newHorizontalBox()
  result.children = @[]
  boxSetPadded(result.impl, padded.cint)

proc newVerticalBox*(padded = false): Box =
  ## Creates a new vertical box.
  ## 
  ## Widgets within the box are placed next to each other vertically.
  ## 
  ## `padded`: `true` to make widgets padded, `false` otherwise.

  newFinal(result)
  result.impl = rawui.newVerticalBox()
  result.children = @[]
  boxSetPadded(result.impl, padded.cint)

# -------------------- Checkbox ----------------------------------

type
  Checkbox* = ref object of Widget
    ## A widget with a user checkable box accompanied by a text label.

    ontoggled*: proc (sender: Checkbox) ## callback for when the checkbox is toggled by the user.
    
genImplProcs(Checkbox)

proc text*(c: Checkbox): string = 
  ## Returns the checkbox label text.
  ## 
  ## `c`: Checkbox instance.

  $checkboxText(c.impl)

proc `text=`*(c: Checkbox; text: string) = 
  ## Sets the checkbox label text.
  ## 
  ## `c`: Checkbox instance.
  ## 
  ## `text`: Label text.
  
  checkboxSetText(c.impl, text)

genCallback(wrapOntoggled, Checkbox, ontoggled)

proc checked*(c: Checkbox): bool = 
  ## Returns whether or the checkbox is checked.
  ## 
  ## `c`: Checkbox instance.
  
  checkboxChecked(c.impl) != 0

proc `checked=`*(c: Checkbox; x: bool) =
  ## Sets whether or not the checkbox is checked.
  ## 
  ## `c`: Checkbox instance.
  ## 
  ## `checked`: `true` to check box, `false` otherwise.
  
  checkboxSetChecked(c.impl, cint(x))

proc newCheckbox*(text: string; ontoggled: proc(sender: Checkbox) = nil): Checkbox =
  ## Creates and returns a new checkbox.
  ## 
  ## `text`: Checkbox label text
  ## 
  ## `ontoggled`: Callback for when the checkbox is toggled by the user.

  newFinal(result)
  result.impl = rawui.newCheckbox(text)
  result.ontoggled = ontoggled
  checkboxOnToggled(result.impl, wrapOntoggled, cast[pointer](result))

# ------------------ Entry ---------------------------------------

type
  Entry* = ref object of Widget
    ## A control with a single line text entry field.

    onchanged*: proc (sender: Entry) ## Callback for when the user changes the entry's text.

genImplProcs(Entry)

proc text*(e: Entry): string = 
  ## Returns the entry's text.
  ## 
  ## `e`: Entry instance.
  
  $entryText(e.impl)

proc `text=`*(e: Entry; text: string) = 
  ## Sets the entry's text.
  ## 
  ## `e`: Entry instance.
  ## 
  ## `text`: Entry text
  
  entrySetText(e.impl, text)

proc readOnly*(e: Entry): bool = 
  ## Returns whether or not the entry's text can be changed.
  ## 
  ## `e`: Entry instance.
  
  entryReadOnly(e.impl) != 0

proc `readOnly=`*(e: Entry; readOnly: bool) =
  ## Sets whether or not the entry's text is read only.
  ## 
  ## `e`: Entry instance.
  ## 
  ## `readonly`: `true` to make read only, `false` otherwise.
  
  entrySetReadOnly(e.impl, cint readOnly)

genCallback(wrapOnchanged, Entry, onchanged)

proc newEntry*(text: string = ""; onchanged: proc(sender: Entry) = nil): Entry =
  ## Creates a new entry.
  ## 
  ## `text`: Entry text
  ## 
  ## `onchanged`: Callback for when the user changes the entry's text.
  
  newFinal(result)
  result.impl = rawui.newEntry()
  result.impl.entryOnChanged(wrapOnchanged, cast[pointer](result))
  result.onchanged = onchanged
  entrySetText(result.impl, text)

proc newPasswordEntry*(text: string = ""; onchanged: proc(sender: Entry) = nil): Entry =
  ## Creates a new entry suitable for sensitive inputs like passwords.
  ## 
  ## The entered text is NOT readable by the user but masked as *******.
  ## 
  ## `text`: Entry text
  ## 
  ## `onchanged`: Callback for when the user changes the entry's text.
  
  newFinal(result)
  result.impl = rawui.newPasswordEntry()
  result.impl.entryOnChanged(wrapOnchanged, cast[pointer](result))
  result.onchanged = onchanged
  entrySetText(result.impl, text)

proc newSearchEntry*(text: string = ""; onchanged: proc(sender: Entry) = nil): Entry =
  ## Creates a new entry suitable for search.
  ## 
  ## Some systems will deliberately delay the uiEntryOnChanged() callback for
  ## a more natural feel.
  ## 
  ## `text`: Entry text
  ## 
  ## `onchanged`: Callback for when the user changes the entry's text.

  newFinal(result)
  result.impl = rawui.newSearchEntry()
  result.impl.entryOnChanged(wrapOnchanged, cast[pointer](result))
  result.onchanged = onchanged
  entrySetText(result.impl, text)

# ----------------- Label ----------------------------------------

type
  Label* = ref object of Widget
    ## A widget that displays non interactive text.

genImplProcs(Label)

proc text*(l: Label): string = 
  ## Returns the label text.
  ## 
  ## `l`: Lable Instance
  
  $labelText(l.impl)

proc `text=`*(l: Label; text: string) = 
  ## Sets the label text.
  ## 
  ## `l`: Lable Instance
  ## 
  ## `text`: Label text.

  labelSetText(l.impl, text)

proc newLabel*(text: string = ""): Label =
  ## Creates a new label.
  ## 
  ## `text`: Label text.
  
  newFinal(result)
  result.impl = rawui.newLabel(text)

# ---------------- Tab --------------------------------------------

type
  Tab* = ref object of Widget
    children*: seq[Widget]
    
genImplProcs(Tab)

proc add*(t: Tab; name: string; c: Widget) =
  tabAppend t.impl, name, c.impl
  t.children.add c

proc insertAt*(t: Tab; name: string; at: int; c: Widget) =
  tabInsertAt(t.impl, name, at.cint, c.impl)
  t.children.insert(c, at)

proc delete*(t: Tab; index: int) =
  tabDelete(t.impl, index.cint)
  t.children.delete(index)

proc margined*(t: Tab; index: int): bool = 
  bool tabMargined(t.impl, index.cint) 

proc setMargined*(t: Tab; index: int; margined: bool) = 
  tabSetMargined(t.impl, cint index, cint margined)

proc newTab*(): Tab =
  ## Creates a new tab container.
  
  newFinal result
  result.impl = rawui.newTab()
  result.children = @[]

# ------------- Group --------------------------------------------------

type
  Group* = ref object of Widget
    child: Widget
    
genImplProcs(Group)

proc title*(g: Group): string = $groupTitle(g.impl)
proc `title=`*(g: Group; title: string) =
  groupSetTitle(g.impl, title)

proc child*(g: Group; c: Widget): Widget = g.child 
proc `child=`*(g: Group; c: Widget) =
  groupSetChild(g.impl, c.impl)
  g.child = c

proc margined*(g: Group): bool = groupMargined(g.impl) != 0
proc `margined=`*(g: Group; x: bool) =
  groupSetMargined(g.impl, x.cint)

proc newGroup*(title: string; margined=false): Group =
  newFinal result
  result.impl = rawui.newGroup(title)
  groupSetMargined(result.impl, margined.cint)

# ----------------------- Spinbox ---------------------------------------

type
  Spinbox* = ref object of Widget
    ## A control to display and modify integer values via a text field or +/- buttons.
    ## 
    ## This is a convenient control for having the user enter integer values.
    ## Values are guaranteed to be within the specified range.
    ## 
    ## The + button increases the held value by 1.
    ## 
    ## The - button decreased the held value by 1.
    ## 
    ## Entering a value out of range will clamp to the nearest value in range.

    onchanged*: proc(sender: Spinbox) ## Callback for when the spinbox value is changed by the user.
    
genImplProcs(Spinbox)

proc value*(s: Spinbox): int = 
  spinboxValue(s.impl)

proc `value=`*(s: Spinbox; value: int) = 
  spinboxSetValue(s.impl, value.cint)

genCallback wrapsbOnChanged, Spinbox, onchanged

proc newSpinbox*(min, max: int; onchanged: proc (sender: Spinbox) = nil): Spinbox =
  newFinal result
  result.impl = rawui.newSpinbox(cint min, cint max)
  result.onchanged = onchanged
  spinboxOnChanged result.impl, wrapsbOnChanged, cast[pointer](result)

# ---------------------- Slider ---------------------------------------

type
  Slider* = ref object of Widget
    onchanged*  : proc(sender: Slider)
    onreleased* : proc(sender: Slider)
    
genImplProcs(Slider)

proc value*(s: Slider): int = sliderValue(s.impl)
proc `value=`*(s: Slider; value: int) = sliderSetValue(s.impl, cint value)
proc `range=`*(s: Slider; sliderRange: tuple[min, max: int]) = sliderSetRange(s.impl, cint sliderRange.min, cint sliderRange.max)
proc setRange*(s: Slider; min, max: int) = sliderSetRange(s.impl, cint min, cint max)
proc hasToolTip*(s: Slider): bool = bool sliderHasToolTip(s.impl)
proc `hasToolTip=`*(s: Slider, hasToolTip: bool) = sliderSetHasToolTip(s.impl, cint hasToolTip)

genCallback wrapslOnChanged, Slider, onchanged
genCallback wrapslOnReleased, Slider, onreleased

proc newSlider*(min, max: int; onchanged: proc (sender: Slider) = nil): Slider =
  newFinal result
  result.impl = rawui.newSlider(cint min, cint max)
  result.onchanged = onchanged
  sliderOnChanged result.impl, wrapslOnChanged, cast[pointer](result)
  sliderOnReleased result.impl, wrapslOnReleased, cast[pointer](result)

# ------------------- Progressbar ---------------------------------

type
  ProgressBar* = ref object of Widget

genImplProcs(ProgressBar)

proc value*(p: ProgressBar): int = int progressBarValue(p.impl)

proc `value=`*(p: ProgressBar; n: int) =
  if n < -1:
    raise newException(ValueError, "ProgressBar value can not be lower than -1")

  progressBarSetValue p.impl, n.cint

proc indeterminate*(p: ProgressBar): bool = p.value == -1
proc `indeterminate=`*(p: ProgressBar, indeterminate: bool) = 
  if indeterminate: p.value = -1
proc setIndeterminate*(p: ProgressBar) = p.value = -1

proc newProgressBar*(): ProgressBar =
  newFinal result
  result.impl = rawui.newProgressBar()

# ------------------------- Separator ----------------------------

type
  Separator* = ref object of Widget
  
genImplProcs(Separator)

proc newVerticalSeparator*(): Separator = 
  newFinal result
  result.impl = rawui.newVerticalSeparator()

proc newHorizontalSeparator*(): Separator =
  newFinal result
  result.impl = rawui.newHorizontalSeparator()

# ------------------------ Combobox ------------------------------

type
  Combobox* = ref object of Widget
    items*: seq[string]
    onselected*: proc (sender: Combobox)
    
genImplProcs(Combobox)

proc add*(c: Combobox; items: varargs[string]) = 
  for text in items:
    comboboxAppend(c.impl, cstring text)
    c.items.add text

proc insertAt*(c: Combobox; index: int; text: string) = 
  comboboxInsertAt(c.impl, cint index, text)
  c.items.insert text, index

proc clear*(c: Combobox) = 
  comboboxClear(c.impl)
  c.items = @[]

proc delete*(c: Combobox, index: int) = 
  comboboxDelete(c.impl, cint index)
  c.items.del index

proc numItems*(c: Combobox): int = int comboboxNumItems(c.impl)
proc selected*(c: Combobox): int = comboboxSelected(c.impl)
proc `selected=`*(c: Combobox; n: int) = comboboxSetSelected c.impl, cint n

genCallback wrapbbOnSelected, Combobox, onselected

proc newCombobox*(onselected: proc(sender: Combobox) = nil): Combobox =
  newFinal result
  result.impl = rawui.newCombobox()
  result.onselected = onselected
  comboboxOnSelected(result.impl, wrapbbOnSelected, cast[pointer](result))

# ----------------------- EditableCombobox ----------------------

type
  EditableCombobox* = ref object of Widget
    onchanged*: proc (sender: EditableCombobox)
    
genImplProcs(EditableCombobox)

proc add*(c: EditableCombobox; items: varargs[string]) = 
  for text in items:
    editableComboboxAppend(c.impl, cstring text)

proc text*(c: EditableCombobox): string =
  $editableComboboxText(c.impl)

proc `text=`*(c: EditableCombobox; text: string) =
  editableComboboxSetText(c.impl, text)

genCallback wrapecbOnchanged, EditableCombobox, onchanged

proc newEditableCombobox*(onchanged: proc (sender: EditableCombobox) = nil): EditableCombobox =
  newFinal result
  result.impl = rawui.newEditableCombobox()
  result.onchanged = onchanged
  editableComboboxOnChanged result.impl, wrapecbOnchanged, cast[pointer](result)

# ------------------------ MultilineEntry ------------------------------

type
  MultilineEntry* = ref object of Widget
    onchanged*: proc (sender: MultilineEntry)
    
genImplProcs(MultilineEntry)

proc text*(e: MultilineEntry): string = $multilineEntryText(e.impl)
proc `text=`*(e: MultilineEntry; text: string) = multilineEntrySetText(e.impl, text)
proc add*(e: MultilineEntry; text: string) = multilineEntryAppend(e.impl, text)

genCallback wrapmeOnchanged, MultilineEntry, onchanged

proc readonly*(e: MultilineEntry): bool = multilineEntryReadOnly(e.impl) != 0
proc `readonly=`*(e: MultilineEntry; x: bool) = multilineEntrySetReadOnly(e.impl, cint(x))

proc newMultilineEntry*(onchanged: proc(sender: MultilineEntry) = nil): MultilineEntry =
  newFinal result
  result.impl = rawui.newMultilineEntry()
  multilineEntryOnChanged(result.impl, wrapmeOnchanged, cast[pointer](result))

proc newNonWrappingMultilineEntry*(onchanged: proc(sender: MultilineEntry) = nil): MultilineEntry =
  newFinal result
  result.impl = rawui.newNonWrappingMultilineEntry()
  multilineEntryOnChanged(result.impl, wrapmeOnchanged, cast[pointer](result))

# ---------------------- MenuItem ---------------------------------------

type
  MenuItem* = ref object of Widget
    onclicked*: proc (sender: MenuItem)
    
genImplProcs(MenuItem)

proc enable*(m: MenuItem) = menuItemEnable(m.impl)
proc disable*(m: MenuItem) = menuItemDisable(m.impl)

proc wrapmeOnclicked(sender: ptr rawui.MenuItem;
                     window: ptr rawui.Window; data: pointer) {.cdecl.} =
  let m = cast[MenuItem](data)
  if m.onclicked != nil: m.onclicked(m)

proc checked*(m: MenuItem): bool = menuItemChecked(m.impl) != 0
proc `checked=`*(m: MenuItem; x: bool) = menuItemSetChecked(m.impl, cint(x))

# -------------------- Menu ---------------------------------------------

type
  Menu* = ref object of Widget
    children*: seq[MenuItem]
    
genImplProcs(Menu)

template addMenuItemImpl(ex) =
  newFinal result
  result.impl = ex
  menuItemOnClicked(result.impl, wrapmeOnclicked, cast[pointer](result))
  m.children.add result

proc addItem*(m: Menu; name: string, onclicked: proc(sender: MenuItem) = proc(_: MenuItem) = discard): MenuItem {.discardable.} =
  addMenuItemImpl(menuAppendItem(m.impl, name))
  result.onclicked = onclicked

proc addCheckItem*(m: Menu; name: string, onclicked: proc(sender: MenuItem) = proc(_: MenuItem) = discard): MenuItem {.discardable.} =
  addMenuItemImpl(menuAppendCheckItem(m.impl, name))
  result.onclicked = onclicked

type
  ShouldQuitClosure = ref object
    fn: proc(): bool

proc wrapOnShouldQuit(data: pointer): cint {.cdecl.} =
  let c = cast[ShouldQuitClosure](data)
  result = cint(c.fn())
  if result == 1:
    GC_unref c

{. push discardable .}

proc addQuitItem*(m: Menu, shouldQuit: proc(): bool): MenuItem =
  newFinal result
  result.impl = menuAppendQuitItem(m.impl)
  m.children.add result
  var cl = ShouldQuitClosure(fn: shouldQuit)
  GC_ref cl
  onShouldQuit(wrapOnShouldQuit, cast[pointer](cl))

proc addPreferencesItem*(m: Menu, onclicked: proc(sender: MenuItem) = proc(_: MenuItem) = discard): MenuItem  =
  addMenuItemImpl(menuAppendPreferencesItem(m.impl))
  result.onclicked = onclicked

proc addAboutItem*(m: Menu, onclicked: proc(sender: MenuItem) = proc(_: MenuItem) = discard): MenuItem =
  addMenuItemImpl(menuAppendAboutItem(m.impl))
  result.onclicked = onclicked

{. pop .}

proc addSeparator*(m: Menu) =
  menuAppendSeparator m.impl

proc newMenu*(name: string): Menu =
  newFinal result
  result.impl = rawui.newMenu(name)
  result.children = @[]

# -------------------- Font Button --------------------------------------

type
  FontButton* = ref object of Widget
    onchanged*: proc(sender: FontButton)

genImplProcs(FontButton)

proc font*(f: FontButton): FontDescriptor =
  var font: rawui.FontDescriptor
  fontButtonFont(f.impl, addr font)

  result = FontDescriptor(
    family: $font.family,
    size: font.size,
    weight: font.weight,
    italic: font.italic,
    stretch: font.stretch
  )

proc freeFont*(f: FontDescriptor) = freeFontButtonFont(f.impl)

genCallback fontButtonOnChanged, FontButton, onchanged

proc newFontButton*(onChanged: proc(sender: FontButton) = nil): FontButton =
  newFinal result
  result.impl = rawui.newFontButton()
  result.onchanged = onChanged
  fontButtonOnChanged(result.impl, fontButtonOnChanged, cast[pointer](result))


# -------------------- ColorButton --------------------------------------

type 
  ColorButton* = ref object of Widget
    onchanged*: proc (sender: ColorButton)

genImplProcs(ColorButton)

proc color*(c: ColorButton): tuple[r, g, b, a: float] = 
  var r, g, b, a: cdouble
  colorButtonColor(c.impl, addr r, addr g, addr b, addr a)

  result = (r: float r, g: float g, b: float b, a: float a)

proc setColor*(c: ColorButton; r, g, b, alpha: float = 1.0) = 
  colorButtonSetColor(c.impl, r, b, g, alpha)

#[
proc setColor*(c: ColorButton; color: colors.Color; alpha: float) = 
  let rgb = color.extractRGB
  colorButtonSetColor(c.impl, cdouble (rgb.r / 255), cdouble (rgb.b / 255), cdouble (rgb.g / 255), cdouble alpha)
]#

genCallback wrapOnChanged, ColorButton, onchanged

proc newColorButton*(onchanged: proc (sender: ColorButton) = nil): ColorButton =
  newFinal result
  result.impl = rawui.newColorButton()
  result.onchanged = onchanged
  colorButtonOnChanged(result.impl, wrapOnChanged, cast[pointer](result))

# -------------------- Form --------------------------------------

type
  Form* = ref object of Widget
    chlidren*: seq[tuple[label: string, widget: Widget]]

genImplProcs(Form)

proc add*(f: Form, label: string, w: Widget, stretchy: bool = false) = 
  formAppend(f.impl, label, w.impl, cint stretchy)
  f.chlidren.add (label: label, widget: w)

# maybe kinda useless since you can do len(form.children)
proc numChildren*(f: Form): int = int formNumChildren(f.impl)

proc delete*(f: Form, index: int) = 
  formDelete(f.impl, cint index)
  f.chlidren.del index

proc padded*(f: Form): bool = bool formPadded(f.impl)
proc `padded=`*(f: Form, padded: bool) = formSetPadded(f.impl, cint padded)

proc newForm*(): Form = 
  newFinal result
  result.impl = rawui.newForm()

# -------------------- Grid --------------------------------------

type
  Grid* = ref object of Widget

export Align, At

genImplProcs(Grid)

proc add*(g: Grid; w: Widget; left, top, xspan, yspan: int, hexpand: bool; halign: Align; vexpand: bool; valign: Align) =
  gridAppend(g.impl, w.impl, cint left, cint top, cint xspan, cint yspan, cint hexpand, halign, cint vexpand, valign)

proc insertAt*(g: Grid; w, existing: Widget; at: At; left, top, xspan, yspan, hexpand: int; halign: Align; vexpand: int; valign: Align) = 
  gridInsertAt(g.impl, w.impl, existing.impl, at, cint xspan, cint yspan, cint hexpand, halign, cint vexpand, valign) 

proc padded*(g: Grid): bool = bool gridPadded(g.impl)
proc `padded=`*(g: Grid, padded: bool) = gridSetPadded(g.impl, cint padded)

proc newGrid*(): Grid = 
  newFinal result
  result.impl = rawui.newGrid()

# -------------------- Image --------------------------------------

type
  Image* = ref object of Widget

genImplProcs(Image)

proc add*(i: Image; pixels: pointer; pixelWidth: int; pixelHeight: int; byteStride: int) =
  imageAppend(i.impl, pixels, cint pixelWidth, cint pixelHeight, cint byteStride)

proc free*(i: Image) = freeImage(i.impl)

proc newImage*(width, height: float): Image =
  newFinal result
  result.impl = rawui.newImage(width.cdouble, height.cdouble)

# -------------------- Table --------------------------------------

export 
  TableSelection,
  TableSelectionMode, 
  TableModelHandler, 
  TableModel, 
  TableParams, 
  TableTextColumnOptionalParams, 
  TableColumnType, 
  TableValueType, 
  TableValue,

  newTableModel, 
  freeTableModel, 
  TableModelColumnNeverEditable, 
  TableModelColumnAlwaysEditable, 
  SortIndicator


type
  Table* = ref object of Widget
    onRowClicked: proc (sender: Table; row: int)
    onRowDoubleClicked: proc (sender: Table; row: int)
    onHeaderClicked: proc (sender: Table; column: int)
    onSelectionChanged: proc (sender: Table)

genImplProcs(Table)

proc free*(t: ptr TableValue) = freeTableValue(t)
proc free*(t: ptr TableModel) = freeTableModel(t)
proc free*(t: ptr rawui.TableSelection) = freeTableSelection(t)

proc tableValueGetType*(v: ptr TableValue): TableValueType {.inline.} = rawui.tableValueGetType(v)

proc newTableValueString*(s: string): ptr TableValue {.inline.} = rawui.newTableValueString(s.cstring)
proc tableValueString*(v: ptr TableValue): string {.inline.} = $rawui.tableValueString(v)

proc newTableValueImage*(img: Image): ptr TableValue = rawui.newTableValueImage(img.impl)
proc tableValueImage*(v: ptr TableValue): Image =
  newFinal result
  result.impl = rawui.tableValueImage(v)

proc newTableValueInt*(i: int): ptr TableValue {.inline.} = rawui.newTableValueInt(i.cint)
proc tableValueInt*(v: ptr TableValue): int {.inline.} = rawui.tableValueInt(v)

proc newTableValueColor*(r: float; g: float; b: float; a: float): ptr TableValue {.inline.} = rawui.newTableValueColor(r, g, b, a)
proc tableValueColor*(v: ptr TableValue; r: ptr float; g: ptr float;
                      b: ptr float; a: ptr float) {.inline.} = rawui.tableValueColor(v, r, g, b, a)


proc rowInserted*(m: ptr TableModel; newIndex: int) {.inline.} = rawui.tableModelRowInserted(m, newIndex.cint)
proc rowChanged*(m: ptr TableModel; index: int) {.inline.} = rawui.tableModelRowChanged(m, index.cint)
proc rowDeleted*(m: ptr TableModel; oldIndex: int) {.inline.} = rawui.tableModelRowDeleted(m, oldIndex.cint)


proc appendTextColumn*(table: Table, title: string, index, editableMode: int, textParams: ptr TableTextColumnOptionalParams) =
  table.impl.tableAppendTextColumn(title, index.cint, editableMode.cint, textParams)

proc appendImageColumn*(table: Table, title: string, index: int) =
  table.impl.tableAppendImageColumn(title, index.cint)

proc appendImageTextColumn*(table: Table, title: string, imageIndex, textIndex, editableMode: int, textParams: ptr TableTextColumnOptionalParams) =
  table.impl.tableAppendImageTextColumn(title, imageIndex.cint, textIndex.cint, editableMode.cint, textParams)

proc appendCheckboxColumn*(table: Table, title: string, index, editableMode: int) =
  table.impl.tableAppendCheckboxColumn(title, index.cint, editableMode.cint)

proc appendProgressBarColumn*(table: Table, title: string, index: int) =
  table.impl.tableAppendProgressBarColumn(title, index.cint)

proc appendButtonColumn*(table: Table, title: string, index, clickableMode: int) =
  table.impl.tableAppendButtonColumn(title, index.cint, clickableMode.cint)

proc headerVisible*(t: Table): bool = bool tableHeaderVisible(t.impl)
proc `headerVisible=`*(t: Table; visible: bool) = tableHeaderSetVisible(t.impl, cint visible)
proc headerSetVisible*(t: Table; visible: bool) = tableHeaderSetVisible(t.impl, cint visible)

proc selectionMode*(table: Table): TableSelectionMode = tableGetSelectionMode(table.impl)
proc `selectionMode=`*(table: Table, mode: TableSelectionMode)= tableSetSelectionMode(table.impl, mode)

proc columnWidth*(table: Table, column: int): int = int tableColumnWidth(table.impl, cint column)
proc setColumnWidth*(table: Table, column, width: int) = tableColumnSetWidth(table.impl, cint column, cint width)

proc sortIndicator*(table: Table, column: int): SortIndicator = tableHeaderSortIndicator(table.impl, cint column)
proc setSortIndicator*(table: Table, column: int, indicator: SortIndicator) = tableHeaderSetSortIndicator(table.impl, cint column, indicator)

proc selection*(table: Table): tuple[numRows: int, row: int] =
  let tSelection = tableGetSelection(table.impl)

  result.numRows = tSelection.numRows
  result.row = int (if tSelection.rows != nil: tSelection.rows[]
                   else: -1)

proc `selection=`*(table: Table; selection: int) =
  var s = cint selection

  var tSelection = TableSelection(
    numRows: 1,
    rows: addr s
  )

  tableSetSelection(table.impl, addr tSelection)

proc tableOnRowClickedCb(w: ptr rawui.Table; row: cint; data: pointer) {.cdecl.} =
    let widget = cast[Table](data)
    if widget.onRowClicked != nil: widget.onRowClicked(widget, int row)

proc tableOnRowDoubleClickedCb(w: ptr rawui.Table; row: cint; data: pointer) {.cdecl.} =
    let widget = cast[Table](data)
    if widget.onRowDoubleClicked != nil: widget.onRowDoubleClicked(widget, int row)

proc tableOnHeaderClickedCb(w: ptr rawui.Table; column: cint; data: pointer) {.cdecl.} =
    let widget = cast[Table](data)
    if widget.onHeaderClicked != nil: widget.onHeaderClicked(widget, int column)

genCallback tableOnSelectionChangedCb, Table, onSelectionChanged

proc newTable*(params: ptr TableParams): Table =
  newFinal result
  result.impl = rawui.newTable(params)

  tableHeaderOnClicked(result.impl, tableOnHeaderClickedCb, cast[pointer](result))
  tableOnRowClicked(result.impl, tableOnRowClickedCb, cast[pointer](result))
  tableOnRowDoubleClicked(result.impl, tableOnRowDoubleClickedCb, cast[pointer](result))
  tableOnSelectionChanged(result.impl, tableOnSelectionChangedCb, cast[pointer](result))

# -------------------- Generics ------------------------------------

proc show*[W: Widget](w: W) =
  ## Shows the widget.

  rawui.controlShow(w.impl)

proc hide*[W: Widget](w: W) =
  ## Hides the widget.

  rawui.controlHide(w.impl)

proc enabled*[W: Widget](w: W): bool =
  ## Returns whether or not the widget is enabled.
  ## Defaults to `true`

  rawui.controlEnabled(w.impl)

proc enable*[W: Widget](w: W) =
  ## Enables the widget.

  rawui.controlEnable(w.impl)

proc disable*[W: Widget](w: W) =
  ## Returns whether or not the widget is visible.

  rawui.controlDisable(w.impl)

proc destroy*[W: Widget](w: W) =
  ## Dispose and free all allocated resources.

  rawui.controlDestroy(w.impl)

#[
proc parent*[W: Widget](w: W): W =
  newFinal result
  result.impl = rawui.controlParent(w.impl)
]#

proc `parent=`*[W: Widget](w: W): W =
  ## Sets the widget's parent.
  ## 
  ## `w`: Widget instance.
  ## 
  ## `parent`: The parent Widget, `nil` to detach.

  var parent: Widget

  rawui.controlSetParent(w.impl, addr parent)
  return parent

proc topLevel*[W: Widget](w: W): bool =
  ## Returns whether or not the widget is a top level widget.

  bool rawui.controlToplevel(w.impl)

proc visible*[W: Widget](w: W): bool =
  ## Returns whether or not the widget is visible.
  

  bool rawui.controlVisible(w.impl)

proc verifySetParent*[W: Widget](w, parent: W): bool =
  ## Makes sure the widget's parent can be set to `parent`.
  ## 
  ## .. warning:: This will crash the application if `false`.
  ## 
  ## 
  ## `w`: Widget instance.
  ## 
  ## `parent`: Widget instance.

  bool rawui.controlVerifySetParent(w.impl, parent.impl)

proc enabledToUser*[W: Widget](w: W): bool =
  ## Returns whether or not the widget can be interacted with by the user.
  ## 
  ## Checks if the widget and all it's parents are enabled to make sure it can
  ## be interacted with by the user.

  bool rawui.controlEnabledToUser(w.impl)

proc free*[W: Widget](w: W) = 
  ## Frees the widget.

  freeControl(w.impl)

# -------------------- DateTimePicker ------------------------------

type
  DateTimePicker* = ref object of Widget
    onchanged*: proc(sender: DateTimePicker)

genImplProcs(DateTimePicker)

proc time*(d: DateTimePicker): DateTime =
  var tm: rawui.Tm
  dateTimePickerTime(d.impl, addr tm)

  result = dateTime(
    int tm.year + 1900,
    Month(tm.mon + 1),
    int tm.mday,
    int tm.hour,
    int tm.min,
    int tm.sec
  )

proc `time=`*(d: DateTimePicker, dateTime: DateTime) =
  var tm = rawui.Tm(
    sec: cint dateTime.second,
    min: cint dateTime.minute,
    hour: cint dateTime.hour,
    mday: cint dateTime.monthday,
    mon: cint ord(dateTime.month) - 1,
    year: cint dateTime.year - 1900,
    wday: cint ord(dateTime.weekday) - 1,
    yday: cint dateTime.yearday,
    isdst: cint dateTime.isDst
  )

  dateTimePickerSetTime(d.impl, addr tm)

genCallback dateTimePickerOnChangedCallback, DateTimePicker, onchanged

proc newDateTimePicker*(onchanged: proc(sender: DateTimePicker) = nil): DateTimePicker =
  newFinal result
  result.impl = rawui.newDateTimePicker()
  result.onchanged = onchanged
  dateTimePickerOnChanged(result.impl, dateTimePickerOnChangedCallback, cast[pointer](result))

proc newDatePicker*(onchanged: proc(sender: DateTimePicker) = nil): DateTimePicker =
  newFinal result
  result.impl = rawui.newDatePicker()
  result.onchanged = onchanged
  dateTimePickerOnChanged(result.impl, dateTimePickerOnChangedCallback, cast[pointer](result))

proc newTimePicker*(onchanged: proc(sender: DateTimePicker) = nil): DateTimePicker =
  newFinal result
  result.impl = rawui.newTimePicker()
  result.onchanged = onchanged
  dateTimePickerOnChanged(result.impl, dateTimePickerOnChangedCallback, cast[pointer](result))

export DateTime
