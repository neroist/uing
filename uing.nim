## High level wrapper for libui-ng. 
## 
## Documentation mainly from `ui.h <https://github.com/libui-ng/libui-ng/blob/master/ui.h>`_
##
## :Author: Jasmine

import std/times
import std/colors

import uing/rawui except Color

type
  Widget* = ref object of RootRef ## abstract Widget base class.
    internalImpl*: pointer

func impl*(w: Widget): ptr[Control] = cast[ptr Control](w.internalImpl)
  ## Default internal implementation of Widgets

proc init*() =
  ## Initialize the application
  
  var 
    o: rawui.InitOptions
    err = rawui.init(addr o)

  if err != nil:
    let msg = $err

    freeInitError(err)
    raise newException(ValueError, msg)

proc quit* = 
  ## Quit the application
  
  rawui.quit()

proc mainLoop*() =
  rawui.main()
  rawui.uninit()

proc pollingMainLoop*(poll: proc(timeout: int); timeout: int) =
  ## Can be used to merge an async event loop with libui-ng's event loop.
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

  new result#, finalize

template genCallback(name, typ, on) {. dirty .} =
  proc name(w: ptr rawui.typ; data: pointer) {.cdecl.} =
    let widget = cast[typ](data)
    if widget.on != nil: widget.on(widget)
  
template genImplProcs(t: untyped) {.dirty.}=
  type `Raw t` = ptr[rawui.t]

  func impl*(b: t): `Raw t` = cast[`Raw t`](b.internalImpl)
    ## Gets internal implementation of `b`
    
  func `impl=`*(b: t, r: `Raw t`) = b.internalImpl = pointer(r)
    ## Sets internal implementation of `b`


# -------------------- Non-Widgets --------------------------------------

# -------- funcs --------

export ForEach

type
  TimerProc = ref object
    fn: proc(): bool

proc queueMain*(f: proc (data: pointer) {.cdecl.}; data: pointer) = rawui.queueMain(f, data)

proc mainSteps*() = rawui.mainSteps()

proc mainStep*(wait: int): bool {.discardable.} = 
  bool rawui.mainStep(cint wait)

proc wrapTimerProc(data: pointer): cint {.cdecl.} =
  let f = cast[TimerProc](data)
  result = cint f.fn() 

  if result == 0: # a result of 0 means to stop the timer
    GC_unref f

proc timer*(milliseconds: int; fun: proc (): bool) = 
  ## Call `fun` after `milliseconds` milliseconds.
  ## This is repeated until `fun` returns `false`.
  ## 
  ## .. note:: This cannot be called from any thread, unlike 
  ##        `queueMain() <#queueMain,proc(pointer),pointer>`_
  ## 
  ## .. note:: The minimum exact timing, either accuracy (timer burst, etc.) 
  ##      or granularity (15ms on Windows, etc.), is OS-defined 
  
  let fn = TimerProc(fn: fun)
  GC_ref fn

  rawui.timer(cint milliseconds, wrapTimerProc, cast[pointer](fn))

proc free*(str: string) = rawui.freeText(str) 

# -------- Font Descriptor --------

export TextWeight, TextItalic, TextStretch, FontDescriptor

proc loadControlFont*(f: ptr FontDescriptor) = rawui.loadControlFont f
proc free*(f: ptr FontDescriptor) = rawui.freeFontDescriptor f

# -------- Area --------

# TODO add documentation for Area

type
  Area* = ref object of Widget
    handler: ptr AreaHandler
    scrolling*: bool

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
proc scrollTo*(a: Area, x, y, width, height: float) = areaScrollTo(a.impl, cdouble x, cdouble y, cdouble width, cdouble height)
proc handler*(a: Area): ptr AreaHandler = a.handler

proc newArea*(ah: ptr AreaHandler): Area =
  newFinal result
  result.handler = ah
  result.impl = rawui.newArea(ah)
  
proc newScrollingArea*(ah: ptr AreaHandler; width, height: int): Area =
  newFinal result
  result.handler = ah
  result.scrolling = true
  result.impl = rawui.newScrollingArea(ah, cint width, cint height)

# -------- Drawing --------

# TODO add documentation for all of this

type
  DrawPath* = ref object
    internalImpl: pointer
  
export 
  DrawMatrix,
  DrawFillMode, 
  DrawBrushType, 
  DrawLineCap, 
  DrawLineJoin,
  DrawStrokeParams,
  DrawDefaultMiterLimit

genImplProcs(DrawPath)

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

proc transform*(c: ptr DrawContext; m: ptr DrawMatrix) =
  drawTransform(c, m)

proc setIdentity*(m: ptr DrawMatrix) = drawMatrixSetIdentity(m)

proc translate*(m: ptr DrawMatrix; x, y: float) = drawMatrixTranslate(m, cdouble x, cdouble y)

proc scale*(m: ptr DrawMatrix; xCenter, yCenter, x, y: float) = 
  drawMatrixScale(m, cdouble xCenter, cdouble yCenter, cdouble x, cdouble y)

proc rotate*(m: ptr DrawMatrix; x, y, amount: float) =
  drawMatrixRotate(m, cdouble x, cdouble y, cdouble amount)

proc skew*(m: ptr DrawMatrix; x, y, xamount, yamount: float) =
  drawMatrixSkew(m, cdouble x, cdouble y, cdouble xamount, cdouble yamount)

proc multiply*(dest, src: ptr DrawMatrix) = drawMatrixMultiply(dest, src)

proc invertible*(m: ptr DrawMatrix): bool = bool drawMatrixInvertible(m)

proc invert*(m: ptr DrawMatrix): int = int drawMatrixInvert(m)

proc transformPoint*(m: ptr DrawMatrix): tuple[x, y: float] =
  var x, y: cdouble

  drawMatrixTransformPoint(m, addr x, addr y)
  result = (x: float x, y: float y)

proc transformSize*(m: ptr DrawMatrix): tuple[x, y: float] =
  var x, y: cdouble

  drawMatrixTransformSize(m, addr x, addr y)
  result = (x: float x, y: float y)

# -------- Attributes --------

type
  Attribute* = ref object
    ## `Attribute` stores information about an attribute in a
    ## `AttributedString`.
    ##
    ## You do not create `Attribute`s directly; instead, you create a
    ## `Attribute` of a given type using the specialized constructor
    ## functions. For every Unicode codepoint in the `AttributedString`,
    ## at most one value of each attribute type can be applied.
    ##
    ## `Attributes` are immutable.
    
    internalImpl: pointer

  AttributedString* = ref object
    ## `AttributedString` represents a string of UTF-8 text that can
    ## optionally be embellished with formatting attributes. libui-ng
    ## provides the list of formatting attributes, which cover common
    ## formatting traits like boldface and color as well as advanced
    ## typographical features provided by OpenType like superscripts
    ## and small caps. These attributes can be combined in a variety of
    ## ways.
    ##
    ## Attributes are applied to runs of Unicode codepoints in the string.
    ## Zero-length runs are elided. Consecutive runs that have the same
    ## attribute type and value are merged. Each attribute is independent
    ## of each other attribute; overlapping attributes of different types
    ## do not split each other apart, but different values of the same
    ## attribute type do.
    ##
    ## The empty string can also be represented by `AttributedString`,
    ## but because of the no-zero-length-attribute rule, it will not have
    ## attributes.
    ##
    ## A `AttributedString` takes ownership of all attributes given to
    ## it, as it may need to duplicate or delete Attribute objects at
    ## any time. By extension, when you free a `AttributedString`,
    ## all Attributes within will also be freed. Each method will
    ## describe its own rules in more details.
    ##
    ## In addition, `AttributedString` provides facilities for moving
    ## between grapheme clusters, which represent a character
    ## from the point of view of the end user. The cursor of a text editor
    ## is always placed on a grapheme boundary, so you can use these
    ## features to move the cursor left or right by one "character".
    ##
    ## `AttributedString` does not provide enough information to be able
    ## to draw itself onto a `DrawContext` or respond to user actions.
    ## In order to do that, you'll need to use a `DrawTextLayout <#DrawTextLayout>`_, 
    ## which is built from the combination of a `AttributedString` and a set 
    ## of layout-specific properties.

    internalImpl: pointer

export AttributeType

genImplProcs(Attribute)
genImplProcs(AttributedString)

proc newAttributedString*(initialString: string): AttributedString =
  ## Creates a new AttributedString from `initialString`. 
  ## The returned string will be entirely unattributed.
  
  newFinal result
  result.impl = rawui.newAttributedString(cstring initialString)

proc free*(a: AttributedString) = 
  ## Destroys the AttributedString `a`.
  ## It will also free all Attributes within.

  freeAttributedString(a.impl)

proc `$`*(s: AttributedString): string =
  ## Returns the textual content of `s` as a string.
  
  result = $attributedStringString(s.impl) 
  free result

proc len*(s: AttributedString): int =
  ## Returns the number of UTF-8 bytes in the textual content of `s`
  
  int attributedStringLen(s.impl) 

proc addUnattributed*(s: AttributedString; str: string) =
  ## Adds string `str` to the end of `s`. 
  ## The new substring will be unattributed.
  
  attributedStringAppendUnattributed(s.impl, cstring str)

proc insertAtUnattributed*(s: AttributedString; str: string; at: int) =
  ## Adds the string `str` to `s` at the byte position specified by `at`. 
  ## The new substring will be unattributed; existing attributes will be 
  ## moved along with their text.
  
  attributedStringInsertAtUnattributed(s.impl, cstring str, csize_t at)

proc delete*(s: AttributedString; start, `end`: int) =
  ## deletes the characters and attributes of `s` in the byte range 
  ## [`start`, `end`).

  attributedStringDelete(s.impl, csize_t start, csize_t `end`)

proc setAttribute*(s: AttributedString; a: Attribute; start, `end`: int) =
  ## Sets `a` in the byte range [`start`, `end`) of `s`. Any existing 
  ## attributes in that byte range of the same type are removed. You 
  ## should not use `a` after this function returns.

  attributedStringSetAttribute(s.impl, a.impl, csize_t start, csize_t `end`)

proc addWithAttributes*(s: AttributedString; str: string; attrs: varargs[Attribute]) =
  ## Adds string `str` to the end of `s`. The new substring will have
  ## the attributes `attrs` applied to it.
  
  let
    start = s.len
    `end` = start + str.len

  s.addUnattributed str

  for attr in attrs:
    s.setAttribute attr, start, `end`

type
  AttributedStringForEachAttributeFunc = ref object
    fun: proc (s: AttributedString; a: Attribute, start, `end`: int): ForEach

proc wrapAttributedStringForEachAttributeFunc(s: ptr rawui.AttributedString;
      a: ptr rawui.Attribute; start: csize_t; `end`: csize_t; data: pointer): ForEach {.cdecl.} =

  let 
    f = cast[AttributedStringForEachAttributeFunc](data)
    attrstr = new AttributedString
    attr = new Attribute

  attrstr.impl = s
  attr.impl = a

  result = f.fun(attrstr, attr, int start, int `end`) 

  if result == ForEachStop: 
    GC_unref f

proc forEachAttribute*(str: AttributedString; fun: proc (s: AttributedString; a: Attribute, start, `end`: int): ForEach) =
  ## enumerates all the Attributes in `str`. Within `fun`, `str` 
  ## still owns the attribute; you can neither free it nor save 
  ## it for later use.
  ## 
  ## .. error:: You cannot modify `str` in `fun`.
  
  let forEachFunc = AttributedStringForEachAttributeFunc(fun: fun)
  GC_ref forEachFunc
   
  attributedStringForEachAttribute(str.impl, wrapAttributedStringForEachAttributeFunc, cast[pointer](forEachFunc))

proc numGraphemes*(s: AttributedString): int =
  int attributedStringNumGraphemes(s.impl)

proc byteIndexToGrapheme*(s: AttributedString; pos: int): int =
  int attributedStringByteIndexToGrapheme(s.impl, csize_t pos)

proc graphemeToByteIndex*(s: AttributedString; pos: int): int = 
  int attributedStringGraphemeToByteIndex(s.impl, csize_t pos)

# attribute 

proc free*(a: Attribute) = 
  ## Frees a `Attribute`. You generally do not need to
  ## call this yourself, as `AttributedString` does this for you. 
  ## 
  ## .. error:: It is an error to call this function on a `Attribute` 
  ##         that has been given to a `AttributedString`. 
  ## 
  ## You can call this, however, if you created a `Attribute` that 
  ## you aren't going to use later.

  freeAttribute(a.impl)

