import std/sugar

import uing

var 
  area: Area
  systemFont: Checkbox
  fontButton: FontButton
  alignment: Combobox
  attrstr: AttributedString

proc appendWithAttribute(what: string; attr, attr2: Attribute = nil) =
  let
    start = attrstr.len
    `end` = start + uint what.len

  attrstr.addUnattributed what
  attrstr.setAttribute attr, start, `end`
  if attr2 != nil:
    attrstr.setAttribute attr2, start, `end`

proc makeAttributedString =
  attrstr = newAttributedString(
    "Drawing strings with libui is done with the uiAttributedString and uiDrawTextLayout objects.\n" &
    "uiAttributedString lets you have a variety of attributes: ")

  let attr = newFamilyAttribute("Courier New")
  appendWithAttribute("font family", attr, nil)
  attrstr.addUnattributed(", ")

  let attr1 = newSizeAttribute(18)
  appendWithAttribute("font size", attr1, nil)
  attrstr.addUnattributed(", ")

  let attr2 = newWeightAttribute(TextWeightBold)
  appendWithAttribute("font weight", attr2, nil)
  attrstr.addUnattributed(", ")

  let attr3 = newItalicAttribute(TextItalicItalic)
  appendWithAttribute("font italicness", attr3, nil)
  attrstr.addUnattributed(", ")

  let attr4 = newStretchAttribute(TextStretchCondensed)
  appendWithAttribute("font stretch", attr4, nil)
  attrstr.addUnattributed(", ")

  let attr5 = newColorAttribute(0.75, 0.25, 0.5, 0.75)
  appendWithAttribute("text color", attr5, nil)
  attrstr.addUnattributed(", ")

  let attr6 = newBackgroundAttribute(0.5, 0.5, 0.25, 0.5)
  appendWithAttribute("text background color", attr6, nil)
  attrstr.addUnattributed(", ")


  let attr7 = newUnderlineAttribute(UnderlineSingle)
  appendWithAttribute("underline style", attr7, nil)
  attrstr.addUnattributed("and ")

  let attr8 = newUnderlineAttribute(UnderlineDouble)
  let attr82 = newUnderlineColorAttribute(uiUnderlineColorCustom, 1.0, 0.0, 0.5, 1.0)
  appendWithAttribute("underline color", attr8, attr82)
  attrstr.addUnattributed(". ")

  attrstr.addUnattributed("Furthermore, there are attributes allowing for ")
  let attr9 = newUnderlineAttribute(UnderlineSuggestion)
  let attr92 = newUnderlineColorAttribute(uiUnderlineColorSpelling, 0, 0, 0, 0)
  appendWithAttribute("special underlines for indicating spelling errors", attr9, attr92)
  attrstr.addUnattributed(" (and other types of errors) ")

  attrstr.addUnattributed("and control over OpenType features such as ligatures (for instance, ")
  let otf = newOpenTypeFeatures()
  otf.add('l', 'i', 'g', 'a', 0)
  let attr10 = newFeaturesAttribute(otf)
  appendWithAttribute("afford", attr10, nil)
  attrstr.addUnattributed(" vs. ")
  otf.add('l', 'i', 'g', 'a', 1)
  let attr11 = newFeaturesAttribute(otf)
  appendWithAttribute("afford", attr11, nil)
  free otf
  attrstr.addUnattributed(").\n")

  attrstr.addUnattributed("Use the controls opposite to the text to control properties of the text.")

proc drawHandler*(a: ptr AreaHandler; area: ptr Area; p: ptr AreaDrawParams) {.cdecl.} =
  var 
    textLayout: DrawTextLayout
    defaultFont: FontDescriptor
    params: DrawTextLayoutParams

    attrstrImpl = attrstr.impl
    defaultFontImpl = defaultFont.impl

  let useSystemFont = systemFont.checked

  params.string = attrstrImpl

  if useSystemFont:
    loadControlFont defaultFont
  else:
    defaultFont = fontButton.font

  params.defaultFont = defaultFontImpl
  params.width = p.areaWidth
  params.align = DrawTextAlign alignment.selected
  textLayout = newDrawTextLayout(addr params)
  drawText(p.context, textLayout, 0, 0)
  free textLayout

  free defaultFont

proc main =
  var handler: AreaHandler

  handler.draw = drawHandler

  makeAttributedString()

  var mainwin = newWindow("libui Text-Drawing Example", 640, 480, true)
  mainwin.margined = true

  var hbox = newHorizontalBox()
  hbox.padded = true
  mainwin.child = hbox

  var vbox = newVerticalBox()
  vbox.padded = true
  hbox.add vbox

  fontButton = newFontButton()
  fontButton.onchanged = (_: FontButton) => area.queueRedrawAll()
  vbox.add fontButton

  let form = newForm()
  form.padded = true
  vbox.add form

  alignment = newCombobox()
  alignment.add ["Left", "Center", "Right"]
  alignment.selected = 0
  alignment.onselected = (_: Combobox) => area.queueRedrawAll()
  form.add "Alignment", alignment

  systemFont = newCheckbox("")
  systemFont.ontoggled = (_: Checkbox) => area.queueRedrawAll()
  form.add "System Font", systemFont

  area = newArea(addr handler)
  hbox.add area

  show mainwin
  mainLoop()

when isMainModule:
  init()
  main()
