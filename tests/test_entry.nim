import std/unittest

import uing

suite "Test Entry":
  # setup
  init()

  let window = newWindow("Entry Test", 200, 200)
  let entry = newEntry()

  # tests
  test "Entry can set text":
    entry.text = "test"

  test "Entry can get text":
    check entry.text == "test"

  test "Entry can clear text":
    entry.clear()
    check entry.text == ""

  test "Entry can set readOnly":
    entry.readOnly = true

    entry.readOnly = false

  test "Entry can get readOnly":
    check not entry.readOnly

  # teardown
  window.child = entry
  show window

  mainSteps()
  mainStep(1)

  uing.quit()
    