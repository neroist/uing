# compile with -d:menus to add a menu bar

import std/with

import uing

proc makeBasicControlsBox: Box =
  result = newVerticalBox(true)

  let bncBox = newHorizontalBox(true)
  bncBox.add newButton("Button")
  bncBox.add newCheckbox("CheckBox")

  result.add bncBox
  result.add newLabel("This is a label\nLabels can span muliple lines.")
  result.add newHorizontalSeparator()

  let 
    entries = newGroup("Entries", true)
    entriesForm = newForm()

  entries.child = entriesForm

  with entriesForm:
    padded = true

    add "Entry", newEntry()
    add "Password Entry", newPasswordEntry()
    add "Search Entry", newSearchEntry()
    add "Multiline Entry", newMultilineEntry(), true
    add "Multiline Entry No Wrap", newNonWrappingMultilineEntry(), true

  result.add entries, true

proc makeNumbersAndListsBox: Box =
  result = newHorizontalBox(true)

  let 
    numbers = newGroup("Numbers", true)
    numbersBox = newVerticalBox(true)

    spin = newSpinbox(0..100)
    slide = newSlider(0..100)
    progress = newProgressBar()

  proc update(sender: Spinbox or Slider) =
    spin.value = sender.value
    slide.value = sender.value
    progress.value = sender.value

  spin.onchanged = update
  slide.onchanged = update

  numbers.child = numbersBox
  numbersBox.add spin
  numbersBox.add slide
  numbersBox.add progress
  numbersBox.add newProgressBar(indeterminate = true)

  let
    lists = newGroup("Lists", true)
    listsBox = newVerticalBox(true)

  lists.child = listsBox
  listsBox.add newCombobox(["Combobox Item 1", "Combobox Item 2", "Combobox Item 3"])
  listsBox.add newEditableCombobox(["Editable Item 1", "Editable Item 2", "Editable Item 3"])
  listsBox.add newRadioButtons(["Radio Button 1", "Radio Button 2", "Radio Button 3"])

  result.add numbers, true
  result.add lists, true

proc makeDataChoosersBox(window: Window): Box =
  result = newHorizontalBox(true)

  const
    MsgBoxTitle = "This is a normal message box."
    MsgBoxDesc = "More detailed information can be shown here."
    ErrorMsgBoxTitle = "This message box describes an error."

  let col1 = newVerticalBox(true)

  with col1:
    add newDatePicker()
    add newTimePicker()
    add newDateTimePicker()
    add newFontButton()
    add newColorButton()

  let 
    col2 = newGrid(true)
    openFileEntry = newEntry()
    openFolderEntry = newEntry()
    saveFileEntry = newEntry()

    msgBoxBox = newHorizontalBox(true)

  for entry in [openFileEntry, openFolderEntry, saveFileEntry]:
    entry.readOnly = true

  msgBoxBox.add newButton("Message Box", proc (_: Button) = window.msgBox(MsgBoxTitle, MsgBoxDesc))
  msgBoxBox.add newButton("Error Box", proc (_: Button) = window.error(ErrorMsgBoxTitle, MsgBoxDesc))

  with col2:
    add newButton("Open File", proc (_: Button) = openFileEntry.text = window.openFile()), 0, 0, 1, 1, false, AlignFill, false, AlignFill
    add openFileEntry, 1, 0, 1, 1, true, AlignFill, false, AlignFill
    add newButton("Open Folder", proc (_: Button) = openFolderEntry.text = window.openFolder()), 0, 1, 1, 1, false, AlignFill, false, AlignFill
    add openFolderEntry, 1, 1, 1, 1, true, AlignFill, false, AlignFill
    add newButton("Save File", proc (_: Button) = saveFileEntry.text = window.saveFile()), 0, 2, 1, 1, false, AlignFill, false, AlignFill
    add saveFileEntry, 1, 2, 1, 1, true, AlignFill, false, AlignFill

    add msgBoxBox, 0, 3, 2, 1, false, AlignCenter, false, AlignStart

  result.add col1
  result.add newVerticalSeparator()
  result.add col2, true

proc main = 
  var window: Window

  when defined(menus):
    let fileMenu = newMenu("File")
    fileMenu.addQuitItem(
      proc(): bool =
        window.destroy()
        return true
    )

    let settingsMenu = newMenu("Settings")
    settingsMenu.addCheckItem("Checkable Item")
    disable settingsMenu.addItem("Disabled Item")
    settingsMenu.addPreferencesItem()

    let helpMenu = newMenu("Help")
    helpMenu.addItem("Help")
    helpMenu.addAboutItem()

  window = newWindow("libui-ng Control Gallery", 800, 600, defined(menus))
  window.margined = true

  let tab = newTab()
  window.child = tab

  # Basic Controls
  let basicControlsBox = makeBasicControlsBox()

  # numbers and lists
  let numbersAndListsBox = makenumbersAndListsBox()

  # data choosers
  let dataChoosersBox = makeDataChoosersBox(window)

  with tab:
    add "Basic Controls", basicControlsBox
    add "Numbers and Lists", numbersAndListsBox
    add "Data Choosers", dataChoosersBox

  for i in 0 ..< tab.tabs.len:
    tab.setMargined i, true

  show window
  mainLoop()

init()
main()