proc getType*(a: Attribute): AttributeType = 
  ## Returns the AttributeType of `a`.

  attributeGetType(a.impl)

proc newFamilyAttribute*(family: string): Attribute = 
  ## Creates a new Attribute that changes the
  ## font family of the text it is applied to. 
  ## Font family names are case-insensitive.

  newFinal result
  result.impl = rawui.newFamilyAttribute(cstring family)

proc family*(a: Attribute): string =
  ## Returns the font family stored in `a`. 
  ## 
  ## .. error:: It is an error to call this on a
  ##        `Attribute` that does not hold a font family.

  result = $attributeFamily(a.impl)
  free result

proc newSizeAttribute*(size: float): Attribute =
  ## Creates a new `Attribute` that changes the
  ## size of the text it is applied to, in typographical points.

  newFinal result
  result.impl = rawui.newSizeAttribute(cdouble size)

proc size*(a: Attribute): float =
  ## Returns the font size stored in `a`. 
  ## 
  ## .. error:: It is an error to
  ##    call this on a `Attribute` that does not hold a font size.

  float rawui.attributeSize(a.impl) 


export TextWeight, TextItalic

proc newWeightAttribute*(weight: TextWeight): Attribute =
  ## Creates a new Attribute that changes the
  ## weight of the text it is applied to. 
  
  newFinal result
  result.impl = rawui.newWeightAttribute(weight)

proc weight*(a: Attribute): TextWeight =
  ## Returns the font weight stored in `a`. 
  ## 
  ## .. error:: It is an error
  ##         to call this on a Attribute that does not hold a font weight.

  attributeWeight(a.impl)

proc newItalicAttribute*(italic: TextItalic): Attribute =
  ## Creates a new Attribute that changes the
  ## italic mode of the text it is applied to. 

  newFinal result
  result.impl = rawui.newItalicAttribute(italic)

proc italic*(a: Attribute): TextItalic =
  ## Returns the font italic mode stored in `a`. 
  ## 
  ## .. error:: It is an error to call this on a Attribute 
  ##        that does not hold a font italic mode.

  attributeItalic(a.impl)


export TextStretch

proc newStretchAttribute*(stretch: TextStretch): Attribute =
  ## Creates a new Attribute that changes the
  ## stretch of the text it is applied to.

  newFinal result
  result.impl = rawui.newStretchAttribute(stretch)

proc stretch*(a: Attribute): TextStretch =
  ## Returns the font stretch stored in `a`. 
  ## 
  ## .. error:: It is an
  ##      error to call this on a Attribute that does not hold a font stretch.

  attributeStretch(a.impl)

proc newColorAttribute*(r, g, b, a: float = 1.0): Attribute =
  ## Creates a new Attribute that changes the
  ## color of the text it is applied to. 
  ## 
  ## .. error:: It is an error to specify an invalid color.

  newFinal result
  result.impl = rawui.newColorAttribute(r, g, b, a)

proc newColorAttribute*(color: Color, a: float = 1.0): Attribute =
  ## Creates a new Attribute that changes the
  ## color of the text it is applied to. 
  ## 
  ## .. error:: It is an error to specify an invalid color.
  
  let (r, g, b) = color.extractRGB()

  newFinal result
  result.impl = rawui.newColorAttribute(r/255, g/255, b/255, a)

proc color*(a: Attribute): tuple[r, g, b, alpha: float] =
  ## Returns the text color stored in `a`. 
  ## 
  ## .. error:: It is an error to call this on a Attribute 
  ##        that does not hold a text color.

  var r, g, b, alpha: cdouble

  attributeColor(a.impl, addr r, addr g, addr b, addr alpha)
  result = (r: float r, g: float g, b: float b, alpha: float alpha)

proc newBackgroundColorAttribute*(r, g, b, a: float = 1.0): Attribute =
  ## Creates a new Attribute that changes the background color 
  ## of the text it is applied to. 
  ## 
  ## .. error:: It is an error to specify an invalid color.

  newFinal result
  result.impl = rawui.newBackgroundAttribute(cdouble r, cdouble g, cdouble b, cdouble a)

proc newBackgroundColorAttribute*(color: Color, a: float = 1.0): Attribute =
  ## Creates a new Attribute that changes the background color 
  ## of the text it is applied to. 
  ## 
  ## .. error:: It is an error to specify an invalid color.
  
  let (r, g, b) = color.extractRGB()

  newFinal result
  result.impl = rawui.newBackgroundAttribute(cdouble r/255, cdouble g/255, cdouble b/255, cdouble a)

export Underline, UnderlineColor

proc newUnderlineAttribute*(u: Underline): Attribute =
  ## Creates a new Attribute that changes the type of 
  ## underline on the text it is applied to. 

  newFinal result
  result.impl = rawui.newUnderlineAttribute(u)

proc underline*(a: Attribute): Underline =
  ## Returns the underline type stored in `a`. 
  ## 
  ## .. error:: It is an error to call this 
  ##      on a Attribute that does not hold an 
  ##      underline style.

  attributeUnderline(a.impl)

proc newUnderlineColorAttribute*(u: UnderlineColor; r = 0.0, g = 0.0, b = 0.0, a: float = 0.0): Attribute =
  ## Creates a new Attribute that changes the color of the underline on 
  ## the text it is applied to.
  ##  
  ## .. error:: If the specified color type is `UnderlineColorCustom`, it is an
  ##          error to specify an invalid color value. Otherwise, the color values
  ##          are ignored and should be specified as zero.

  newFinal result
  result.impl = rawui.newUnderlineColorAttribute(u, cdouble r, cdouble g, cdouble b, cdouble a)

proc newUnderlineColorAttribute*(u: UnderlineColor; color: Color, a: float = 0.0): Attribute =
  ## Creates a new Attribute that changes the color of the underline on 
  ## the text it is applied to.
  ##  
  ## .. error:: If the specified color type is `UnderlineColorCustom`, it is an
  ##          error to specify an invalid color value. Otherwise, the color values
  ##          are ignored and should be specified as zero.
  
  let (r, g, b) = color.extractRGB()

  newFinal result
  result.impl = rawui.newUnderlineColorAttribute(u, cdouble r/255, cdouble g/255, cdouble b/255, cdouble a)

proc underlineColor*(a: Attribute): tuple[u: UnderlineColor, r, g, b, alpha: float] = 
  ## Returns the underline color stored in `a`. 
  ## 
  ## .. error:: It is an error to call this on a Attribute 
  ##          that does not hold an underline color.


  var r, g, b, alpha: cdouble
  var u: UnderlineColor

  attributeUnderlineColor(a.impl, addr u, addr r, addr g, addr b, addr alpha)
  result = (u: u, r: float r, g: float g, b: float b, alpha: float alpha)

# -------- Open Type Features --------

type
  OpenTypeFeatures* = ref object
    ## OpenTypeFeatures represents a set of OpenType feature
    ## tag-value pairs, for applying OpenType features to text.
    ## OpenType feature tags are four-character codes defined by
    ## OpenType that cover things from design features like small
    ## caps and swashes to language-specific glyph shapes and
    ## beyond. Each tag may only appear once in any given
    ## OpenTypeFeatures instance. Each value is a 32-bit integer,
    ## often used as a Boolean flag, but sometimes as an index to choose 
    ## a glyph shape to use.
    ## 
    ## If a font does not support a certain feature, that feature will be
    ## ignored. 
    ## 
    ## See the OpenType specification at
    ## https://www.microsoft.com/typography/otspec/featuretags.htm
    ## for the complete list of available features, information on specific
    ## features, and how to use them.
     
    internalImpl: pointer

genImplProcs(OpenTypeFeatures)

proc newOpenTypeFeatures*(): OpenTypeFeatures =
  ## Returns a new OpenTypeFeatures instance, with no tags yet added.
  
  newFinal result
  result.impl = rawui.newOpenTypeFeatures()

proc free*(otf: OpenTypeFeatures) = 
  ## Frees `otf`
  
  freeOpenTypeFeatures(otf.impl)

proc clone*(otf: OpenTypeFeatures): OpenTypeFeatures =
  ## Makes a copy of `otf` and returns it.
  ## Changing one will not affect the other.

  newFinal result
  result.impl = openTypeFeaturesClone(otf.impl)

proc add*(otf: OpenTypeFeatures; a, b, c, d: char, value: uint32) =
  ## Adds the given feature tag and value to otf. 
  ## The feature tag is specified by a, b, c, and d. If there is
  ## already a value associated with the specified tag in otf, the old
  ## value is removed.
  
  openTypeFeaturesAdd(otf.impl, a, b, c, d, value)

proc add*(otf: OpenTypeFeatures; abcd: string, value: uint32 | bool) =
  ## Alias of `add <#add,OpenTypeFeatures,char,char,char,char,uint32>`_.
  ## `a`, `b`, `c`, and `d` are instead a string of 4 characters, each
  ## character representing `a`, `b`, `c`, and `d` respectively.
  
  if abcd.len != 4:
    raise newException(ValueError, "String has an invalid length; it must have a length of 4.")

  openTypeFeaturesAdd(otf.impl, abcd[0], abcd[1], abcd[2], abcd[3], uint32 value)

proc remove*(otf: OpenTypeFeatures; a, b, c, d: char) =
  ## Removes the given feature tag and value from otf. 
  ## If the tag is not present in otf, this function does nothing.
  
  openTypeFeaturesRemove(otf.impl, a, b, c, d)

proc remove*(otf: OpenTypeFeatures; abcd: string) =
  ## Alias of `remove <#remove,OpenTypeFeatures,char,char,char,char>`_.
  ## `a`, `b`, `c`, and `d` are instead a string of 4 characters, each
  ## character representing `a`, `b`, `c`, and `d` respectively.
  
  if abcd.len != 4:
    raise newException(ValueError, "String has an invalid length; it must have a length of 4.")
  
  openTypeFeaturesRemove(otf.impl, abcd[0], abcd[1], abcd[2], abcd[3])

proc get*(otf: OpenTypeFeatures; a, b, c, d: char, value: var int): bool =
  ## Determines whether the given feature tag is present in `otf`. 
  ## If it is, `value` is set to the tag's value and
  ## nonzero is returned. Otherwise, zero is returned.
  ## 
  ## Note that if this function returns zero, `value` isn't
  ## changed. This is important: if a feature is not present in a
  ## `OpenTypeFeatures`, the feature is **NOT** treated as if its
  ## value was zero anyway. Script-specific font shaping rules and
  ## font-specific feature settings may use a different default value
  ## for a feature. You should likewise not treat a missing feature as
  ## having a value of zero either. Instead, a missing feature should
  ## be treated as having some unspecified default value.
  var val = uint32 value
  
  result = bool openTypeFeaturesGet(otf.impl, a, b, c, d, addr val)
  value = int val

proc get*(otf: OpenTypeFeatures; abcd: string, value: var int): bool =
  ## Alias of `get <#get,OpenTypeFeatures,char,char,char,char,uint32>`_.
  ## `a`, `b`, `c`, and `d` are instead a string of 4 characters, each
  ## character representing `a`, `b`, `c`, and `d` respectively.
  
  if abcd.len != 4:
    raise newException(ValueError, "String has an invalid length; it must have a length of 4.")

  otf.get(abcd[0], abcd[1], abcd[2], abcd[3], value)

type
  OpenTypeFeaturesForEachFunc = ref object
    fun: proc (otf: OpenTypeFeatures; abcd: string; value: int): ForEach

proc wrapOpenTypeFeaturesForEachFunc(otf: ptr rawui.OpenTypeFeatures; a, b, c, d: char; value: uint32; 
                                     data: pointer): ForEach {.cdecl.} =

  let 
    f = cast[OpenTypeFeaturesForEachFunc](data)
    openType = new OpenTypeFeatures

  openType.impl = otf

  result = f.fun(openType, a & b & c & d, int value) 

  if result == ForEachStop: 
    GC_unref f

proc forEach*(otf: OpenTypeFeatures; f: proc (otf: OpenTypeFeatures; abcd: string; value: int): ForEach) =
  ## Executes `f` for every tag-value pair in `otf`. 
  ## The enumeration order is unspecified. 
  ## 
  ## .. error:: You cannot modify `otf` while this function 
  ##        is running.
  
  let forEachFunc = OpenTypeFeaturesForEachFunc(fun: f)
  GC_ref forEachFunc

  openTypeFeaturesForEach(otf.impl, wrapOpenTypeFeaturesForEachFunc, cast[pointer](forEachFunc))

