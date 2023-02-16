# Example by PMunch (https://github.com/PMunch), not me! (with a few modifications)

import uing/genui
import uing

# The macro is a fairly simple substitution
# It follows one of three patterns:
# <Widget name>(arguments, for, widget, creator)[arguments, for, add, function]:
#   <Children>
# <Identifier>%<Widget name>(arguments, for, widget, creator)[arguments, for, add, function]:
#   <Children>
# %<Identifier>[arguments, for, add, function]:
#   <Children>
# "String"
#
# Both ()-arguments and []-arguments can be omitted
# If the widget has no children the : must be omitted
# Identifiers create a var statement assigning the widget to the identifier, or assign the widget to the identifier if it already exists
# Using %<identifier> you can add widget created previously, it takes the same add options and children as any other widget
# The string pattern is used for widgets which have an add function for string values, such as radio-, and comboboxes.

# This is an example of a simple function which creates a piece of UI
# You will notice it uses result% to bind the RadioButtons widget created to the result
proc getRadioBox(): RadioButtons =
  genui:
    result%RadioButtons:
      "Radio Button 1"
      "Radio Button 2"
      "Radio Button 3"

# This is a longer example which creates the same UI as in the controllgallery2.nim example (without menu)
proc main() =
  var spinbox: Spinbox
  var slider: Slider
  var progressbar: ProgressBar

  # This gets the widget from the previously defined function and adds callback to it
  var radioBox = getRadioBox()

  radioBox.onselected = proc (sender: RadioButtons) =
    echo radioBox.items[radioBox.selected]

  # This is another way to create a callback, it will be assigned to the widgets later
  proc update(sender: Slider or Spinbox) =
    spinbox.value = sender.value
    slider.value = sender.value
    progressBar.value = sender.value

  # This is where the magic happens. Note that most of the parameter names are included,
  # this is a stylistic choice which I find makes the code easier to read. The notable
  # exception to this is for widgets which take only a string as it's fairly obvious what it's used for
  genui:
    # The window is attached to the mainwin variable for later use
    mainwin%Window("libui-ng Control Gallery", 640, 480):
      VerticalBox(padded = true):
        HorizontalBox(padded = true)[stretchy = true]:
          Group("Basic Controls", margined = true):
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
            Group("Numbers", margined = true):
              VerticalBox(padded = true):
                # These are the three widgets which variables was declared earlier and used in the callback
                spinbox%Spinbox(0..100, onchanged = update)
                slider%Slider(0..100, onchanged = update)
                progressbar%ProgressBar
            Group("Lists", margined = true):
              VerticalBox(padded = true):
                Combobox:
                  "Combobox Item 1"
                  "Combobox Item 2"
                  "Combobox Item 3"
                EditableCombobox:
                  "Editable Item 1"
                  "Editable Item 2"
                  "Editable Item 3"
                # This does not create a new widget but inserts the radio box created earlier
                %radioBox
            # Tabs are a bit strange as their add function has two required arguments
            # Here the name parameter must be included fully qualified in order to be properly added
            Tab[stretchy = true]:
              HorizontalBox[name = "Page 1"]
              HorizontalBox[name = "Page 2"]
              HorizontalBox[name = "Page 3"]

  mainwin.margined = true

  show mainwin
  mainLoop()

when isMainModule:
  init()
  main() 
