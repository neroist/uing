import std/unittest

import uing

suite "Test Checkbox":
  # setup
  init()

  let window = newWindow("Checkbox Test", 200, 200)
  let checkbox = newCheckbox("")

  # tests
  test "Checkbox can set text":
    checkbox.text = "test"
  
  test "Checkbox can get text":
    check checkbox.text == "test"

  test "Checkbox can be set checked/unchecked":
    checkbox.checked = true

    checkbox.checked = false

  test "Checkbox can get checked":
    check not checkbox.checked

  # teardown
  window.child = checkbox
  show window

  mainSteps()
  mainStep(1)

  uing.quit()
    