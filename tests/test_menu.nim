import std/unittest

import uing

var window: Window

suite "Test Menu":
  # setup
  init()

  let menu = newMenu("Test")
  
  # tests
  test "Menu can add item":
    menu.addItem("Test Item")

  test "Menu can add check item":
    menu.addCheckItem("Test Check item")

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

  test "Menu can add separator":
    menu.addSeparator()

  test "Menu children seq length":
    check menu.children.len == 5
  
  # teardown
  window = newWindow("Menu Test", 200, 200, true)
  show window

  mainSteps()
  mainStep(1)

  uing.quit()
  