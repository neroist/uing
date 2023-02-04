import std/unittest

import uing

suite "Test EditableCombobox":
  # setup
  init()

  let window = newWindow("EditableCombobox Test", 200, 200)
  let editableCombobox = newEditableCombobox()

  # tests
  test "EditableCombobox can add items":
    editableCombobox.add "test1", "test2", "test3"
    check editableCombobox.items.len == 3
    check editableCombobox.items == @["test1", "test2", "test3"]

  test "EditableCombobox text":
    editableCombobox.text = "test1"
    check editableCombobox.text == "test1"

  test "EditableCombobox can clear text":
    editableCombobox.clear()
    check editableCombobox.text == ""

  # teardown
  window.child = editableCombobox
  show window

  mainSteps()
  discard mainStep(1)

  uing.quit()
    