proc newFeaturesAttribute*(otf: OpenTypeFeatures): Attribute =
  ## Creates a and returns new Attribute that changes
  ## the font family of the text it is applied to. otf is copied; you may
  ## free it after this function returns.

  newFinal result
  result.impl = rawui.newFeaturesAttribute(otf.impl)

proc features*(a: Attribute): OpenTypeFeatures =
  ## Returns the OpenType features stored in `a`.
  ## It is an error to call this on a Attribute 
  ## that does not hold OpenType features.
  
  newFinal result
  result.impl = rawui.attributeFeatures(a.impl)

# -------- Draw Text --------

type
  DrawTextLayout* = ref object
    ## `DrawTextLayout` is a concrete representation of a
    ## `AttributedString` that can be displayed in a `DrawContext`.
    ## It includes information important for the drawing of a block of
    ## text, including the bounding box to wrap the text within, the
    ## alignment of lines of text within that box, areas to mark as
    ## being selected, and other things.
    ##
    ## Unlike `AttributedString`, the content of a `DrawTextLayout` is
    ## immutable once it has been created.
    ## 
    ## .. note:: There are OS-specific differences with text drawing 
    ##        that libui-ng can't account for
    
    internalImpl: pointer

export 
  DrawTextAlign, 
  DrawTextLayoutParams, 
  DrawContext, 
  DrawBrush, 
  DrawBrushType

genImplProcs(DrawTextLayout)

proc newDrawTextLayout*(params: ptr DrawTextLayoutParams): DrawTextLayout =
  ## Creates a new DrawTextLayout from the given parameters `params`.
  
  newFinal result
  result.impl = drawNewTextLayout(params)

proc free*(tl: DrawTextLayout) =
  ## Frees `tl`. The underlying `AttributedString` is not freed.
  
  drawFreeTextLayout(tl.impl)

proc drawText*(c: ptr DrawContext; tl: DrawTextLayout; point: tuple[x, y: float]) =
  ## Draws `tl` in `c` with the top-left point of `tl` at (`point.x`, `point.y`).
  
  rawui.drawText(c, tl.impl, cdouble point.x, cdouble point.y)

proc extents*(tl: DrawTextLayout): tuple[width, height: float] =
  ## Returns the width and height of `tl`. 
  ## The returned width may be smaller than the width passed 
  ## into `newDrawTextLayout() <#newDrawTextLayout,ptr.DrawTextLayoutParams>`_ 
  ## depending on how the text in `tl` is wrapped. Therefore, 
  ## you can use this function to get the actual size of the 
  ## text layout.
  
  var w, h: cdouble

  drawTextLayoutExtents(tl.impl, addr w, addr h)
  result = (width: float w, height: float h)


# ------------------- Widgets --------------------------------------

# ------------------- Button --------------------------------------

type
  Button* = ref object of Widget
    ## A widget that visually represents a button 
    ## to be clicked by the user to trigger an action.
    
    onclick*: proc (sender: Button) ## callback for when the button is clicked.

genCallback wrapOnClick, Button, onclick

genImplProcs(Button)

proc text*(b: Button): string =
  ## Returns the button label text.
  
  result = $buttonText(b.impl)
  free result

proc `text=`*(b: Button; text: string) =
  ## Sets the button label text.
  ## 
  ## | `b`: Button instance
  ## | `text`: Label text

  buttonSetText(b.impl, text)

proc newButton*(text: string; onclick: proc(sender: Button) = nil): Button =
  ## Creates and returns a new button.
  ## 
  ## | `text`: Button label text
  ## | `onclick`: callback for when the button is clicked.

  newFinal(result)
  result.impl = rawui.newButton(text)
  result.onclick = onclick
  result.impl.buttonOnClicked(wrapOnClick, cast[pointer](result))

# ------------------------ RadioButtons ----------------------------

type
  RadioButtons* = ref object of Widget
    ## A multiple choice widget of check buttons from which only one can be selected at a time.

    items*: seq[string] ## Seq of text of the radio buttons 
    onselected*: proc(sender: RadioButtons) ## Callback for when radio button is selected.

genImplProcs(RadioButtons)

proc add*(r: RadioButtons; items: varargs[string, `$`]) = 
  ## Appends a radio button.
  ## 
  ## | `r`: RadioButtons instance.
  ## | `items`: Radio button text(s).
  
  for text in items:
    radioButtonsAppend(r.impl, cstring text)
    r.items.add text

proc selected*(r: RadioButtons): int =
  ## Returns the index of the item selected.
  ## 
  ## `r`: RadioButtons instance.
  
  radioButtonsSelected(r.impl)

proc `selected=`*(r: RadioButtons, index: int) =
  ## Sets the item selected.
  ## 
  ## | `r`: RadioButtons instance.
  ## | `index`: Index of the item to be selected, `-1` to clear selection.
  
  radioButtonsSetSelected(r.impl, cint index)

genCallback(wrapOnRadioButtonClick, RadioButtons, onselected)

proc newRadioButtons*(items: openArray[string] = []; onselected: proc(sender: RadioButtons)  = nil): RadioButtons =
  ## Creates a new radio buttons instance.
  ## 
  ## `onselected`: Callback for when radio button is selected.

  newFinal(result)
  result.impl = rawui.newRadioButtons()
  result.onselected = onselected
  result.impl.radioButtonsOnSelected(wrapOnRadioButtonClick, cast[pointer](result))

  for item in items:
    result.add item

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
    ## .. warning:: A Window can **NOT** be a child of another Widget.

    onclosing*: proc (sender: Window): bool
    onfocuschanged*: proc (sender: Window)
    onContentSizeChanged*: proc (sender: Window)
    child: Widget
    
genImplProcs(Window)

proc title*(w: Window): string =
  ## Returns the window title.
  ## 
  ## `w`: Window instance.

  result = $windowTitle(w.impl)
  free result

proc `title=`*(w: Window; text: string) =
  ## Returns the window title.
  ## 
  ## .. note:: This method is merely a hint and may be ignored on unix platforms.
  ## 
  ## | `w`: Window instance.
  ## | `title`: Window title text.
  
  windowSetTitle(w.impl, text)

proc contentSize*(window: Window): tuple[width, height: int] = 
  ## Gets the window content size.
  ## 
  ## .. note:: The content size does NOT include window decorations like menus or title bars.
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
  ## | `window`: Window instance.
  ## | `size.width`: Window content width to set.
  ## | `size.height`:  Window content height to set.
  
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
  ## | `w`: Window instance.
  ## | `fullscreen`: `true` to make window full screen, `false` otherwise.
  
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
  ## | `w`: Window instance.
  ## | `borderless`: `true` to make window borderless, `false` otherwise.

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
  ## | `w`: Window instance.
  ## | `resizeable`: `true` to make window resizable, `false` otherwise.

  windowSetResizeable(w.impl, cint resizeable)

#proc destroy*(w: Window) =
#  ## this needs to be called if the callback passed to addQuitItem returns
#  ## true. Don't ask...
#
#  controlDestroy(w.impl)

proc margined*(w: Window): bool = 
  ## Returns whether or not the window has a margin.
  ## 
  ## `w`: Window instance.
  
  windowMargined(w.impl) != 0

proc `margined=`*(w: Window; margined: bool) = 
  ## Sets whether or not the window has a margin.
  ## The margin size is determined by the OS defaults.
  ## 
  ## | `w`: Window instance.
  ## | `margined`: `true` to set a window margin, `false` otherwise.

  windowSetMargined(w.impl, cint(margined))

proc child*(w: Window): Widget = 
  ## Returns the window's child.
  ## 
  ## | `w`: Window instance.
  
  w.child

proc `child=`*(w: Window; child: Widget) =
  ##  Sets the window's child.
  ## 
  ## | `w`: Window instance.
  ## | `child`: Widget to be made child.

  windowSetChild(w.impl, child.impl)
  w.child = child

proc openFile*(parent: Window): string =
  ## File chooser dialog window to select a single file. Returns
  ## the selected file path
  ## 
  ## .. note:: File paths are separated by the underlying OS 
  ##        file path separator.
  ## 
  ## `parent`: Parent window.
  
  let x = openFile(parent.impl)
  result = $x
  if x != nil: freeText(x)

proc openFolder*(parent: Window): string =
  ## Folder chooser dialog window to select a single file. Returns
  ## the selected folder path
  ## 
  ## .. note:: File paths are separated by the underlying OS 
  ##        file path separator.
  ## 
  ## `parent`: Parent window.

  let x = openFolder(parent.impl)
  result = $x
  if x != nil: freeText(x)

proc saveFile*(parent: Window): string =
  ## Save file dialog window. Returns the selected file path.
  ## 
  ## The user is asked to confirm overwriting existing files, should the chosen
  ## file path already exist on the system.
  ## 
  ## .. note:: File paths are separated by the underlying OS 
  ##        file path separator.
  ## 
  ## `parent`: Parent window.

  let x = saveFile(parent.impl)
  result = $x
  if x != nil: freeText(x)

proc msgBox*(parent: Window; title, desc: string) =
  ## Message box dialog window.
  ## 
  ## A message box displayed in a new window indicating a common message.
  ## 
  ## | `parent`: Parent window.
  ## | `title`: Dialog window title text.
  ## | `description`: Dialog message text.

  msgBox(parent.impl, title, desc)

proc msgBoxError*(parent: Window; title, desc: string) =
  ## Error message box dialog window.
  ## 
  ## A message box displayed in a new window indicating an error. On some systems
  ## this may invoke an accompanying sound.
  ## 
  ## | `parent`: Parent window.
  ## | `title`: Dialog window title text.
  ## | `description`: Dialog message text.
  
  msgBoxError(parent.impl, title, desc)

proc error*(parent: Window; title, desc: string) =
  ## Alias for `msgBoxError <#msgBoxError,Window,string,string>`_

  msgBoxError(parent, title, desc)

proc onClosingWrapper(rw: ptr rawui.Window; data: pointer): cint {.cdecl.} =
  let w = cast[Window](data)
  if w.onclosing != nil:
    if w.onclosing(w):
      controlDestroy(w.impl)
      rawui.quit()
      system.quit()

genCallback wrapOnFocusChangedWrapper, Window, onfocuschanged
genCallback wrapOnContentSizeChangedWrapper, Window, onContentSizeChanged

proc newWindow*(title: string; width, height: int; hasMenubar: bool = false, onfocuschanged: proc (sender: Window) = nil): Window =
  ## Creates and returns a new Window.
  ## 
  ## | `title`: Window title text.
  ## | `width`: Window width.
  ## | `height`: Window height.
  ## | `hasMenubar`: Whether or not the window should display a menu bar.
  ## | `onfocuschanged`: Callback for when the window focus changes.

  newFinal(result)
  result.impl = rawui.newWindow(title, cint width, cint height, cint hasMenubar)
  result.onfocuschanged = onfocuschanged
  result.onclosing = proc (_: Window): bool = return true
  windowOnFocusChanged(result.impl, wrapOnFocusChangedWrapper, cast[pointer](result))
  windowOnClosing(result.impl, onClosingWrapper, cast[pointer](result))
  windowOnContentSizeChanged(result.impl, wrapOnContentSizeChangedWrapper, cast[pointer](result))


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
  ## | `b`: Box instance.
  ## | `child`: widget instance to append.
  ## | `stretchy`: `true` to stretch widget,`false` otherwise. Default is `false`.

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
  ## | `b`: Box instance.
  ## | `index`: Index of widget to be removed.
  
  boxDelete(b.impl, index.cint)
  b.children.delete index

proc padded*(b: Box): bool = 
  ## Returns whether or not widgets within the box are padded.
  ## 
  ## Padding is defined as space between individual widgets.
  ## 
  ## `b`: Box instance.

  bool boxPadded(b.impl)

proc `padded=`*(b: Box; padded: bool) = 
  ## Sets whether or not widgets within the box are padded.
  ## 
  ## Padding is defined as space between individual widgets.
  ## The padding size is determined by the OS defaults.
  ## 
  ## | `b`: Box instance.
  ## | `padded` : `true` to make widgets padded, `false` otherwise.

  boxSetPadded(b.impl, padded.cint)

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

  result = $checkboxText(c.impl)
  free result

proc `text=`*(c: Checkbox; text: string) = 
  ## Sets the checkbox label text.
  ## 
  ## | `c`: Checkbox instance.
  ## | `text`: Label text.
  
  checkboxSetText(c.impl, text)

