import uing/genui
import uing

proc main() =
  var mainwin: Window
  var spinbox: Spinbox
  var slider: Slider
  var progressbar: ProgressBar

  proc update(sender: Slider or Spinbox) =
    spinbox.value = sender.value
    slider.value = sender.value
    progressBar.value = sender.value

  mainwin = newWindow("libui-ng Control Gallery", 640, 480)
  mainwin.margined = true

  genui:
    box%VerticalBox(padded = true):
      HorizontalBox(padded = true)[stretchy = true]:
        Group(title = "Basic Controls", margined = true):
          VerticalBox(padded = true):
            Button("Button")
            Checkbox("Checkbox")
            Entry("Entry")
            HorizontalSeparator()
            DatePicker()
            TimePicker()
            DateTimePicker()
            FontButton()
            ColorButton()
        VerticalBox(padded = true)[stretchy = true]:
          Group(title = "Numbers", margined = true):
            VerticalBox(padded = true):
              spinbox%Spinbox(range = 0..100, onchanged = update)
              slider%Slider(range = 0..100, onchanged = update)
              progressbar%ProgressBar
          Group(title = "Lists", margined = true):
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
          Tab[stretchy = true]:
            HorizontalBox[name = "Page 1"]
            HorizontalBox[name = "Page 2"]
            HorizontalBox[name = "Page 3"]

  mainwin.child = box
  show mainwin
  mainLoop()

when isMainModule:
  init()
  main() 