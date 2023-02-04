import std/unittest

import uing

suite "Test Button":
  # setup
  init()

  let window = newWindow("Button Test", 200, 200)
  let button = newButton("")

  # tests
  test "Button text":
    button.text = "test"
    check button.text == "test"

  # teardown
  window.child = button
  show window

  mainSteps()
  discard mainStep(1)

  uing.quit()
    