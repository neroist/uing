import std/unittest

import uing

var window: Window

suite "Test Menu":
  # setup
  init()

  let menu = newMenu("Test")
  
  # tests
  test "Menu can add item":
    discard menu.addItem("Test Item")

  test "Menu can add check item":
    discard menu.addCheckItem("Test Check item")

  test "Menu can add quit item":
    menu.addQuitItem(
      proc(): bool = 
        destroy window
        return true
    )

  test "Menu can add about item":
    menu.addPreferencesItem()

  test "Menu can add about item":
    menu.addAboutItem()

  test "Menu children seq length":
    check menu.children.len == 5
  
  # teardown
  window = newWindow("Menu Test", 200, 200, true)
  show window

  mainSteps()
  discard mainStep(1)

  uing.quit()
  