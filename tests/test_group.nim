import std/unittest

import uing

suite "Test Group":
  # setup
  init()

  let window = newWindow("Group Test", 200, 200)
  let group = newGroup("Test Group")

  # tests
  test "Group can set title":
    group.title = "Test Group Title"
    check group.title == "Test Group Title"

  test "Group can set child":
    group.child = newDatePicker()

  test "Group can remove child":
    group.child = nil
    check group.child == nil

  test "Group can set margined":
    group.margined = true
    check group.margined

    group.margined = false
    check not group.margined
  
  # teardown
  window.child = group
  show window

  mainSteps()
  discard mainStep(1)

  uing.quit()
    