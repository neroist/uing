import std/unittest

import uing

suite "Test Checkbox":
  # setup
  init()

  let window = newWindow("Checkbox Test", 200, 200)
  let checkbox = newCheckbox("")

  # tests
  test "Checkbox text":
    checkbox.text = "test"
    check checkbox.text == "test"

  test "Checkbox can be set checked":
    checkbox.checked = true
    check checkbox.checked

  test "Checkbox can be set unchecked":
    checkbox.checked = false
    check not checkbox.checked

  # teardown
  window.child = checkbox
  show window

  mainSteps()
  mainStep(1)

  uing.quit()
    