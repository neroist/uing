import std/unittest
import std/colors

import uing

suite "Test ColorButton":
  # setup
  init()

  let window = newWindow("ColorButton Test", 200, 200)
  let colorButton = newColorButton()

  # tests
  test "ColorButton can set color":
    colorButton.setColor(0.5, 0.35, 0.88)

  test "ColorButton can get color":
    let color = colorButton.color

    check color == (0.5, 0.35, 0.88, 1.0)

  test "ColorButton can set color (std/colors)":
    colorButton.color = rgb(128, 89, 224)

  # teardown
  window.child = colorButton
  show window

  mainSteps()
  mainStep(1)

  uing.quit()
    