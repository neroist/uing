import std/unittest
import std/times

import uing

suite "Test DateTimePicker":
  # setup
  init()

  let window = newWindow("DateTimePicker Test", 200, 200)
  let dateTimePicker = newDateTimePicker()
  let time = dateTime(2023, mFeb, 4)

  # tests
  test "DateTimePicker can set time":
    dateTimePicker.time = time

  test "DateTimePicker can get time":
    let dtTime = dateTimePicker.time

    check dtTime.year == 2023
    check dtTime.month == mFeb
    check dtTime.monthday == 4
  
  # teardown
  window.child = dateTimePicker
  show window

  mainSteps()
  mainStep(1)

  uing.quit()

suite "Test TimePicker":
  # setup
  # init() libui-ng already initialized

  let window = newWindow("DatePicker Test", 200, 200)
  let timePicker = newTimePicker()
  let time = dateTime(2023, mMar, 7, 23, 46, 10)

  # tests
  test "TimePicker can set time":
    timePicker.time = time

  test "TimePicker can get time":
    let dtTime = timePicker.time

    check dtTime.hour == 23
    check dtTime.minute == 46
    check dtTime.second == 10

  # teardown
  window.child = timePicker
  show window

  mainSteps()
  mainStep(1)

  uing.quit()

suite "Test DatePicker":
  # setup
  # init() libui-ng already initialized

  let window = newWindow("DatePicker Test", 200, 200)
  let datePicker = newDatePicker()
  let time = dateTime(2023, mMar, 7)

  # tests
  test "DatePicker can set time":
    datePicker.time = time

  test "DatePicker can get time":
    let dtTime = datePicker.time

    check dtTime.year == 2023
    check dtTime.month == mMar
    check dtTime.monthday == 7

  # teardown
  window.child = datePicker
  show window

  mainSteps()
  mainStep(1)

  uing.quit()
