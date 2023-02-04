import std/unittest
import std/times

import uing

suite "Test Box":
  # setup
  init()

  let window = newWindow("DateTimePicker Test", 200, 200)
  let dateTimePicker = newDateTimePicker()

  # tests
  test "DateTimePicker time":
    dateTimePicker.time = dateTime(2023, mFeb, 4)
    let dtTime = dateTimePicker.time

    check dtTime.year == 2023
    check dtTime.month == mFeb
    check dtTime.monthday == 4

  # teardown
  window.child = dateTimePicker
  show window

  mainSteps()
  discard mainStep(1)

  uing.quit()
    