genCallback(wrapOntoggled, Checkbox, ontoggled)

proc checked*(c: Checkbox): bool = 
  ## Returns whether or the checkbox is checked.
  ## 
  ## `c`: Checkbox instance.
  
  checkboxChecked(c.impl) != 0

proc `checked=`*(c: Checkbox; checked: bool) =
  ## Sets whether or not the checkbox is checked.
  ## 
  ## | `c`: Checkbox instance.
  ## | `checked`: `true` to check box, `false` otherwise.
  
  checkboxSetChecked(c.impl, cint(checked))

proc newCheckbox*(text: string; ontoggled: proc(sender: Checkbox) = nil): Checkbox =
  ## Creates and returns a new checkbox.
  ## 
  ## | `text`: Checkbox label text
  ## | `ontoggled`: Callback for when the checkbox is toggled by the user.

  newFinal(result)
  result.impl = rawui.newCheckbox(text)
  result.ontoggled = ontoggled
  checkboxOnToggled(result.impl, wrapOntoggled, cast[pointer](result))

# ------------------ Entry ---------------------------------------

type
  Entry* = ref object of Widget
    ## A widget with a single line text entry field.

    onchanged*: proc (sender: Entry) ## Callback for when the user changes the entry's text.

genImplProcs(Entry)

proc text*(e: Entry): string = 
  ## Returns the entry's text.
  ## 
  ## `e`: Entry instance.
  
  result = $entryText(e.impl)
  free result

proc `text=`*(e: Entry; text: string) = 
  ## Sets the entry's text.
  ## 
  ## | `e`: Entry instance.
  ## | `text`: Entry text
  
  entrySetText(e.impl, cstring text)

proc clear*(e: Entry) = 
  ## Clears the entry's text
  ## 
  ## `e`: Entry instance.

  entrySetText(e.impl, cstring "")

proc readOnly*(e: Entry): bool = 
  ## Returns whether or not the entry's text can be changed.
  ## 
  ## `e`: Entry instance.
  
  entryReadOnly(e.impl) != 0

proc `readOnly=`*(e: Entry; readOnly: bool) =
  ## Sets whether or not the entry's text is read only.
  ## 
  ## | `e`: Entry instance.
  ## | `readonly`: `true` to make read only, `false` otherwise.
  
  entrySetReadOnly(e.impl, cint readOnly)

genCallback(wrapOnchanged, Entry, onchanged)

proc newEntry*(text: string = ""; onchanged: proc(sender: Entry) = nil): Entry =
  ## Creates a new entry.
  ## 
  ## | `text`: Entry text
  ## | `onchanged`: Callback for when the user changes the entry's text.
  
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
  ## | `text`: Entry text
  ## | `onchanged`: Callback for when the user changes the entry's text.
  
  newFinal(result)
  result.impl = rawui.newPasswordEntry()
  result.impl.entryOnChanged(wrapOnchanged, cast[pointer](result))
  result.onchanged = onchanged
  entrySetText(result.impl, text)

proc newSearchEntry*(text: string = ""; onchanged: proc(sender: Entry) = nil): Entry =
  ## Creates a new entry suitable for search.
  ## 
  ## Some systems will deliberately delay the `onchanged()` callback for
  ## a more natural feel.
  ## 
  ## | `text`: Entry text
  ## | `onchanged`: Callback for when the user changes the entry's text.

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
  
  result = $labelText(l.impl)
  free result

proc `text=`*(l: Label; text: string) = 
  ## Sets the label text.
  ## 
  ## | `l`: Lable Instance
  ## | `text`: Label text.

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
    ## A multi page widget interface that displays one page at a time.
    ## 
    ## Each page/tab has an associated label that can be selected to switch
    ## between pages/tabs.
    
    tabs*: seq[tuple[name: string, widget: Widget]] 
    
genImplProcs(Tab)

proc add*(t: Tab; name: string; w: Widget) =
  ## Appends a widget in form of a page/tab with label.
  ## 
  ## | `t`: Tab instance.
  ## | `name`: Label text.
  ## | `w`: Widget to append.
 
  tabAppend t.impl, name, w.impl
  t.tabs.add (name, w)

proc insertAt*(t: Tab; name: string; index: int; w: Widget) =
  ## Inserts a widget in form of a page/tab with label at `index`.
  ## 
  ## | `t`: Tab instance.
  ## | `name`: Label text.
  ## | `index`: Index at which to insert the widget.
  ## | `w`: Widget to append.

  tabInsertAt(t.impl, name, index.cint, w.impl)
  t.tabs.insert (name, w), index

proc delete*(t: Tab; index: int) =
  ## Removes the widget at index.
  ## 
  ## .. note:: The widget is neither destroyed nor freed.
  ## 
  ## | `t`: Tab instance.
  ## | `index`: Index at which to insert the widget.

  tabDelete(t.impl, index.cint)
  t.tabs.delete index 

proc margined*(t: Tab; index: int): bool = 
  ## Returns whether or not the page/tab at `index` has a margin.
  ## 
  ## | `t`: Tab instance.
  ## | `index`: Index to check if it has a margin.

  bool tabMargined(t.impl, index.cint) 

proc setMargined*(t: Tab; index: int; margined: bool) = 
  ## Sets whether or not the page/tab at `index` has a margin.
  ## 
  ## The margin size is determined by the OS defaults.
  ## 
  ## | `t`: Tab instance.
  ## | `index`: Index of the tab/page to un/set margin for.
  ## | `margined`: `true` to set a margin for tab at `index`, `false` otherwise.

  tabSetMargined(t.impl, cint index, cint margined)

proc newTab*(): Tab =
  ## Creates a new tab container.
  
  newFinal result
  result.impl = rawui.newTab()
  result.tabs = @[]

# ------------- Group --------------------------------------------------

type
  Group* = ref object of Widget
    ## A widget container that adds a label to the contained child widget.
    ## 
    ## This widget is a great way of grouping related widgets in combination with
    ## `Box <#Box>`_.
    ## 
    ## A visual box will or will not be drawn around the child widget dependent
    ## on the underlying OS implementation.

    child: Widget 
    
genImplProcs(Group)

proc title*(g: Group): string = 
  ## Returns the group title.
  ## 
  ## `g`: Group instance.

  result = $groupTitle(g.impl)
  free result

proc `title=`*(g: Group; title: string) =
  ## Sets the group title.
  ## 
  ## | `g`: Group instance.
  ## | `title`: Group title text.

  groupSetTitle(g.impl, title)

proc child*(g: Group): Widget = 
  ## Returns the group's child widget.
  ## 
  ## `g`: Group instance.
  
  g.child 

proc `child=`*(g: Group; c: Widget) =
  ## Sets the group's child.
  ## 
  ## | `g`: Group instance.
  ## | `c`: Widget child instance, or `nil`.

  groupSetChild(g.impl, 
    if c != nil: c.impl
    else: nil
  )

  g.child = c

proc margined*(g: Group): bool = 
  ## Returns whether or not the group has a margin.
  ## 
  ## `g`: Group instance.

  groupMargined(g.impl) != 0

proc `margined=`*(g: Group; margined: bool) =
  ## Sets whether or not the group has a margin.
  ## 
  ## The margin size is determined by the OS defaults.
  ## 
  ## | `g`: Group instance.
  ## | `margined`: `true` to set a margin, `false` otherwise.

  groupSetMargined(g.impl, margined.cint)

proc newGroup*(title: string; margined: bool = false): Group =
  ## Creates a new group
  ## 
  ## | `title`: Group title text.
  ## | `margined`: Sets whether or not the group has a margin.
  
  newFinal result
  result.impl = rawui.newGroup(title)
  groupSetMargined(result.impl, margined.cint)

# ----------------------- Spinbox ---------------------------------------

type
  Spinbox* = ref object of Widget
    ## A widget to display and modify integer values via a text field or +/- buttons.
    ## 
    ## This is a convenient widget for having the user enter integer values.
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
  ## Returns the spinbox value.
  ## 
  ## `s`: Spinbox instance.
  
  spinboxValue(s.impl)

proc `value=`*(s: Spinbox; value: int) = 
  ## Returns the spinbox value.
  ## 
  ## .. note:: Setting a value out of range will clamp to the nearest value in range.
  ## 
  ## `s`: Spinbox instance.
  ## `value`: Value to set.

  spinboxSetValue(s.impl, value.cint)

genCallback wrapsbOnChanged, Spinbox, onchanged

proc newSpinbox*(range: Slice[SomeInteger]; onchanged: proc (sender: Spinbox) = nil): Spinbox =
  ## Creates a new spinbox.
  ## 
  ## The initial spinbox value equals the minimum value.
  ## 
  ## In the current implementation `min` and `max` are swapped if `min>max`.
  ## This may change in the future though.
  ## 
  ## `range`: Range of allowed values as `min..max`.
  ## `onchanged`: Callback for when the spinbox value is changed by the user.

  newFinal result
  result.impl = rawui.newSpinbox(cint range.a, cint range.b)
  result.onchanged = onchanged
  spinboxOnChanged result.impl, wrapsbOnChanged, cast[pointer](result)

# ---------------------- Slider ---------------------------------------

type
  Slider* = ref object of Widget
    ## A widget to display and modify integer values via a user draggable slider.
    ## 
    ## Values are guaranteed to be within the specified range.
    ## 
    ## Sliders by default display a tool tip showing the current value when being
    ## dragged.
    ## 
    ## Sliders are horizontal only.

    onchanged*  : proc(sender: Slider) ## Callback for when the slider value is changed by the user.
    onreleased* : proc(sender: Slider) ## Callback for when the slider is released from dragging.
    
genImplProcs(Slider)

proc value*(s: Slider): int = 
  ## Returns the slider value.
  ## 
  ## `s`: Slider instance.

  int sliderValue(s.impl)

proc `value=`*(s: Slider; value: int) = 
  ## Sets the slider value.
  ## 
  ## | `s`: Slider intance.
  ## | `value`: Value to set.

  sliderSetValue(s.impl, cint value)

proc hasToolTip*(s: Slider): bool = 
  ## Returns whether or not the slider has a tool tip.
  ## 
  ## `s`: Slider instance.

  bool sliderHasToolTip(s.impl)

proc `hasToolTip=`*(s: Slider, hasToolTip: bool) = 
  ## Sets whether or not the slider has a tool tip.
  ## 
  ## | `s`: Slider instance.
  ## | `hasToolTip`: `true` to display a tool tip, `false` to display no tool tip.

  sliderSetHasToolTip(s.impl, cint hasToolTip)


proc `range=`*(s: Slider; sliderRange: Slice[SomeInteger]) = 
  ## Sets the slider range.
  ## 
  ## | `s`: Slider instance.
  ## | `sliderRange`: Slider range, as `min .. max`


  sliderSetRange(s.impl, cint sliderRange.a, cint sliderRange.b)

genCallback wrapslOnChanged, Slider, onchanged
genCallback wrapslOnReleased, Slider, onreleased

proc newSlider*(range: Slice[SomeInteger]; onchanged: proc (sender: Slider) = nil): Slider =
  ## Creates a new slider.
  ##
  ## The initial slider value equals the minimum value.
  ##
  ## In the current implementation `min `and `max` are swapped if `min > max`.
  ## This may change in the future though. 
  ## 
  ## | `range`: Slider range, as `min .. max`
  ## | `onchanged`: Callback for when the slider value is changed by the user.

  newFinal result
  result.impl = rawui.newSlider(cint range.a, cint range.b)
  result.onchanged = onchanged
  sliderOnChanged result.impl, wrapslOnChanged, cast[pointer](result)
  sliderOnReleased result.impl, wrapslOnReleased, cast[pointer](result)

# ------------------- Progressbar ---------------------------------

type
  ProgressBar* = ref object of Widget
    ## A widget that visualizes the progress of a task via the fill level of a horizontal bar.
    ## 
    ## Indeterminate values are supported via an animated bar.

genImplProcs(ProgressBar)

proc value*(p: ProgressBar): int = 
  ## Returns the progress bar value.
  ## 
  ## `p`: ProgressBar instance.
  
  int progressBarValue(p.impl)

proc `value=`*(p: ProgressBar; n: -1..100) =
  ## Sets the progress bar value.
  ## 
  ## Valid values are `[0, 100]` for displaying a solid bar imitating a percent
  ## value.
  ## 
  ## Use a value of `-1` to render an animated bar to convey an indeterminate
  ## value.
  ## 
  ## | `p`: ProgressBar instance.
  ## | `n`: Value to set. Integer in the range of `[-1, 100]`.

  progressBarSetValue p.impl, n.cint

