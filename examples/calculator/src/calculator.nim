import std/strformat

import nimkalc
import uing

var 
  window: Window
  input: Entry
  output: Entry
  history: MultilineEntry

proc eval(_: Button) = 
  if len(input.text) == 0: return

  try: 
    let 
      result = eval(input.text)

      resultVal = if result.kind == NodeKind.Integer: 
          $int(result.value)
        else: 
          $result.value

    output.text = resultVal
    history.text = fmt"{input.text} = {resultVal}" & '\n' & history.text

  except ParseError:
    window.error "A Parsing Error Occurred", getCurrentExceptionMsg()
  except MathError:
    window.error "An Arithmetic Error Occurred", getCurrentExceptionMsg()
  except OverflowDefect:
    window.error "Value Overflow/Underflow Detected", getCurrentExceptionMsg()
  except:
    window.error "An Error Occurred", getCurrentExceptionMsg()

proc main = 
  let fileMenu = newMenu("File")
  fileMenu.addItem(
    "Clear All",
    proc (_: MenuItem, win: Window) =
      input.clear()
      output.clear()
      history.clear()
  )
  fileMenu.addItem(
    "Clear History",
    proc (_: MenuItem, win: Window) = history.clear()
  )
  fileMenu.addQuitItem(
    proc (): bool =
      window.destroy()
      return true
  )

  window = newWindow("Calculator", 800, 600, true)
  window.margined = true

  let vbox = newVerticalBox(true)
  window.child = vbox

  let form = newForm(true)
  vbox.add form

  let hbox = newHorizontalBox(true)
  input = newEntry()
  hbox.add input, true
  hbox.add newButton("Eval", eval)
  hbox.add newButton("Clear") do (_: Button):
    input.clear()
    output.clear()

  form.add "Input:", hbox, true


  output = newEntry()
  output.readOnly = true
  form.add "Output:", output, true

  let historyGroup = newGroup("History")
  history = newNonWrappingMultilineEntry()
  history.readOnly = true
  historyGroup.child = history

  vbox.add historyGroup, true

  show window
  mainLoop()

init()
main()
