# example of genui macro with the same ui as controllgallery3.nim

import std/sugar

import uing/genui
import uing

proc main = 
  const
    MsgBoxTitle = "This is a normal message box."
    MsgBoxDesc = "More detailed information can be shown here."
    ErrorMsgBoxTitle = "This message box describes an error."

  var
    spin: Spinbox
    slide: Slider
    progress: ProgressBar

  proc update(sender: Spinbox or Slider) =
    spin.value = sender.value
    slide.value = sender.value
    progress.value = sender.value

  genui:
    window%Window("libui-ng Control Gallery", 800, 600):
      tab%Tab:
        # Basic Controls
        VerticalBox(padded = true)[name = "Basic Controls"]:
          HorizontalBox(padded = true):
            Button("Button")
            Checkbox("Checkbox")
            
          Label("This is a label\nLabels can span muliple lines.")

          HorizontalSeparator()

          Group("Entries", margined = true)[stretchy = true]:
            Form(padded = true):
              Entry[label = "Entry"]
              PasswordEntry[label = "Password Entry"]
              SearchEntry[label = "Search Entry"]
              MultilineEntry[label = "Multiline Entry", stretchy = true]
              NonWrappingMultilineEntry[label = "Multiline Entry No Wrap", stretchy = true]

        # Numbers and Lists
        HorizontalBox(padded = true)[name = "Numbers and Lists"]:
          Group("Numbers", margined = true)[stretchy = true]:
            VerticalBox(padded = true):
              spin%Spinbox(0..100, onchanged = update)
              slide%Slider(0..100, onchanged = update)
              progress%ProgressBar
              ProgressBar(indeterminate = true)

          Group("Lists", margined = true)[stretchy = true]:
            VerticalBox(padded = true):
              Combobox:
                "Combobox Item 1"
                "Combobox Item 2"
                "Combobox Item 3"
              EditableCombobox:
                "Editable Item 1"
                "Editable Item 2"
                "Editable Item 3"
              RadioButtons:
                "Radio Button 1"
                "Radio Button 2"
                "Radio Button 3"

        # Data Choosers
        HorizontalBox(padded = true)[name = "Data Choosers"]:
          VerticalBox(padded = true):
            DatePicker()
            TimePicker()
            DateTimePicker()
            FontButton()
            ColorButton()

          VerticalSeparator()

          Grid(padded = true)[stretchy = true]:
            openFileEntry%Entry[1, 0, 1, 1, true, AlignFill, false, AlignFill]
            openFolderEntry%Entry[1, 1, 1, 1, true, AlignFill, false, AlignFill]
            saveFileEntry%Entry[1, 2, 1, 1, true, AlignFill, false, AlignFill]
            Button("Open File", onclick = (_: Button) => (openFileEntry.text = window.openFile()))[0, 0, 1, 1, false, AlignFill, false, AlignFill]
            Button("Open Folder", onclick = (_: Button) => (openFileEntry.text = window.openFolder()))[0, 1, 1, 1, false, AlignFill, false, AlignFill]
            Button("Save File", onclick = (_: Button) => (openFileEntry.text = window.saveFile()))[0, 2, 1, 1, false, AlignFill, false, AlignFill]

            HorizontalBox(padded = true)[0, 3, 2, 1, false, AlignCenter, false, AlignStart]:
              Button("Message Box", onclick = (_: Button) => window.msgBox(MsgBoxTitle, MsgBoxDesc))
              Button("Error Box", onclick = (_: Button) => window.error(ErrorMsgBoxTitle, MsgBoxDesc))

  for entry in [openFileEntry, openFolderEntry, saveFileEntry]:
    entry.readOnly = true

  for i in 0 ..< tab.tabs.len:
    tab.setMargined i, true

  window.margined = true

  show window
  mainLoop()

init()
main()