proc newProgressBar*(indeterminate: bool = false): ProgressBar =
  ## Creates a new progress bar.
  ## 
  ## `indeterminate`: Whether or not the progress bar will display an 
  ## indeterminate value.

  newFinal result
  result.impl = rawui.newProgressBar()
  
  if indeterminate: 
    result.value = -1

# ------------------------- Separator ----------------------------

type
  Separator* = ref object of Widget
    ## A widget to visually separate widget, horizontally or vertically.
  
genImplProcs(Separator)

proc newVerticalSeparator*(): Separator = 
  ## Creates a new vertical separator
  
  newFinal result
  result.impl = rawui.newVerticalSeparator()

proc newHorizontalSeparator*(): Separator =
  ## Creates a new horizontal separator
   
  newFinal result
  result.impl = rawui.newHorizontalSeparator()

# ------------------------ Combobox ------------------------------

type
  Combobox* = ref object of Widget
    ## A widget to select one item from a predefined list of items via a drop down menu.

    items*: seq[string] ## List of tiems in the combobox
    onselected*: proc (sender: Combobox) ## Callback for when a combo box item is selected.
    
genImplProcs(Combobox)

proc add*(c: Combobox; items: varargs[string, `$`]) = 
  ## Appends an item to the combo box.
  ## 
  ## | `c`: Combobox instance.
  ## | `items`: Item text(s).

  for text in items:
    comboboxAppend(c.impl, cstring text)
    c.items.add text

proc insertAt*(c: Combobox; index: int; text: string) = 
  ## Inserts an item at `index` to the combo box.
  ## 
  ## 
  ## | `c`: Combobox instance.
  ## | `index`: Index at which to insert the item.
  ## | `text`: Item text.

  comboboxInsertAt(c.impl, cint index, text)
  c.items.insert text, index

proc clear*(c: Combobox) = 
  ## Deletes all items from the combo box.
  ## 
  ## `c`: Combobox instance.

  comboboxClear(c.impl)
  c.items = @[]

proc delete*(c: Combobox, index: int) = 
  ## Deletes an item at `index` from the combo box.
  ## 
  ## .. note:: Deleting the index of the item currently selected will move the
  ##        selection to the next item in the combo box or `-1` if no such item exists.
  ## 
  ## | `c`: Combobox instance.
  ## | `index`: Index of the item to be deleted.

  comboboxDelete(c.impl, cint index)
  c.items.delete index

proc selected*(c: Combobox): int = 
  ## Returns the index of the item selected.
  ## 
  ## `c`: Combobox instance.

  comboboxSelected(c.impl)

proc `selected=`*(c: Combobox; index: int) = 
  ## Sets the item selected.
  ## 
  ## | `c`: Combobox instance.
  ## | `index`: Index of the item to be selected, `-1` to clear selection.

  comboboxSetSelected c.impl, cint index

genCallback wrapbbOnSelected, Combobox, onselected

proc newCombobox*(items: openArray[string] = [], onselected: proc(sender: Combobox) = nil): Combobox =
  ## Creates a new combo box.
  ## 
  ## | `items`: List of strings to add to the combobox
  ## | `onselected`: Callback for when a combo box item is selected.
  
  newFinal result
  result.impl = rawui.newCombobox()
  result.onselected = onselected
  comboboxOnSelected(result.impl, wrapbbOnSelected, cast[pointer](result))

  for item in items:
    result.add item

# ----------------------- EditableCombobox ----------------------

type
  EditableCombobox* = ref object of Widget
    ## A widget to select one item from a predefined list of items or enter ones own.
    ## 
    ## Predefined items can be selected from a drop down menu.
    ## 
    ## A customary item can be entered by the user via an editable text field.

    items*: seq[string] ## Predefined text items in the combo box
    onchanged*: proc (sender: EditableCombobox) ## Callback for when an editable combo box item is selected or user text changed.
    
genImplProcs(EditableCombobox)

proc add*(c: EditableCombobox; items: varargs[string, `$`]) = 
  ## Appends an item to the editable combo box.
  ## 
  ## | `c`: Combobox instance.
  ## | `items`: Item text(s). 

  for text in items:
    editableComboboxAppend(c.impl, cstring text)
    c.items.add text

proc text*(c: EditableCombobox): string =
  ## Returns the text of the editable combo box.
  ## 
  ## This text is either the text of one of the predefined list items or the
  ## text manually entered by the user.
  ## 
  ## `c`: Combobox instance.

  result = $editableComboboxText(c.impl)
  free result

proc `text=`*(c: EditableCombobox; text: string) =
  ## Sets the text of the editable combo box.
  ## 
  ## This text is either the text of one of the predefined list items or the
  ## text manually entered by the user.
  ## 
  ## | `c`: Combobox instance.
  ## | `text`: Text field text.

  editableComboboxSetText(c.impl, cstring text)

proc clear*(e: EditableCombobox) = 
  ## Clears the editable combobox's text
  ## 
  ## `e`: Combobox instance.

  editableComboboxSetText(e.impl, cstring "")

genCallback wrapecbOnchanged, EditableCombobox, onchanged

proc newEditableCombobox*(items: openArray[string] = []; onchanged: proc (sender: EditableCombobox) = nil): EditableCombobox =
  ## Creates a new editable combo box.
  ## 
  ## `onchanged`: Callback for when an editable combo box item is selected or user text changed.

  newFinal result
  result.impl = rawui.newEditableCombobox()
  result.onchanged = onchanged
  editableComboboxOnChanged result.impl, wrapecbOnchanged, cast[pointer](result)

  for item in items:
    result.add item

# ------------------------ MultilineEntry ------------------------------

type
  MultilineEntry* = ref object of Widget
    ## A widget with a multi line text entry field.

    onchanged*: proc (sender: MultilineEntry) ## Callback for when the user changes the multi line entry's text.
    
genImplProcs(MultilineEntry)

proc text*(e: MultilineEntry): string = 
  ## Returns the multi line entry's text.
  ## 
  ## `e`: MultilineEntry instance
  
  result = $multilineEntryText(e.impl)
  free result

proc `text=`*(e: MultilineEntry; text: string) = 
  ## Sets the multi line entry's text.
  ## 
  ## | `e`: MultilineEntry instance
  ## | `text`: Single/multi line text
  
  multilineEntrySetText(e.impl, text)

proc clear*(e: MultilineEntry) = 
  ## Clears the multi line entry's text
  ## 
  ## `e`: MultilineEntry instance.

  multilineEntrySetText(e.impl, cstring "")

proc add*(e: MultilineEntry; text: string) = 
  ## Appends text to the multi line entry's text.
  ## 
  ## | `e`: MultilineEntry instance
  ## | `text`: Text to append.

  multilineEntryAppend(e.impl, text)

proc readOnly*(e: MultilineEntry): bool = 
  ## Returns whether or not the multi line entry's text can be changed.
  ## 
  ## | `e`: MultilineEntry instance

  multilineEntryReadOnly(e.impl) != 0

proc `readOnly=`*(e: MultilineEntry; readOnly: bool) = 
  ## Sets whether or not the multi line entry's text is read only.
  ## 
  ## | `e`: MultilineEntry instance
  ## | `readonly`: `true` to make read only, `false` otherwise.
  
  multilineEntrySetReadOnly(e.impl, cint(readOnly))

genCallback wrapmeOnchanged, MultilineEntry, onchanged

proc newMultilineEntry*(onchanged: proc(sender: MultilineEntry) = nil): MultilineEntry =
  ## Creates a new multi line entry that visually wraps text when lines overflow.
  
  newFinal result
  result.impl = rawui.newMultilineEntry()
  multilineEntryOnChanged(result.impl, wrapmeOnchanged, cast[pointer](result))

proc newNonWrappingMultilineEntry*(onchanged: proc(sender: MultilineEntry) = nil): MultilineEntry =
  ## Creates a new multi line entry that scrolls horizontally when lines overflow.
  ## 
  ## .. note:: Windows does not allow for this style to be changed after creation,
  ##        hence the two constructors.

  newFinal result
  result.impl = rawui.newNonWrappingMultilineEntry()
  multilineEntryOnChanged(result.impl, wrapmeOnchanged, cast[pointer](result))

# ---------------------- MenuItem ---------------------------------------

type
  MenuItem* = ref object of Widget
    ## A menu item used in conjunction with `Menu <#Menu>`_.
    
    onclicked*: proc (sender: MenuItem, window: Window) ## Callback for when the menu item is clicked.
    
genImplProcs(MenuItem)

proc enable*(m: MenuItem) = 
  ## Enables the menu item.
  ## 
  ## `m`: MenuItem instance.

  menuItemEnable(m.impl)

proc disable*(m: MenuItem) = 
  ## Disables the menu item.
  ## 
  ## Menu item is grayed out and user interaction is not possible.
  ## 
  ## `m`: MenuItem instance.
  
  menuItemDisable(m.impl)

proc wrapmeOnclicked(sender: ptr rawui.MenuItem;
                     window: ptr rawui.Window; data: pointer) {.cdecl.} =
  let m = cast[MenuItem](data)
  var win: Window
  newFinal win
  win.impl = window
  if m.onclicked != nil: m.onclicked(m, win)

proc checked*(m: MenuItem): bool = 
  ## Returns whether or not the menu item's checkbox is checked.
  ## 
  ## To be used only with items created via `addCheckItem() <#addCheckItem,Menu,string,proc(MenuItem)>`_.
  ## 
  ## `m`: MenuItem instance.

  menuItemChecked(m.impl) != 0

proc `checked=`*(m: MenuItem; checked: bool) = 
  ## Sets whether or not the menu item's checkbox is checked.
  ## 
  ## To be used only with items created via `addCheckItem() <#addCheckItem,Menu,string,proc(MenuItem)>`_.
  ## 
  ## `m`: MenuItem instance.
  ## `checked`: `true` to check menu item checkbox, `false` otherwise.
  
  menuItemSetChecked(m.impl, cint(checked))

# -------------------- Menu ---------------------------------------------

type
  Menu* = ref object of Widget
    ## An application level menu bar.
    ## 
    ## The various operating systems impose different requirements on the
    ## creation and placement of menu bar items, hence the abstraction of the
    ## items `Quit`, `Preferences` and `About`.
    ## 
    ## An exemplary, cross platform menu bar:
    ## 
    ## - File
    ##   * New
    ##   * Open
    ##   * Save
    ##   * Quit, use `addQuitItem() <#addQuitItem,Menu,proc)>`_
    ## - Edit
    ##   * Undo
    ##   * Redo
    ##   * Cut
    ##   * Copy
    ##   * Paste
    ##   * Select All
    ##   * Preferences, use `addPreferencesItem() <#addPreferencesItem,Menu,proc(MenuItem)>`_
    ## - Help
    ##   * About, use `addAboutItem() <#addAboutItem,Menu,proc(MenuItem)>`_

    children*: seq[MenuItem]
    
genImplProcs(Menu)

template addMenuItemImpl(ex) =
  newFinal result
  result.impl = ex
  menuItemOnClicked(result.impl, wrapmeOnclicked, cast[pointer](result))
  m.children.add result

proc addItem*(m: Menu; name: string, onclicked: proc(sender: MenuItem, window: Window) = nil): MenuItem {.discardable.} =
  ## Appends a generic menu item.
  ## 
  ## | `m`: Menu instance.
  ## | `name`: Menu item text.
  ## | `onclicked`: Callback for when the menu item is clicked.

  addMenuItemImpl(menuAppendItem(m.impl, name))
  result.onclicked = onclicked

proc addCheckItem*(m: Menu; name: string, onclicked: proc(sender: MenuItem, window: Window) = nil): MenuItem {.discardable.} =
  ## Appends a generic menu item with a checkbox.
  ## 
  ## | `m`: Menu instance.
  ## | `name`: Menu item text.
  ## | `onclicked`: Callback for when the menu item is clicked.
  
  addMenuItemImpl(menuAppendCheckItem(m.impl, name))
  result.onclicked = onclicked

  m.children.add result

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
  ## Appends a new `Quit` menu item.
  ## 
  ## .. warning:: Only one such menu item may exist per application.
  ## 
  ## .. error:: the window **MUST** be destroyed in `shouldQuit`
  ##        if the proc returns `true`
  ## 
  ## | `m`: Menu instance
  ## | `shouldQuit`: Proc that returns if the application should quit or not

  newFinal result
  result.impl = menuAppendQuitItem(m.impl)
  var cl = ShouldQuitClosure(fn: shouldQuit)
  GC_ref cl
  onShouldQuit(wrapOnShouldQuit, cast[pointer](cl))

