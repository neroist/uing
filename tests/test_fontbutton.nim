import std/unittest

import uing

suite "Test FontButton":
  # setup
  init()

  let window = newWindow("FontButton Test", 200, 200)
  let fontButton = newFontButton()

  # tests
  test "FontButton can get font":
    discard fontButton.font

  # teardown
  window.child = fontButton
  show window

  mainSteps()
  mainStep(1)

  uing.quit()
    