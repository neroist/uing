import std/sugar
import std/with

import ui

proc makeBasicControlsBox: Box =
  result = newVerticalBox(true)

  var bncBox = newHorizontalBox(true)
  bncBox.add newButton("Button")
  bncBox.add newCheckbox("CheckBox")

  result.add bncBox
  result.add newLabel("This is a label\nLabels can span muliple lines.")
  result.add newHorizontalSeparator()

  var 
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

proc makenumbersAndListsBox: Box =
  result = newHorizontalBox(true)

  var 
    numbers = newGroup("Numbers", true)
    numbersBox = newVerticalBox(true)

    spin = newSpinbox(0, 100)
    slide = newSlider(0, 100)
    progress = newProgressBar()
    progress2 = newProgressBar()

  proc update(sender: Spinbox or Slider) =
    spin.value = sender.value
    slide.value = sender.value
    progress.value = sender.value

  spin.onchanged = update
  slide.onchanged = update

  #progress2.value = -1 # send progressbar to be indeterminate
  progress2.indeterminate = true

  numbers.child = numbersBox
  numbersBox.add spin
  numbersBox.add slide
  numbersBox.add progress
  numbersBox.add progress2

  var
    lists = newGroup("Lists", true)
    listsBox = newVerticalBox(true)

    combo = newCombobox()
    editableCombo = newEditableCombobox()
    radio = newRadioButtons()

  combo.add ["Combobox Item 1", "Combobox Item 2", "Combobox Item 3"]
  editableCombo.add ["Editable Item 1", "Editable Item 2", "Editable Item 3"]
  radio.add ["Radio Button 1", "Radio Button 2", "Radio Button 3"]

  lists.child = listsBox
  listsBox.add combo
  listsBox.add editableCombo
  listsBox.add radio

  result.add numbers, true
  result.add lists, true

proc makeDataChoosersBox(window: Window): Box =
  result = newHorizontalBox(true)

  const
    MsgBoxTitle = "This is a normal message box."
    MsgBoxDesc = "More detailed information can be shown here."
    ErrorMsgBoxTitle = "This message box describes an error."

  var col1 = newVerticalBox(true)

  with col1:
    add newDatePicker()
    add newTimePicker()
    add newDateTimePicker()
    add newFontButton()
    add newColorButton()

  var 
    col2 = newGrid()
    openFileEntry = newEntry()
    openFolderEntry = newEntry()
    saveFileEntry = newEntry()

    msgBoxBox = newHorizontalBox(true)

  for entry in [openFileEntry, openFolderEntry, saveFileEntry]:
    entry.readOnly = true

  msgBoxBox.add newButton("Message Box", (_: Button) => window.msgBox(MsgBoxTitle, MsgBoxDesc))
  msgBoxBox.add newButton("Error Box", (_: Button) => window.msgBoxError(ErrorMsgBoxTitle, MsgBoxDesc))

  with col2:
    padded = true

    add newButton("Open File", (_: Button) => openFileEntry.`text=`(window.openFile())), 0, 0, 1, 1, false, AlignFill, false, AlignCenter
    add openFileEntry, 1, 0, 1, 1, true, AlignFill, false, AlignCenter
    add newButton("Open Folder", (_: Button) => openFolderEntry.`text=`(window.openFolder())), 0, 1, 1, 1, false, AlignFill, false, AlignCenter
    add openFolderEntry, 1, 1, 1, 1, true, AlignFill, false, AlignCenter
    add newButton("Save File", (_: Button) => saveFileEntry.`text=`(window.saveFile())), 0, 2, 1, 1, false, AlignFill, false, AlignCenter
    add saveFileEntry, 1, 2, 1, 1, true, AlignFill, false, AlignCenter

    add msgBoxBox, 1, 3, 1, 1, false, AlignCenter, false, AlignCenter

  result.add col1
  result.add newVerticalSeparator()
  result.add col2, true

proc main = 
  var window: Window

  when defined(menus):
    let fileMenu = newMenu("File")
    fileMenu.addQuitItem(
      proc(): bool {. closure .} =
        window.destroy()
        return true
    )

    let settingsMenu = newMenu("Settings")
    settingsMenu.addCheckItem("Checkable Item")
    let disabledItem = settingsMenu.addItem("Disabled Item")
    disabledItem.disable()
    settingsMenu.addPreferencesItem()

    let helpMenu = newMenu("Help")
    helpMenu.addItem("Help")
    helpMenu.addAboutItem()

  window = newWindow("libui-ng Control Gallery", 800, 600, defined(menus))
  window.margined = true

  var tab = newTab()
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
    
    setMargined(0, true)
    setMargined(1, true)
    setMargined(2, true)

  show window
  mainLoop()

when isMainModule:
  init()
  main()