proc addPreferencesItem*(m: Menu, onclicked: proc(sender: MenuItem, window: Window) = nil): MenuItem  =
  ## Appends a new `Preferences` menu item.
  ## 
  ## .. warning:: Only one such menu item may exist per application.
  ## 
  ## | `m`: Menu instance.
  ## | `onclicked`: Callback for when the menu item is clicked.

  addMenuItemImpl(menuAppendPreferencesItem(m.impl))
  result.onclicked = onclicked

proc addAboutItem*(m: Menu, onclicked: proc(sender: MenuItem, window: Window) = nil): MenuItem =
  ## Appends a new `About` menu item.
  ## 
  ## .. warning:: Only one such menu item may exist per application.
  ## 
  ## | `m`: Menu instance.
  ## | `onclicked`: Callback for when the menu item is clicked.
  
  addMenuItemImpl(menuAppendAboutItem(m.impl))
  result.onclicked = onclicked

{. pop .}

proc addSeparator*(m: Menu) =
  ## Appends a new separator.
  ## 
  ## `m`: Menu instance.

  menuAppendSeparator m.impl

proc newMenu*(name: string): Menu =
  ## Creates a new menu.
  ## 
  ## .. important:: To add a menu and its items to 
  ##            a window, they **must** be created 
  ##            before calling `newWindow()`
  ## 
  ## Typical values are `File`, `Edit`, `Help`, etc.
  ## 
  ## `name`: Menu label.

  newFinal result
  result.impl = rawui.newMenu(cstring name)
  result.children = @[]

# -------------------- Font Button --------------------------------------

type
  FontButton* = ref object of Widget
    ## A button-like widget that opens a font chooser when clicked.
    
    onchanged*: proc(sender: FontButton) ## Callback for when the font is changed.

genImplProcs(FontButton)

proc font*(f: FontButton): FontDescriptor =
  ## Returns the selected font.
  ## 
  ## `f`: FontButton instance

  var font: rawui.FontDescriptor
  fontButtonFont(f.impl, addr font)

  result = font

proc freeFont*(desc: ptr FontDescriptor) = 
  ##  Frees a `FontDescriptor` previously filled by `font() <#font,FontButton>`_.
  ##  
  ##  After calling this function the contents of `desc` should be assumed undefined,
  ##  however you can safely reuse `desc`.
  ##  
  ##  Calling this function on a `FontDescriptor` not previously filled by
  ##  `font() <#font,FontButton>`_ results in undefined behavior.
  ##  
  ##  `desc`: Font descriptor to free.

  freeFontButtonFont(desc)

genCallback fontButtonOnChanged, FontButton, onchanged

proc newFontButton*(onchanged: proc(sender: FontButton) = nil): FontButton =
  ## Creates and returns a new font button.
  ##
  ## The default font is determined by the OS defaults.
  ## 
  ## `onchanged`: Callback for when the font is changed.

  newFinal result
  result.impl = rawui.newFontButton()
  result.onchanged = onchanged
  fontButtonOnChanged(result.impl, fontButtonOnChanged, cast[pointer](result))


# -------------------- ColorButton --------------------------------------

type 
  ColorButton* = ref object of Widget
    ## A widget with a color indicator that opens a color chooser when clicked.
    ## 
    ## The widget visually represents a button with a color field representing
    ## the selected color.
    ## 
    ## Clicking on the button opens up a color chooser in form of a color palette.
    
    onchanged*: proc (sender: ColorButton) ## Callback for when the color is changed.

genImplProcs(ColorButton)

proc color*(c: ColorButton): tuple[r, g, b, a: float] = 
  ## Returns the color button color.
  ## 
  ## `c`: ColorButton instance
  
  var r, g, b, a: cdouble
  colorButtonColor(c.impl, addr r, addr g, addr b, addr a)

  result = (r: float r, g: float g, b: float b, a: float a)

proc setColor*(c: ColorButton; r, g, b, alpha: 0.0..1.0 = 1.0) = 
  ## Sets the color button color.
  ##   
  ## | `c`: ColorButton instance.
  ## | `r`: Red. Float in range of [0.0, 1.0].
  ## | `g`: Green. Float in range of [0.0, 1.0].
  ## | `b`: Blue. Float in range of [0.0, 1.0].
  ## | `alpha`: Alpha. Float in range of [0.0, 1.0].

  colorButtonSetColor(c.impl, r, b, g, alpha)

proc `color=`*(c: ColorButton; color: Color) = 
  ## Sets the color button color.
  ## 
  ## If you need to set color alpha use `setColor() <#setColor,ColorButton,int,int,int,float>`_
  ##   
  ## | `c`: ColorButton instance.
  ## | `color`: `Color <https://nim-lang.org/docs/colors.html>`_.
  
  let (r, g, b) = color.extractRGB()

  colorButtonSetColor(c.impl, cdouble (r / 255), cdouble (b / 255), cdouble (g / 255), cdouble 1)

genCallback wrapOnChanged, ColorButton, onchanged

proc newColorButton*(onchanged: proc (sender: ColorButton) = nil): ColorButton =
  ## Creates a new color button.
  ## 
  ## `onchanged`: Callback for when the color is changed.
  
  newFinal result
  result.impl = rawui.newColorButton()
  result.onchanged = onchanged
  colorButtonOnChanged(result.impl, wrapOnChanged, cast[pointer](result))

# -------------------- Form --------------------------------------

type
  Form* = ref object of Widget
    ## A container widget to organize contained widgets as labeled fields.
    ## 
    ## As the name suggests this container is perfect to create ascetically pleasing
    ## input forms.
    ## 
    ## Each widget is preceded by it's corresponding label.
    ## 
    ## Labels and containers are organized into two panes, making both labels
    ## and containers align with each other.

    chlidren*: seq[tuple[label: string, widget: Widget]]

genImplProcs(Form)

proc add*(f: Form, label: string, w: Widget, stretchy: bool = false) = 
  ## Appends a widget with a label to the form.
  ## 
  ## Stretchy items expand to use the remaining space within the container.
  ## In the case of multiple stretchy items the space is shared equally.
  ## 
  ## | `f`: Form instance.
  ## | `label`: Label text.
  ## | `w`: Widget to append.
  ## | `stretchy`: `true` to stretch widget, `false` otherwise.
  
  formAppend(f.impl, label, w.impl, cint stretchy)
  f.chlidren.add (label: label, widget: w)

proc delete*(f: Form, index: int) =
  ## Removes the widget at `index` from the form.
  ## 
  ## .. note:: The widget is neither destroyed nor freed. 
  ## 
  ## | `f`: Form instance.
  ## | `index`: Index of the widget to be removed.
  
  formDelete(f.impl, cint index)
  f.chlidren.delete index

proc padded*(f: Form): bool =
  ## Returns whether or not widgets within the form are padded.
  ## 
  ## Padding is defined as space between individual widgets.
  ## 
  ## `f`: Form instance.  

  bool formPadded(f.impl)

proc `padded=`*(f: Form, padded: bool) = 
  ## Sets whether or not widgets within the box are padded.
  ## 
  ## Padding is defined as space between individual widgets.
  ## The padding size is determined by the OS defaults.
  ## 
  ## `f`: Form instance.
  ## `padded`: `true` to make widgets padded, `false` otherwise.
  
  formSetPadded(f.impl, cint padded)

proc newForm*(padded: bool = false): Form = 
  ## Creates a new form.
  ## 
  ## `padded`: `true` to make widgets padded, `false` otherwise.
  
  newFinal result
  result.impl = rawui.newForm()
  result.padded = padded

# -------------------- Grid --------------------------------------

type
  Grid* = ref object of Widget
    ## A widget container to arrange containing widgets in a grid.
    ## 
    ## Contained widgets are arranged on an imaginary grid of rows and columns.
    ## Widgets can be placed anywhere on this grid, spanning multiple rows and/or
    ## columns.
    ## 
    ## Additionally placed widgets can be programmed to expand horizontally and/or
    ## vertically, sharing the remaining space among other expanded widgets.
    ## 
    ## Alignment options are available via `Align <uing/rawui.html#Align>`_ attributes to determine the
    ## widgets placement within the reserved area, should the area be bigger than
    ## the widget itself.
    ## 
    ## Widgets can also be placed in relation to other widget using `At <uing/rawui.html#At>`_
    ## attributes.
    
    children*: seq[Widget]

export Align, At

genImplProcs(Grid)

proc add*(g: Grid; w: Widget; left, top, xspan, yspan: int, hexpand: bool; halign: Align; vexpand: bool; valign: Align) =
  ## Appends a widget to the grid.
  ## 
  ## | `g`: Grid instance.
  ## | `w`: The widget to insert.
  ## | `left`: Placement as number of columns from the left. Integer in range of `[INT_MIN, INT_MAX]`.
  ## | `top`: Placement as number of rows from the top. Integer in range of `[INT_MIN, INT_MAX]`.
  ## | `xspan`: Number of columns to span. Integer in range of `[0, INT_MAX]`.
  ## | `yspan`: Number of rows to span. Integer in range of `[0, INT_MAX]`.
  ## | `hexpand`: `true` to expand reserved area horizontally, `false` otherwise.
  ## | `halign`: Horizontal alignment of the widget within the reserved space.
  ## | `vexpand`: `true` to expand reserved area vertically, `false` otherwise.
  ## | `valign`: Vertical alignment of the widget within the reserved space.
  
  gridAppend(g.impl, w.impl, cint left, cint top, cint xspan, cint yspan, cint hexpand, halign, cint vexpand, valign)
  g.children.add w

proc insertAt*(g: Grid; w, existing: Widget; at: At; left, top, xspan, yspan: int, hexpand: bool; halign: Align; vexpand: bool; valign: Align) = 
  ##  Inserts a widget positioned in relation to another widget within the grid.
  ##  
  ##  | `g`: Grid instance.
  ##  | `w`: The widget to insert.
  ##  | `existing`: The existing widget to position relatively to.
  ##  | `at`: Placement specifier in relation to `existing` widget.
  ##  | `xspan`: Number of columns to span. Integer in range of `[0, INT_MAX]`.
  ##  | `yspan`: Number of rows to span. Integer in range of `[0, INT_MAX]`.
  ##  | `hexpand`: `true` to expand reserved area horizontally, `false` otherwise.
  ##  | `halign`: Horizontal alignment of the widget within the reserved space.
  ##  | `vexpand`: `true` to expand reserved area vertically, `false` otherwise.
  ##  | `valign`: Vertical alignment of the widget within the reserved space. 

  gridInsertAt(g.impl, w.impl, existing.impl, at, cint xspan, cint yspan, cint hexpand, halign, cint vexpand, valign) 
  g.children.add w

proc padded*(g: Grid): bool = 
  ## Returns whether or not widgets within the grid are padded.
  ## 
  ## Padding is defined as space between individual widgets.
  ## 
  ## `g`: Grid instance.
  
  bool gridPadded(g.impl)

proc `padded=`*(g: Grid, padded: bool) = 
  ## Sets whether or not widgets within the grid are padded.
  ## 
  ## Padding is defined as space between individual widgets.
  ## The padding size is determined by the OS defaults.
  ## 
  ## | `g`: Grid instance.
  ## | `padded`: `true` to make widgets padded, `false` otherwise.

  gridSetPadded(g.impl, cint padded)

proc newGrid*(padded: bool = false): Grid = 
  ## Creates a new grid.
  ## 
  ## `padded`: `true` to make widgets padded, `false` otherwise.
  
  newFinal result
  result.impl = rawui.newGrid()
  result.padded = padded

# -------------------- Image --------------------------------------

type
  Image* = ref object of Widget
    ## A container for an image to be displayed on screen.
    ## 
    ## The container can hold multiple representations of the same image with the
    ## **same** aspect ratio but in different resolutions to support high-density
    ## displays.
    ## 
    ## Common image dimension scale factors are `1x` and `2x`. Providing higher
    ## density representations is entirely optional.
    ## 
    ## The system will automatically determine the correct image to render depending
    ## on the screen's pixel density.
    ## 
    ## Image only supports premultiplied 32-bit RGBA images.
    ## 
    ## No image file loading or image format conversion utilities are provided.

genImplProcs(Image)

