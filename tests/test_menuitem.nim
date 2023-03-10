# test Menu and MenuItem

import std/unittest

import uing

suite "Test MenuItem":
  # setup
  init()

  let menu = newMenu("Test")
  let item = menu.addItem("Test")
  let checkItem = menu.addCheckItem("Test Check Item")
  let window = newWindow("MenuItem Test", 200, 200, true)

  # tests
  test "MenuItem can be disabled":
    disable item

  test "MenuItem can be enabled":
    enable item

  test "MenuItem can be checked":
    checkItem.checked = true

    checkItem.checked = false

  test "MenuItem can get checked":
    check not checkItem.checked
  
  # teardown
  show window

  mainSteps()
  mainStep(1)

  uing.quit()
  