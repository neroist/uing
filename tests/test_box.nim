import std/unittest

import uing

suite "Test Box":
  # setup
  init()

  let window = newWindow("Box Test", 200, 200)
  let box = newHorizontalBox()

  # tests
  test "Box can add":
    box.add newLabel("Test")

  test "Box can remove":
    box.delete 0

  test "Assert Box children":
    check box.children.len == 0

  test "Box can be set padded":
    box.padded = true

    box.padded = false

  test "Box can get padded":
    check box.padded == false

  # teardown
  window.child = box
  show window

  mainSteps()
  mainStep(1)

  uing.quit()
    