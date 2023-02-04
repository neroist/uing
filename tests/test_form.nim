import std/unittest

import uing

suite "Test Form":
  # setup
  init()

  let window = newWindow("Form Test", 200, 200)
  let form = newForm()

  # tests
  test "Form can add children":
    form.add "test1", newEntry()
    check form.chlidren.len == 1

  test "Form can delete children":
    form.delete 0
    check form.chlidren.len == 0

  test "Form can be set padded":
    form.padded = true
    check form.padded

    form.padded = false
    check not form.padded

  # teardown
  window.child = form
  show window

  mainSteps()
  discard mainStep(1)

  uing.quit()
    