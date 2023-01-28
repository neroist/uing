# Test & show the new high level wrapper
import ui

proc main*() =
  var mainwin: Window

  var menu = newMenu("File")

  menu.addItem("Open", proc(_: MenuItem) =
    let filename = ui.openFile(mainwin)
    if filename.len == 0:
      msgBoxError(mainwin, "No file selected", "Don't be alarmed!")
    else:
      msgBox(mainwin, "File selected", filename)
  )

  menu.addItem("Save", proc(_: MenuItem) =
    let filename = ui.saveFile(mainwin)
    if filename.len == 0:
      msgBoxError(mainwin, "No file selected", "Don't be alarmed!")
    else:
      msgBox(mainwin, "File selected (don't worry, it's still there)", filename)
  )

  menu.addQuitItem(proc(): bool {.closure.} =
    mainwin.destroy()
    return true)

  menu = newMenu("Edit")
  menu.addCheckItem("Checkable Item")
  menu.addSeparator()

  let item = menu.addItem("Disabled Item")
  item.disable()

  menu.addPreferencesItem()
  menu = newMenu("Help")
  menu.addItem("Help")
  menu.addAboutItem()

  mainwin = newWindow("libui-ng Control Gallery", 640, 480, true)
  mainwin.margined = true

  let box = newVerticalBox(true)
  mainwin.child = box

  let hbox = newHorizontalBox(true)
  box.add(hbox, true)

  var group = newGroup("Basic Controls")
  group.margined = true
  hbox.add(group, false)

  var inner = newVerticalBox(true)
  group.child = inner
  inner.add newButton("Button")
  inner.add newCheckbox("Checkbox")
  inner.add newEntry("Entry")
  inner.add newLabel("Label")
  inner.add newHorizontalSeparator()
  inner.add newDatePicker()
  inner.add newTimePicker()
  inner.add newDateTimePicker()
  inner.add newFontButton()
  inner.add newColorButton()

  var inner2 = newVerticalBox()
  inner2.padded = true
  hbox.add inner2

  group = newGroup("Numbers", true)
  inner2.add group

  inner = newVerticalBox(true)
  group.child = inner

  var spinbox: Spinbox
  var slider: Slider
  var progressbar: ProgressBar

  proc update(sender: Spinbox or Slider) =
    spinbox.value = sender.value
    slider.value = sender.value
    progressBar.value = sender.value

  spinbox = newSpinbox(0, 100, update)
  inner.add spinbox

  slider = newSlider(0, 100, update)
  inner.add slider

  progressbar = newProgressBar()
  inner.add progressbar

  group = newGroup("Lists")
  group.margined = true
  inner2.add group

  inner = newVerticalBox()
  inner.padded = true
  group.child = inner

  var cbox = newCombobox()
  cbox.add "Combobox Item 1"
  cbox.add "Combobox Item 2"
  cbox.add "Combobox Item 3"
  inner.add cbox

  var ecbox = newEditableCombobox()
  ecbox.add "Editable Item 1"
  ecbox.add "Editable Item 2"
  ecbox.add "Editable Item 3"
  inner.add ecbox

  var rb = newRadioButtons()
  rb.add "Radio Button 1"
  rb.add "Radio Button 2"
  rb.add "Radio Button 3"
  inner.add rb, true

  var tab = newTab()
  tab.add "Page 1", newHorizontalBox()
  tab.add "Page 2", newHorizontalBox()
  tab.add "Page 3", newHorizontalBox()
  inner2.add tab, true

  show(mainwin)
  mainLoop()

init()
main()
