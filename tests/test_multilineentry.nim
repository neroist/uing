import std/unittest

import uing

suite "Test MultilineEntry":
  # setup
  init()

  let window = newWindow("MultilineEntry Test", 200, 200)
  let multilineEntry = newMultilineEntry()

  # tests
  test "MultilineEntry can set text":
    multilineEntry.text = "test"
    check multilineEntry.text == "test"

  test "MultilineEntry can clear text":
    multilineEntry.clear()
    check multilineEntry.text == ""

  test "MultilineEntry can add text":
    multilineEntry.add "test\n"
    check multilineEntry.text == "test\n"

  test "MultilineEntry can set readOnly":
    multilineEntry.readOnly = true
    check multilineEntry.readOnly

    multilineEntry.readOnly = false
    check not multilineEntry.readOnly
  
  # teardown
  window.child = multilineEntry
  show window

  mainSteps()
  discard mainStep(1)

  uing.quit()
  