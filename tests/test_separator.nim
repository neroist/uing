import std/unittest

import uing

suite "Test Separator":
  # setup
  init()

  let window = newWindow("Separator Test", 200, 200)
  let horizontalSeparator = newHorizontalSeparator()
  let verticalSeparator {.used.} = newVerticalSeparator()

  # tests
  # ?
  
  # teardown
  window.child = horizontalSeparator
  show window

  mainSteps()
  mainStep(1)

  uing.quit()
  