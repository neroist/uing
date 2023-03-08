import std/unittest

import uing

suite "Test Tab":
  # setup
  init()

  let window = newWindow("Slider Test", 200, 200)
  let tab = newTab()

  # tests
  test "Tab can add widget":
    tab.add "Test1", newLabel("Test Widget")
    tab.add "Test2", newLabel("Test Widget")
    check tab.tabs.len == 2

  test "Tab can insert widget":
    tab.insertAt "Test0", 0, newLabel("Test Widget")
    check tab.tabs.len == 3

  test "Tab can delete tab":
    tab.delete 0
    check tab.tabs.len == 2

  test "Tab can set tab margined":
    tab.setMargined(0, true)

    tab.setMargined(0, false)

  test "Tab can get tab margined":
    check not tab.margined(0)

  test "Tab can set all tabs margined":
    tab.setAllTabsMargined(true)

  # teardown
  window.child = tab
  show window

  mainSteps()
  mainStep(1)

  uing.quit()
  