proc add*(i: Image; pixels: pointer; pixelWidth: int; pixelHeight: int; byteStride: int) =
  ## Appends a new image representation.
  ## 
  ## | `i`: Image instance.
  ## | `pixels`: Pointer to byte array of premultiplied pixels in [R G B A] order.
  ## |        `pixels[0]` equals the **R** of the first pixel,
  ##          `[3]` the **A** of the first pixel.
  ## |        `pixels` must be at least `byteStride * pixelHeight` bytes long.
  ## | `pixelWidth`: Width in pixels.
  ## | `pixelHeight`: Height in pixels.
  ## | `byteStride`: Number of bytes per row of the pixel array.

  imageAppend(i.impl, pixels, cint pixelWidth, cint pixelHeight, cint byteStride)

proc free*(i: Image) = 
  ## Frees the image container and all associated resources.
  ## 
  ## `i`: Image instance.

  freeImage(i.impl)

proc newImage*(width, height: float): Image =
  ## Creates a new image container.
  ## 
  ## Dimensions are measured in points. This is most commonly the pixel size
  ## of the `1x` scaled image.
  ## 
  ## | `width`: Width in points.
  ## | `height`: Height in points.

  newFinal result
  result.impl = rawui.newImage(width.cdouble, height.cdouble)

# -------------------- Table --------------------------------------

export 
  TableSelectionMode, 
  TableModelHandler, 
  TableParams, 
  TableTextColumnOptionalParams, 
  TableColumnType, 
  TableValueType, 

  TableModelColumnNeverEditable, 
  TableModelColumnAlwaysEditable, 
  SortIndicator


type
  Table* = ref object of Widget
    ## A widget to display data in a tabular fashion.
    ## 
    ## The view of the architecture.
    ## 
    ## Data is retrieved from a `TableModel` via methods that you need to define
    ## in a `TableModelHandler`.
    ## 
    ## Make sure the `TableModel` columns return the right type, as specified in
    ## the `add*Column()` parameters.
    ## 
    ## The `*EditableModelColumn` parameters typically point to a `TableModel`
    ## column index, that specifies the property on a per row basis.
    ## | They can however also be passed two special values defining the property
    ## for all rows: `TableModelColumnNeverEditable` and
    ## `TableModelColumnAlwaysEditable`.

    onRowClicked*: proc (sender: Table; row: int) ## Callback for when the user single clicks a table row.
    onRowDoubleClicked*: proc (sender: Table; row: int) ## Callback for when the user double clicks a table row.
    onHeaderClicked*: proc (sender: Table; column: int) ## Callback for when a table column header is clicked.
    onSelectionChanged*: proc (sender: Table) ## Callback for when the table selection changed.

  TableValue* = ref object
    ## Container to store values used in container related methods.
    ## 
    ## `TableValue` objects are immutable.
    
    internalImpl: pointer

  TableModel* = ref object
    ## Table model delegate to retrieve data and inform about model changes.
    ## 
    ## This is a wrapper around `TableModelHandler` where the actual data is
    ## held.
    ## 
    ## The main purpose it to provide methods to the developer to signal that
    ## underlying data has changed.
    ## 
    ## Row indexes match both the row indexes in `Table` and `TableModelHandler`.
    ## 
    ## A `TableModel` can be used as the backing store for multiple `Table` views.
    ## 
    ## Once created, the number of columns and their data types are not allowed
    ## to change.
    ## 
    ## .. error:: Not informing the `TableModel` about out-of-band data changes is
    ##          an error. User edits via `Table` do *not* fall in this category.

    internalImpl: pointer

genImplProcs(Table)
genImplProcs(TableValue)
genImplProcs(TableModel)

proc free*(t: TableValue) = 
  ## Frees the TableValue.
  ## 
  ## .. warning:: This function is to be used only on `TableValue` objects that
  ##          have NOT been passed to `Table` or `TableModel` - as these
  ##          take ownership of the object.
  ## 
  ##          Use this for freeing erroneously created values or when directly
  ##          calling `TableModelHandler` without transferring ownership to
  ##          `Table` or `TableModel`.
  ## 
  ## `t`: TableValue to free.

  freeTableValue(t.impl)

proc free*(t: TableModel) = 
  ## Frees the table model.
  ## 
  ## .. error:: It is an error to free table models currently associated with a
  ##          `Table`.
  ## 
  ## `m`: Table model to free.

  freeTableModel(t.impl)

proc free*(t: ptr TableSelection) = 
  ## Frees the given TableSelection and all its resources.
  ## 
  ## `s`: TableSelection instance.

  freeTableSelection(t)

proc type*(v: TableValue): TableValueType = 
  ## Gets the TableValue type.
  ## 
  ## `v`: Table value.

  rawui.tableValueGetType(v.impl)

proc newTableValue*(str: string): TableValue = 
  ## Creates a new TableValue to store a text string.
  ## 
  ## `str`: String value.
 
  newFinal result
  result.impl = rawui.newTableValueString(cstring str)

proc `$`*(v: TableValue): string = 
  ## Returns the string value held internally.
  ## 
  ## To be used only on `TableValue` objects of type `TableValueTypeString`.
  ## 
  ## `v`: Table value.  
  
  if v.type != TableValueTypeString:
    raise newException(ValueError, "Invalid TableValue kind. Must be `TableValueTypeString`, not " & $v.type)

  $rawui.tableValueString(v.impl)

proc newTableValue*(img: Image): TableValue = 
  ## Creates a new table value to store an image.
  ## 
  ## .. warning:: Unlike other `TableValue` constructors, this function does
  ##          **NOT** copy the image to save time and space. Make sure the image
  ##          data stays valid while in use by the library.
  ##          As a general rule: if the constructor is called via the
  ##          `TableModelHandler`, the image is safe to free once execution
  ##          returns to **ANY** of your code.
  ## 
  ## `img`: Image.
  ##          | Data is NOT copied and needs to kept alive.

  newFinal result
  result.impl = rawui.newTableValueImage(img.impl)

proc image*(v: TableValue): Image =
  ## Returns the image contained.
  ## 
  ## To be used only on `TableValue` objects of kind `TableValueTypeImage`.
  ## 
  ## .. warning:: The image returned is not owned by the object `v`,
  ##          hence no lifetime guarantees can be made.
  ## 
  ## `v`: Table value.
  
  if v.type != TableValueTypeImage:
    raise newException(ValueError, "Invalid TableValue type. Must be `TableValueTypeImage`, not " & $v.type)

  newFinal result
  result.impl = rawui.tableValueImage(v.impl)

proc newTableValue*(i: int | bool): TableValue = 
  ## Creates a new table value to store an integer.
  ## 
  ## This value type can be used in conjunction with properties like
  ## column editable [`true`, `false`] or widget like progress bars and
  ## checkboxes. For these, consult ProgressBar and Checkbox for the allowed
  ## integer ranges.
  ## 
  ## `i`: Integer value.

  newFinal result
  result.impl = rawui.newTableValueInt(i.cint)

proc getInt*(v: TableValue): int = 
  ## Returns the integer value held internally.
  ## 
  ## To be used only on `TableValue` objects of type `TableValueTypeInt`.
  ## 
  ## `v`: Table value.
  
  if v.type != TableValueTypeInt:
    raise newException(ValueError, "Invalid TableValue type. Must be `TableValueTypeInt`, not " & $v.type)

  int rawui.tableValueInt(v.impl)

proc newTableValue*(r, g, b, a: 0.0..1.0 = 1.0): TableValue = 
  ## Creates a new table value to store a color in.
  ## 
  ## | `r`: Red. Float in range of [0, 1.0].
  ## | `g`: Green. Float in range of [0, 1.0].
  ## | `b`: Blue. Float in range of [0, 1.0].
  ## | `a`: Alpha. Float in range of [0, 1.0].

  newFinal result
  result.impl = rawui.newTableValueColor(cdouble r, cdouble g, cdouble b, cdouble a)

proc newTableValue*(color: Color; a: 0.0..1.0 = 1.0): TableValue = 
  ## Creates a new table value to store a color in.
  ## 
  ## | `color`: Table value color.
  ## | `a`: Alpha. Float in range of [0, 1.0].
  
  let (r, g, b) = color.extractRGB

  newFinal result
  result.impl = rawui.newTableValueColor(cdouble r/255, cdouble g/255, cdouble b/255, cdouble a)


proc color*(v: TableValue): tuple[r, g, b, a: float] = 
  ## Returns the color value held internally.
  ## 
  ## To be used only on `TableValue` objects of type `TableValueTypeColor`.
  ## 
  ## `v`: Table value.

  if v.type != TableValueTypeColor:
    raise newException(ValueError, "Invalid TableValue type. Must be `TableValueTypeColor`, not " & $v.type)

  var r, g, b, a: cdouble
  rawui.tableValueColor(v.impl, addr r, addr g, addr b, addr a)

  result.r = float r
  result.g = float g
  result.b = float b
  result.a = float a

proc newTableModel*(mh: ptr TableModelHandler): TableModel =
  ## Creates a new table model.
  ## 
  ## `mh`: Table model handler.
 
  newFinal result
  result.impl = rawui.newTableModel(mh)

proc rowInserted*(m: TableModel; newIndex: int) = 
  ## Informs all associated `Table` views that a new row has been added.
  ## 
  ## You must insert the row data in your model before calling this function.
  ## 
  ## `numRows() <uing/rawui.html#TableModelHandler>`_ must represent the 
  ## new row count before you call this function.
  ## 
  ## | `m`: Table model that has changed.
  ## | `newIndex`: Index of the row that has been added.

  rawui.tableModelRowInserted(m.impl, newIndex.cint)

proc rowChanged*(m: TableModel; index: int) = 
  ## Informs all associated `Table` views that a row has been changed.
  ## 
  ## You do NOT need to call this in your `setCellValue()<uing/rawui.html#TableModelHandler>`_ 
  ## handlers, but **NEED** to call this if your data changes at any other point.
  ## 
  ## | `m`: Table model that has changed.
  ## | `index`: Index of the row that has changed.

  rawui.tableModelRowChanged(m.impl, index.cint)

proc rowDeleted*(m: TableModel; oldIndex: int) = 
  ## Informs all associated `Table` views that a row has been deleted.
  ## 
  ## You must delete the row from your model before you call this function.
  ## 
  ## `numRows() <uing/rawui.html#TableModelHandler>`_ must represent the 
  ## new row count before you call this function.
  ## 
  ## | `m`: Table model that has changed.
  ## | `oldIndex`: Index of the row that has been deleted.

  rawui.tableModelRowDeleted(m.impl, oldIndex.cint)

proc addTextColumn*(t: Table, name: string, textModelColumn, textEditableModelColumn: int | bool, textParams: ptr TableTextColumnOptionalParams = nil) =
  ## Appends a text column to the table.
  ## 
  ## | `t`: Table instance.
  ## | `name`: Column title text.
  ## | `textModelColumn`: Column that holds the text to be displayed.
  ## | `textEditableModelColumn`: Column that defines whether or not the text is editable.
  ## |                         `TableModelColumnNeverEditable` to make all rows never editable.
  ## |                         `TableModelColumnAlwaysEditable` to make all rows always editable.
  ## | `textParams`: Text display settings, `nil` to use defaults.

  t.impl.tableAppendTextColumn(name, textModelColumn.cint, textEditableModelColumn.cint, textParams)

proc addImageColumn*(table: Table, title: string, index: int) =
  ## Appends an image column to the table.
  ## 
  ## Images are drawn at icon size, using the representation that best fits the
  ## pixel density of the screen.
  ## 
  ## | `table`: Table instance.
  ## | `title`: Column title text.
  ## | `index`: Column that holds the images to be displayed.

  table.impl.tableAppendImageColumn(title, index.cint)

proc addCheckboxTextColumn*(t: Table; name: string; checkboxModelColumn, checkboxEditableModelColumn, textModelColumn, textEditableModelColumn: int; textParams: ptr TableTextColumnOptionalParams = nil) =
  ## Appends a column to the table containing a checkbox and text.
  ## 
  ## | `t`: Table instance.
  ## | `name`: Column title text.
  ## | `checkboxModelColumn`: Column that holds the data to be displayed.
  ## |                     `true` for a checked checkbox, `false` otherwise.
  ## | `checkboxEditableModelColumn`: Column that defines whether or not the checkbox is editable.
  ## |                             `TableModelColumnNeverEditable` to make all rows never editable.
  ## |                             `TableModelColumnAlwaysEditable` to make all rows always editable.
  ## | `textModelColumn`: Column that holds the text to be displayed.
  ## | `textEditableModelColumn`: Column that defines whether or not the text is editable.
  ## |                         `TableModelColumnNeverEditable` to make all rows never editable.
  ## |                         `TableModelColumnAlwaysEditable` to make all rows always editable.
  ## | `textParams`: Text display settings, `nil` to use defaults.
  
  t.impl.tableAppendCheckboxTextColumn(
    name, 
    cint checkboxModelColumn, 
    cint checkboxEditableModelColumn, 
    cint textModelColumn, 
    cint textEditableModelColumn, 
    textParams
  )

