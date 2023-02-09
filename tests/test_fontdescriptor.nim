import std/unittest

import uing

suite "Test FontDescriptor":
  # setup
  init()

  let window = newWindow("FontDescriptor Test", 200, 200)
  var font: FontDescriptor

  # tests
  test "FontDescriptor can load as control font":
    loadControlFont addr font

  test "FontDescriptor can be freed":
    free addr font

  # teardown
  show window

  mainSteps()
  discard mainStep(1)

  uing.quit()
    