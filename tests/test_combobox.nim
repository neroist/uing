import std/unittest

import uing

suite "Test ComboBox":
  # setup
  init()

  let window = newWindow("ComboBox Test", 200, 200)
  let combobox = newComboBox()

  # tests
  test "ComboBox can add items":
    combobox.add "test1", "test2", "test3"
    check combobox.items.len == 3
    check combobox.items == @["test1", "test2", "test3"]

  test "ComboBox can insert items":
    combobox.insertAt 1, "test_inserted"
    check combobox.items.len == 4
    check combobox.items == @["test1", "test_inserted", "test2", "test3"]

  test "ComboBox can delete items":
    combobox.delete 1
    check combobox.items.len == 3

  test "ComboBox can clear items":
    combobox.clear()
    check combobox.items.len == 0

  test "ComboBox can set selected":
    combobox.add "test1"
    combobox.selected = 0
    check combobox.selected == 0

  # teardown
  window.child = combobox
  show window

  mainSteps()
  discard mainStep(1)

  uing.quit()
    