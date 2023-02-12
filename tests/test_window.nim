import std/unittest

import uing

suite "Test Window":
  # setup
  init()

  let window = newWindow("Window Test", 200, 200)

  # tests
  test "Window can be set margined":
    window.margined = true
    check window.margined 

    window.margined = false
    check not window.margined 

  test "Window can set child":
    window.child = newGroup("Test")
  
  # teardown
  show window

  mainSteps()
  mainStep(1)

  uing.quit()
  