import std/sugar

import uing
from uing/rawui import nil

# TODO i really dislike these global vars

var 
  systemFont: Checkbox
  fontButton: FontButton
  alignment: Combobox
  attrstr: AttributedString

proc appendWithAttribute(what: string; attr, attr2: Attribute = nil) =
  let
    start = attrstr.len
    `end` = start + what.len

  attrstr.addUnattributed what
  attrstr.setAttribute attr, start, `end`

  if attr2 != nil:
    attrstr.setAttribute attr2, start, `end`

proc makeAttributedString =
  attrstr = newAttributedString(
    "Drawing strings with libui-ng is done with the AttributedString and DrawTextLayout objects.\n" &
    "AttributedString lets you have a variety of attributes: "
  )

  let attr = newFamilyAttribute("Courier New")
  appendWithAttribute("font family", attr)
  attrstr.addUnattributed(", ")

  let attr1 = newSizeAttribute(18)
  appendWithAttribute("font size", attr1)
  attrstr.addUnattributed(", ")

  let attr2 = newWeightAttribute(TextWeightBold)
  appendWithAttribute("font weight", attr2)
  attrstr.addUnattributed(", ")

  let attr3 = newItalicAttribute(TextItalicItalic)
  appendWithAttribute("font italicness", attr3)
  attrstr.addUnattributed(", ")

  let attr4 = newStretchAttribute(TextStretchCondensed)
  appendWithAttribute("font stretch", attr4)
  attrstr.addUnattributed(", ")

  let attr5 = newColorAttribute(0.75, 0.25, 0.5, 0.75)
  appendWithAttribute("text color", attr5)
  attrstr.addUnattributed(", ")

  let attr6 = newBackgroundColorAttribute(0.5, 0.5, 0.25, 0.5)
  appendWithAttribute("text background color", attr6)
  attrstr.addUnattributed(", ")

  let attr7 = newUnderlineAttribute(UnderlineSingle)
  appendWithAttribute("underline style", attr7)
  attrstr.addUnattributed(", and ")

  let attr8 = newUnderlineAttribute(UnderlineDouble)
  let attr82 = newUnderlineColorAttribute(UnderlineColorCustom, 1.0, 0.0, 0.5, 1.0)
  appendWithAttribute("underline color", attr8, attr82)
  attrstr.addUnattributed(". ")

  attrstr.addUnattributed("Furthermore, there are attributes allowing for ")
  let attr9 = newUnderlineAttribute(UnderlineSuggestion)
  let attr92 = newUnderlineColorAttribute(UnderlineColorSpelling)
  appendWithAttribute("special underlines for indicating spelling errors", attr9, attr92)
  attrstr.addUnattributed(" (and other types of errors) ")

  attrstr.addUnattributed("and control over OpenType features such as ligatures (for instance, ")
  let otf = newOpenTypeFeatures()
  otf.add("liga", off)
  let attr10 = newFeaturesAttribute(otf)
  appendWithAttribute("afford", attr10)
  attrstr.addUnattributed(" vs. ")
  otf.add("liga", on)
  let attr11 = newFeaturesAttribute(otf)
  appendWithAttribute("afford", attr11)
  free otf
  attrstr.addUnattributed(").\n")

  attrstr.addUnattributed("Use the controls opposite to the text to control properties of the text.")

proc drawHandler*(a: ptr AreaHandler; area: ptr rawui.Area; p: ptr AreaDrawParams) {. cdecl .} =
  var 
    textLayout: DrawTextLayout
    defaultFont: FontDescriptor
    params: DrawTextLayoutParams

  let useSystemFont = systemFont.checked

  if useSystemFont:
    loadControlFont defaultFont
  else:
    defaultFont = fontButton.font

  params.string = attrstr.impl
  params.defaultFont = defaultFont.impl
  params.width = p.areaWidth
  params.align = DrawTextAlign(alignment.selected)
  
  textLayout = newDrawTextLayout(addr params)
  echo "draw"
  p.context.drawText textLayout, (0.0, 0.0)

  free textLayout
  free defaultFont

proc main =
  var handler: AreaHandler 

  handler.draw = drawHandler
  handler.mouseEvent = (_: ptr AreaHandler, a: ptr rawui.Area, b: ptr AreaMouseEvent) {.cdecl.} => (discard)
  handler.mouseCrossed = (_: ptr AreaHandler, a: ptr rawui.Area, b: cint) {.cdecl.} => (discard)
  handler.dragBroken = (_: ptr AreaHandler, a: ptr rawui.Area) {.cdecl.} => (discard)
  handler.keyEvent = (_: ptr AreaHandler, a: ptr rawui.Area, b: ptr AreaKeyEvent) {.cdecl.} => cint 0

  makeAttributedString()

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
  vbox.add form

  alignment = newCombobox()
  # note that the items match with the values of the uiDrawTextAlign values
  alignment.add "Left", "Center", "Right"
  alignment.selected = 0 # start with left alignment
  alignment.onselected = (_: Combobox) => area.queueRedrawAll()
  form.add "Alignment", alignment

  systemFont = newCheckbox("")
  systemFont.ontoggled = (_: Checkbox) => area.queueRedrawAll()
  form.add "System Font", systemFont

  free attrstr

  show window
  mainLoop()

when isMainModule:
  init()
  main()
