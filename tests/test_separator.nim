import std/unittest

import uing

suite "Test Separator":
  # setup
  init()

  let window = newWindow("Separator Test", 200, 200)
  let separator = newHorizontalSeparator()

  # tests
  # ?
  
  # teardown
  window.child = separator
  show window

  mainSteps()
  discard mainStep(1)

  uing.quit()
  