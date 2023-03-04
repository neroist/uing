# Test & show the new high level wrapper

import uing

proc main*() =
  var mainwin: Window

  var menu = newMenu("File")

  menu.addItem("Open", proc(_: MenuItem, win: Window) =
    let filename = win.openFile()

    if filename.len == 0:
      win.error("No file selected", "Don't be alarmed!")
    else:
      win.msgBox("File selected", filename)
  )

  menu.addItem("Save", proc(_: MenuItem, win: Window) =
    let filename = win.saveFile()

    if filename.len == 0:
      win.error("No file selected", "Don't be alarmed!")
    else:
      win.msgBox("File selected (don't worry, it's still there)", filename)
  )

  menu.addQuitItem(
    proc(): bool =
      mainwin.destroy()
      return true
  )

  menu = newMenu("Edit")
  menu.addCheckItem("Checkable Item")
  menu.addSeparator()
  disable menu.addItem("Disabled Item")
  menu.addPreferencesItem()

  menu = newMenu("Help")
  menu.addItem("Help")
  menu.addAboutItem()

  mainwin = newWindow("libui-ng Control Gallery", 640, 480, true)
  mainwin.margined = true

  let box = newVerticalBox(true)
  mainwin.child = box

  let hbox = newHorizontalBox(true)
  box.add hbox, true

  let group = newGroup("Basic Controls", true)
  hbox.add group

  let inner = newVerticalBox(true)
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

  let inner2 = newVerticalBox(true)
  hbox.add inner2, true

  let group2 = newGroup("Numbers", true)
  inner2.add group2

  let inner3 = newVerticalBox(true)
  group2.child = inner3

  var spinbox: Spinbox
  var slider: Slider
  var progressbar: ProgressBar

  proc update(sender: Spinbox or Slider) =
    spinbox.value = sender.value
    slider.value = sender.value
    progressBar.value = sender.value

  spinbox = newSpinbox(0..100, update)
  inner3.add spinbox

  slider = newSlider(0..100, update)
  inner3.add slider

  progressbar = newProgressBar()
  inner3.add progressbar

  let group3 = newGroup("Lists", true)
  inner2.add group3

  let inner4 = newVerticalBox(true)
  group3.child = inner4

  let cbox = newCombobox(["Combobox Item 1", "Combobox Item 2", "Combobox Item 3"])
  inner4.add cbox

  let ecbox = newEditableCombobox(["Editable Item 1", "Editable Item 2", "Editable Item 3"])
  inner4.add ecbox

  let rb = newRadioButtons(["Radio Button 1", "Radio Button 2", "Radio Button 3"])
  inner4.add rb, true

  let tab = newTab()
  tab.add "Page 1", newHorizontalBox()
  tab.add "Page 2", newHorizontalBox()
  tab.add "Page 3", newHorizontalBox()
  inner2.add tab, true

  show(mainwin)
  mainLoop()

init()
main()
