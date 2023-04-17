import std/unittest

import uing

suite "Test Window":
  # setup
  init()

  let window = newWindow("Window Test", 200, 200)
  let child = newGroup("Test")

  # tests
  test "Window can be set margined":
    window.margined = true

    window.margined = false

  test "Window can get margined":
    check not window.margined 

  test "Window can be set resizeable":
    window.resizeable = true

    window.resizeable = false

  test "Window can get resizeable":
    check not window.resizeable 

  test "Window can be set borderless":
    window.borderless = true

    window.borderless = false

  test "Window can get borderless":
    check not window.borderless 

  test "Window can get focused":
    #check window.focused
    discard

  test "Window can be set fullscreen":
    window.fullscreen = true

    window.fullscreen = false

  test "Window can get fullscreen":
    check not window.fullscreen

  test "Window can set content size":
    window.contentSize = (400, 400)

  test "Window can get content size":
    check window.contentSize == (400, 400) 

  test "Window can set title":
    window.title = "Window Test Test"

  test "Window can get title":
    check window.title == "Window Test Test"

  test "Window can set position":
    window.position = (0, 0)

  test "Window can get position":
    check window.position == (0, 0)

  test "Window can set child":
    window.child = child
   
  test "Window can get child":
    let winChild = window.child

    #? Should be the same?
    check winChild.signature == child.signature

  # * dialogs are blocking, not tested

  # teardown
  show window

  mainSteps()
  mainStep(1)

  uing.quit()
  