proc addImageTextColumn*(t: Table, name: string, imageIndex, textIndex, editableMode: int, textParams: ptr TableTextColumnOptionalParams) =
  ## Appends a column to the table that displays both an image and text.
  ## 
  ## Images are drawn at icon size, using the representation that best fits the
  ## pixel density of the screen.
  ## 
  ## | `t`: Table instance.
  ## | `name`: Column title text.
  ## | `imageIndex`: Column that holds the images to be displayed.
  ## | `textIndex`: Column that holds the text to be displayed.
  ## | `editableMode`: Column that defines whether or not the text is editable.
  ## |               `TableModelColumnNeverEditable` to make all rows never editable.
  ## |               `TableModelColumnAlwaysEditable` to make all rows always editable.
  ## | `textParams`: Text display settings, `NULL` to use defaults.

  t.impl.tableAppendImageTextColumn(name, imageIndex.cint, textIndex.cint, editableMode.cint, textParams)

proc addCheckboxColumn*(table: Table, title: string, index, editableMode: int) =
  ## Appends a column to the table containing a checkbox.
  ## 
  ## | `t`: Table instance.
  ## | `title`: Column title text.
  ## | `index`: Column that holds the data to be displayed.
  ## | `editableMode`: Column that defines whether or not the checkbox is editable.
  ## |               `TableModelColumnNeverEditable` to make all rows never editable.
  ## |               `TableModelColumnAlwaysEditable` to make all rows always editable.

  table.impl.tableAppendCheckboxColumn(title, index.cint, editableMode.cint)

proc addProgressBarColumn*(table: Table, title: string, index: int) =
  ## Appends a column to the table containing a progress bar.
  ## 
  ## The workings and valid range are exactly the same as that of uiProgressBar.
  ## 
  ## | `table`: Table instance.
  ## | `title`: Column title text.
  ## | `index`: Column that holds the data to be displayed.
  ## |        Integer in range of `[-1, 100]`, see `ProgressBar <#ProgressBar>`_
  ## |        for details.

  table.impl.tableAppendProgressBarColumn(title, index.cint)

proc addButtonColumn*(table: Table, title: string, index, clickableMode: int) =
  ## Appends a column to the table containing a button.
  ##
  ## Button clicks are signaled to the `TableModelHandler` via a call to
  ## SetCellValue() with a value of `NULL` for the `buttonModelColumn`.
  ##
  ## CellValue() must return the button text to display.
  ##
  ## | `table`: Table instance.
  ## | `title`: Column title text.
  ## | `index`: Column that holds the button text to be displayed.
  ## | `clickableMode`: Column that defines whether or not the button is clickable.
  ## |                `TableModelColumnNeverEditable` to make all rows never clickable.
  ## |                `TableModelColumnAlwaysEditable` to make all rows always clickable.

  table.impl.tableAppendButtonColumn(title, index.cint, clickableMode.cint)

proc headerVisible*(t: Table): bool = 
  ## Returns whether or not the table header is visible.
  ## 
  ## `table`: Table instance.
  
  bool tableHeaderVisible(t.impl)

proc `headerVisible=`*(t: Table; visible: bool) = 
  ## Sets whether or not the table header is visible.
  ## 
  ## `table`: Table instance.
  ## `visible`: `true` to show header, `false` to hide header.

  tableHeaderSetVisible(t.impl, cint visible)

proc selectionMode*(table: Table): TableSelectionMode = 
  ## Returns the table selection mode. Defaults to TableSelectionModeZeroOrOne
  ## 
  ## `table`: Table instance.

  tableGetSelectionMode(table.impl)

proc `selectionMode=`*(table: Table, mode: TableSelectionMode) = 
  ## Sets the table selection mode.
  ## 
  ## .. warning:: All rows will be deselected if the existing selection is illegal
  ##          in the new selection mode.
  ## 
  ## | `table`: Table instance.
  ## | `mode`: Table selection mode to set.

  tableSetSelectionMode(table.impl, mode)

proc columnWidth*(table: Table, column: int): int = 
  ## Returns the table column width in pixels.
  ## 
  ## | `table`: Table instance.
  ## | `column`: Column index.
  
  int tableColumnWidth(table.impl, cint column)

proc setColumnWidth*(table: Table, column, width: int) = 
  ## Sets the table column width.
  ## 
  ## Setting the width to `-1` will restore automatic column sizing matching
  ## either the width of the content or column header (which ever one is bigger).
  ## 
  ## .. note:: Darwin currently only resizes to the column header width on `-1`.
  ## 
  ## | `table`: Table instance.
  ## | `column`: Column index.
  ## | `width`: Column width to set in pixels, `-1` to restore automatic column sizing.

  tableColumnSetWidth(table.impl, cint column, cint width)

proc sortIndicator*(table: Table, column: int): SortIndicator = 
  ## Returns the column's sort indicator displayed in the table header.
  ## 
  ## | `table`: Table instance.
  ## | `column`: Column index.

  tableHeaderSortIndicator(table.impl, cint column)

proc setSortIndicator*(table: Table, column: int, indicator: SortIndicator) = 
  ## Sets the column's sort indicator displayed in the table header.
  ## 
  ## Use this to display appropriate arrows in the table header to indicate a
  ## sort direction.
  ## 
  ## .. note:: Setting the indicator is purely visual and does not 
  ##        perform any sorting.
  ## 
  ## | `table`: Table instance.
  ## | `column`: Column index.
  ## | `indicator`: Sort indicator.

  tableHeaderSetSortIndicator(table.impl, cint column, indicator)

proc selection*(table: Table): seq[int] =
  ## Returns the current table selection.
  ## 
  ## .. note:: For empty selections an empty seq will be returned.
  ## 
  ## `table`: Table instance.

  let tSelection = tableGetSelection(table.impl)

  if tSelection.rows != nil:
    for row in tSelection.rows.toOpenArray(0, tSelection.numRows - 1):
      result.add int row

  free tSelection

proc setSelection(table: Table; sel: openArray[cint]) {.inline.} =
  var tSelection = TableSelection(
    numRows: cint sel.len,
    rows: cast[ptr UncheckedArray[cint]](sel)
  )

  tableSetSelection(table.impl, addr tSelection)

proc `selection=`*(table: Table; sel: openArray[int]) =
  ## Sets the current table selection, clearing any previous selection.
  ## 
  ## .. note:: Selecting more rows than the selection mode allows for 
  ##      results in nothing happening.
  ## 
  ## | `table`: Table instance.
  ## | `sel`: List of rows to select.
  
  var selection: seq[cint]
  
  for i in sel:
    selection.add cint i 

  table.setSelection(selection)

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
  ## Creates a new table.
  ## 
  ## `params`: Table parameters.
  
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
  ## Defaults to `true`.

  bool rawui.controlEnabled(w.impl)

proc enable*[W: Widget](w: W) =
  ## Enables the widget.

  rawui.controlEnable(w.impl)

proc disable*[W: Widget](w: W) =
  ## Disables the widget.

  rawui.controlDisable(w.impl)

proc destroy*[W: Widget](w: W) =
  ## Dispose and free all allocated resources.

  rawui.controlDestroy(w.impl)

# A Window can not be a child of another widget
proc parent*[W: Widget](w: W and not Window): W =
  ## Returns the parent of `w`
  ## 
  ## .. important:: Returns `nil` if `w` has no parent
  ## 
  ## `w`: Widget instance.
  
  let parent = rawui.controlParent(w.impl)

  if parent == nil:
    return nil
  
  newFinal result

  # same thing as `impl=`
  result.internalImpl = pointer parent

proc `parent=`*[W: Widget](w: W, parent: Widget) =
  ## Sets the widget's parent.
  ## 
  ## | `w`: Widget instance.
  ## | `parent`: The parent Widget, `nil` to detach.

  rawui.controlSetParent(
    w.impl, 
    if parent != nil: parent.impl
    else: nil
  )

proc handle*[W: Widget](w: W): int = 
  ## Returns the control's OS-level handle.
  ## 
  ## `w`: Widget instance.
  
  controlHandle(w.impl)

func signature*[W: Widget](w: W): int = 
  ## Get widget signature
  
  int w.impl.signature

func typeSignature*[W: Widget](w: W): int = 
  ## Get widget type signature
  
  int w.impl.typeSignature

func osSignature*[W: Widget](w: W): int = 
  ## Get widget OS signature
  
  int w.impl.osSignature

proc topLevel*[W: Widget](w: W): bool =
  ## Returns whether or not the widget is a top level widget.

  bool rawui.controlToplevel(w.impl)

proc visible*[W: Widget](w: W): bool =
  ## Returns whether or not the widget is visible.
  
  bool rawui.controlVisible(w.impl)

proc verifySetParent*[W: Widget](w: W, parent: Widget) =
  ## Makes sure the widget's parent can be set to `parent`.
  ## 
  ## .. warning:: This will crash the application if `false`.
  ## 
  ## | `w`: Widget instance.
  ## | `parent`: Widget instance.

  rawui.controlVerifySetParent(w.impl, parent.impl)

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
    ## A widget to enter a date and/or time.
    ## 
    ## All functions assume local time and do **NOT** perform any time zone conversions.

    onchanged*: proc(sender: DateTimePicker) ## Callback for when the date time picker value is changed by the user.

genImplProcs(DateTimePicker)

proc time*(d: DateTimePicker): DateTime =
  ## Returns date and time stored in the data time picker.
  ## 
  ## `d`: DateTimePicker instance
  
  var tm: Tm
  dateTimePickerTime(d.impl, addr tm)

  result = dateTime(
    int tm.tm_year + 1900,
    Month(tm.tm_mon + 1),
    int tm.tm_mday,
    int tm.tm_hour,
    int tm.tm_min,
    int tm.tm_sec
  )

proc `time=`*(d: DateTimePicker, dateTime: DateTime) =
  ## Sets date and time of the data time picker.
  ## 
  ## 
  ## | `d`: DateTimePicker instance.
  ## | `time`: Date and/or time as local time.

  var tm = rawui.Tm(
    tm_sec: cint dateTime.second,
    tm_min: cint dateTime.minute,
    tm_hour: cint dateTime.hour,
    tm_mday: cint dateTime.monthday,
    tm_mon: cint ord(dateTime.month) - 1,
    tm_year: cint dateTime.year - 1900,
    tm_wday: cint ord(dateTime.weekday) - 1,
    tm_yday: cint dateTime.yearday,
    tm_isdst: cint -1 # dateTime.isDst
  )

  dateTimePickerSetTime(d.impl, addr tm)

genCallback dateTimePickerOnChangedCallback, DateTimePicker, onchanged

proc newDateTimePicker*(onchanged: proc(sender: DateTimePicker) = nil): DateTimePicker =
  ## Creates a new date and time picker.
  ## 
  ## `onchanged`: Callback for when the date time picker value is changed by the user.

  newFinal result
  result.impl = rawui.newDateTimePicker()
  result.onchanged = onchanged
  dateTimePickerOnChanged(result.impl, dateTimePickerOnChangedCallback, cast[pointer](result))

proc newDatePicker*(onchanged: proc(sender: DateTimePicker) = nil): DateTimePicker =
  ## Creates a new date picker
  ## 
  ## `onchanged`: Callback for when the date time picker value is changed by the user.

  newFinal result
  result.impl = rawui.newDatePicker()
  result.onchanged = onchanged
  dateTimePickerOnChanged(result.impl, dateTimePickerOnChangedCallback, cast[pointer](result))

proc newTimePicker*(onchanged: proc(sender: DateTimePicker) = nil): DateTimePicker = 
  ## Creates a new time picker.
  ## 
  ## `onchanged`: Callback for when the date time picker value is changed by the user.

  newFinal result
  result.impl = rawui.newTimePicker()
  result.onchanged = onchanged
  dateTimePickerOnChanged(result.impl, dateTimePickerOnChangedCallback, cast[pointer](result))

export DateTime
