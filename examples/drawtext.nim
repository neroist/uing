import std/sugar

import uing
from uing/rawui import nil

# TODO i really dislike these global vars

var 
  #systemFont: Checkbox
  fontButton: FontButton
  alignment: Combobox
  attrstr: AttributedString

proc addWithAttribute(what: string; attr1, attr2: Attribute = nil) =
  let
    start = attrstr.len
    `end` = start + what.len

  attrstr.addUnattributed what
  attrstr.setAttribute attr1, start, `end`

  if attr2 != nil:
    attrstr.setAttribute attr2, start, `end`

proc makeAttributedString =
  attrstr = newAttributedString(
    "Drawing strings with libui-ng is done with the AttributedString and DrawTextLayout objects.\n" &
    "AttributedString lets you have a variety of attributes: "
  )

  let attr = newFamilyAttribute("Courier New")
  addWithAttribute("font family", attr)
  attrstr.addUnattributed(", ")

  let attr1 = newSizeAttribute(18)
  addWithAttribute("font size", attr1)
  attrstr.addUnattributed(", ")

  let attr2 = newWeightAttribute(TextWeightBold)
  addWithAttribute("font weight", attr2)
  attrstr.addUnattributed(", ")

  let attr3 = newItalicAttribute(TextItalicItalic)
  addWithAttribute("font italicness", attr3)
  attrstr.addUnattributed(", ")

  let attr4 = newStretchAttribute(TextStretchCondensed)
  addWithAttribute("font stretch", attr4)
  attrstr.addUnattributed(", ")

  let attr5 = newColorAttribute(0.75, 0.25, 0.5, 0.75)
  addWithAttribute("text color", attr5)
  attrstr.addUnattributed(", ")

  let attr6 = newBackgroundColorAttribute(0.5, 0.5, 0.25, 1.0)
  addWithAttribute("text background color", attr6)
  attrstr.addUnattributed(", ")

  let attr7 = newUnderlineAttribute(UnderlineSingle)
  addWithAttribute("underline style", attr7)
  attrstr.addUnattributed(", and ")

  let attr8 = newUnderlineAttribute(UnderlineDouble)
  let attr82 = newUnderlineColorAttribute(UnderlineColorCustom, 1.0, 0.0, 0.5, 1.0)
  addWithAttribute("underline color", attr8, attr82)
  attrstr.addUnattributed(". ")

  attrstr.addUnattributed("Furthermore, there are attributes allowing for ")
  let attr9 = newUnderlineAttribute(UnderlineSuggestion)
  let attr92 = newUnderlineColorAttribute(UnderlineColorSpelling)
  addWithAttribute("special underlines for indicating spelling errors", attr9, attr92)
  attrstr.addUnattributed(" (and other types of errors) ")

  attrstr.addUnattributed("and control over OpenType features such as ligatures (for instance, ")
  let otf = newOpenTypeFeatures()
  otf.add("liga", off)
  let attr10 = newFeaturesAttribute(otf)
  addWithAttribute("afford", attr10)
  attrstr.addUnattributed(" vs. ")
  otf.add("liga", on)
  let attr11 = newFeaturesAttribute(otf)
  addWithAttribute("afford", attr11)
  
  attrstr.addUnattributed(").\n")

  attrstr.addUnattributed("Use the controls opposite to the text to control properties of the text.")

  free otf

proc drawHandler*(a: ptr AreaHandler; area: ptr rawui.Area; p: ptr AreaDrawParams) {. cdecl .} =
  makeAttributedString()

  var 
    params: DrawTextLayoutParams
    defaultFont: ptr FontDescriptor

  #let useSystemFont = systemFont.checked

  #if useSystemFont:
  #  loadControlFont defaultFont
  #else:
  var f = fontButton.font
  defaultFont = addr f

  params.string = attrstr.impl
  params.defaultFont = defaultFont
  params.width = p.areaWidth
  params.align = DrawTextAlign(alignment.selected)

  let textLayout = newDrawTextLayout(addr params)
  
  p.context.drawText textLayout, (0.0, 0.0)

  free textLayout
  freeFont defaultFont

proc main =
  makeAttributedString()

  var handler: AreaHandler 

  handler.draw = drawHandler
  handler.mouseEvent = (_: ptr AreaHandler, a: ptr rawui.Area, b: ptr AreaMouseEvent) {.cdecl.} => (discard)
  handler.mouseCrossed = (_: ptr AreaHandler, a: ptr rawui.Area, b: cint) {.cdecl.} => (discard)
  handler.dragBroken = (_: ptr AreaHandler, a: ptr rawui.Area) {.cdecl.} => (discard)
  handler.keyEvent = (_: ptr AreaHandler, a: ptr rawui.Area, b: ptr AreaKeyEvent) {.cdecl.} => cint 0

  var window = newWindow("libui-ng Text-Drawing Example", 640, 480)
  window.margined = true

  var hbox = newHorizontalBox(true)
  window.child = hbox

  var vbox = newVerticalBox(true)
  hbox.add vbox

  var area = newArea(addr handler)
  hbox.add area, true

  fontButton = newFontButton()
  fontButton.onchanged = (_: FontButton) => area.queueRedrawAll()
  vbox.add fontButton

  let form = newForm(true)
  # on OS X if stretchy is set to `true` then the window can't resize
  vbox.add form

  alignment = newCombobox()
  # note that the items match with the values of the DrawTextAlign values
  alignment.add "Left", "Center", "Right"
  alignment.selected = 0 # start with left alignment
  alignment.onselected = (_: Combobox) => area.queueRedrawAll()
  form.add "Alignment", alignment

  #systemFont = newCheckbox("")
  #systemFont.ontoggled = (_: Checkbox) => area.queueRedrawAll()
  #form.add "System Font", systemFont

  free attrstr

  show window
  mainLoop()

when isMainModule:
  init()
  main()
