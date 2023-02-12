import std/unittest

import uing

suite "Test RadioButtons":
  # setup
  init()

  let window = newWindow("RadioButtons Test", 200, 200)
  let radioButtons = newRadioButtons()

  # tests
  test "RadioButtons can add items":
    radioButtons.add "Test1", "Test2", "Test3"
    check radioButtons.items == @["Test1", "Test2", "Test3"]

  test "RadioButtons can set selected":
    radioButtons.selected = 2
    check radioButtons.selected == 2

  test "RadioButtons can remove selected":
    radioButtons.selected = -1
    check radioButtons.selected == -1
  
  # teardown
  window.child = radioButtons
  show window

  mainSteps()
  mainStep(1)

  uing.quit()
  