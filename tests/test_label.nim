import std/unittest

import uing

suite "Test Label":
  # setup
  init()

  let window = newWindow("Label Test", 200, 200)
  let label = newLabel("")

  # tests
  test "Label can set text":
    label.text = "Test"

  test "Label can get text":
    check label.text == "Test"
  
  # teardown
  window.child = label
  show window

  mainSteps()
  mainStep(1)

  uing.quit()
    