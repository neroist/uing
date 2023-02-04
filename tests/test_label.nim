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
    check label.text == "Test"
  
  # teardown
  window.child = label
  show window

  mainSteps()
  discard mainStep(1)

  uing.quit()
    