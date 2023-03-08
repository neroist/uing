import std/unittest

import uing

suite "Test Button":
  # setup
  init()

  let window = newWindow("Button Test", 200, 200)
  let button = newButton("")

  # tests
  test "Button can set text":
    button.text = "test"

  test "Button can get text":
    check button.text == "test"

  # teardown
  window.child = button
  show window

  mainSteps()
  mainStep(1)

  uing.quit()
    