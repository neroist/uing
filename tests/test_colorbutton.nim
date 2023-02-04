import std/unittest
import std/colors

import uing

suite "Test ColorButton":
  # setup
  init()

  let window = newWindow("ColorButton Test", 200, 200)
  let colorButton = newColorButton()

  # tests
  test "ColorButton color":
    colorButton.setColor(0.5, 0.35, 0.88)

  test "ColorButton color (std/colors)":
    colorButton.color = rgb(128, 89, 224)

  # teardown
  window.child = colorButton
  show window

  mainSteps()
  discard mainStep(1)

  uing.quit()
    