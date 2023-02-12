import std/unittest

import uing

suite "Test Spinbox":
  # setup
  init()

  let window = newWindow("Spinbox Test", 200, 200)
  let spinbox = newSpinbox(0..100)

  # tests
  test "Spinbox can set value":
    spinbox.value = 6
    check spinbox.value == 6
  
  # teardown
  window.child = spinbox
  show window

  mainSteps()
  mainStep(1)

  uing.quit()
  