import std/times

import uing

proc main = 
  let window = newWindow("Date / Time", 320, 240)
  window.margined = true

  let grid = newGrid(true)
  window.child = grid

  let
    dateTimeLabel = newLabel()
    dateLabel = newLabel()
    timeLabel = newLabel()

    dateTimePicker = newDateTimePicker() do (dt: DateTimePicker):
      dateTimeLabel.text = dt.time.format("ddd MMM d HH:mm:ss UUUU")

    datePicker = newDatePicker() do (dt: DateTimePicker):
      dateLabel.text = dt.time.format("yyyy-MM-dd")

    timePicker = newTimePicker() do (dt: DateTimePicker):
      timeLabel.text = dt.time.format("hh:mm:ss")

    nowButton = newButton("Now") do (_: Button): 
      timePicker.time = now()
      datePicker.time = now()

    epochButton = newButton("Unix epoch") do (_: Button):
      dateTimePicker.time = dateTime(1969, mDec, 31, 19)

  grid.add(dateTimePicker, 0, 0, 2, 1, true, AlignFill, false, AlignFill)
  grid.add(datePicker, 0, 1, 1, 1, true, AlignFill, false, AlignFill)
  grid.add(timePicker, 1, 1, 1, 1, true, AlignFill, false, AlignFill)

  grid.add(dateTimeLabel, 0, 2, 2, 1, true, AlignCenter, false, AlignFill)
  grid.add(dateLabel, 0, 3, 1, 1, true, AlignCenter, false, AlignFill)
  grid.add(timeLabel, 1, 3, 1, 1, true, AlignCenter, false, AlignFill)
  
  grid.add(nowButton, 0, 4, 1, 1, true, AlignFill, true, AlignEnd)
  grid.add(epochButton, 1, 4, 1, 1, true, AlignFill, true, AlignEnd)

  show window
  mainLoop()

init()
main()
