import uing
from uing/rawui import nil

var 
  systemFont: Checkbox
  fontButton: FontButton
  alignment: Combobox
  attrstr: AttributedString

proc makeAttributedString =
  attrstr = newAttributedString(
    "Drawing strings with libui-ng is done with the AttributedString and DrawTextLayout objects.\n" &
    "AttributedString lets you have a variety of attributes: "
  )

  let attr = newFamilyAttribute("Courier New")
  attrstr.addWithAttributes("font family", attr)
  attrstr.addUnattributed(", ")

  let attr1 = newSizeAttribute(18)
  attrstr.addWithAttributes("font size", attr1)
  attrstr.addUnattributed(", ")

  let attr2 = newWeightAttribute(TextWeightBold)
  attrstr.addWithAttributes("font weight", attr2)
  attrstr.addUnattributed(", ")

  let attr3 = newItalicAttribute(TextItalicItalic)
  attrstr.addWithAttributes("font italicness", attr3)
  attrstr.addUnattributed(", ")

  let attr4 = newStretchAttribute(TextStretchCondensed)
  attrstr.addWithAttributes("font stretch", attr4)
  attrstr.addUnattributed(", ")

  let attr5 = newColorAttribute(0.75, 0.25, 0.5, 0.75)
  attrstr.addWithAttributes("text color", attr5)
  attrstr.addUnattributed(", ")

  let attr6 = newBackgroundColorAttribute(0.5, 0.5, 0.25, 1.0)
  attrstr.addWithAttributes("text background color", attr6)
  attrstr.addUnattributed(", ")

  let attr7 = newUnderlineAttribute(UnderlineSingle)
  attrstr.addWithAttributes("underline style", attr7)
  attrstr.addUnattributed(", and ")

  let attr8 = newUnderlineAttribute(UnderlineDouble)
  let attr82 = newUnderlineColorAttribute(UnderlineColorCustom, 1.0, 0.0, 0.5, 1.0)
  attrstr.addWithAttributes("underline color", attr8, attr82)
  attrstr.addUnattributed(". ")

  attrstr.addUnattributed("Furthermore, there are attributes allowing for ")
  let attr9 = newUnderlineAttribute(UnderlineSuggestion)
  let attr92 = newUnderlineColorAttribute(UnderlineColorSpelling)
  attrstr.addWithAttributes("special underlines for indicating spelling errors", attr9, attr92)
  attrstr.addUnattributed(" (and other types of errors) ")

  attrstr.addUnattributed("and control over OpenType features such as ligatures (for instance, ")
  let otf = newOpenTypeFeatures()
  otf.add("liga", off)
  let attr10 = newFeaturesAttribute(otf)
  attrstr.addWithAttributes("afford", attr10)
  attrstr.addUnattributed(" vs. ")
  otf.add("liga", on)
  let attr11 = newFeaturesAttribute(otf)
  attrstr.addWithAttributes("afford", attr11)
  
  attrstr.addUnattributed(").\n")

  attrstr.addUnattributed("Use the controls opposite to the text to control properties of the text.")

  free otf

proc drawHandler*(a: ptr AreaHandler; area: ptr rawui.Area; p: ptr AreaDrawParams) {. cdecl .} =
  makeAttributedString()

  var 
    params: DrawTextLayoutParams
    defaultFont: FontDescriptor

  let useSystemFont = systemFont.checked

  if useSystemFont:
    loadControlFont addr defaultFont
  else:
    var f = fontButton.font
    defaultFont = f

  params.string = attrstr.impl
  params.defaultFont = addr defaultFont
  params.width = p.areaWidth
  params.align = DrawTextAlign(alignment.selected)

  let textLayout = newDrawTextLayout(addr params)
  
  p.context.drawText textLayout, (0.0, 0.0)

  free textLayout
  
  if not useSystemFont:
    freeFont addr defaultFont

proc main =
  makeAttributedString()

  var handler: AreaHandler 

  handler.draw = drawHandler
  handler.mouseEvent = proc (_: ptr AreaHandler, a: ptr rawui.Area, b: ptr AreaMouseEvent) {.cdecl.} = discard
  handler.mouseCrossed = proc (_: ptr AreaHandler, a: ptr rawui.Area, b: cint) {.cdecl.} = discard
  handler.dragBroken = proc (_: ptr AreaHandler, a: ptr rawui.Area) {.cdecl.} = discard
  handler.keyEvent = proc (_: ptr AreaHandler, a: ptr rawui.Area, b: ptr AreaKeyEvent): cint {.cdecl.} = cint 0

  let window = newWindow("libui-ng Text-Drawing Example", 640, 480)
  window.margined = true

  let hbox = newHorizontalBox(true)
  window.child = hbox

  let vbox = newVerticalBox(true)
  hbox.add vbox

  let area = newArea(addr handler)
  hbox.add area, true

  fontButton = newFontButton()
  fontButton.onchanged = proc (_: FontButton) = area.queueRedrawAll()
  vbox.add fontButton

  let form = newForm(true)
  # on OS X if stretchy is set to `true` then the window can't resize
  vbox.add form

  alignment = newCombobox()
  # note that the items match with the values of the DrawTextAlign values
  alignment.add "Left", "Center", "Right"
  alignment.selected = 0 # start with left alignment
  alignment.onselected = proc (_: Combobox) = area.queueRedrawAll()
  form.add "Alignment", alignment

  systemFont = newCheckbox("")
  systemFont.ontoggled = proc (_: Checkbox) = area.queueRedrawAll()
  form.add "System Font", systemFont

  free attrstr

  show window
  mainLoop()

init()
main()
