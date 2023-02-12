import std/unittest

import uing

suite "Test Entry":
  # setup
  init()

  let window = newWindow("Entry Test", 200, 200)
  let entry = newEntry()

  # tests
  test "Entry text":
    entry.text = "test"
    check entry.text == "test"

  test "Entry can clear text":
    entry.clear()
    check entry.text == ""

  test "Entry can set readOnly":
    entry.readOnly = true
    check entry.readOnly

    entry.readOnly = false
    check not entry.readOnly

  # teardown
  window.child = entry
  show window

  mainSteps()
  mainStep(1)

  uing.quit()
    