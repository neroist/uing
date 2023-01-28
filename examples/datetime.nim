import std/[sugar, times]

import uing

proc main = 
  let window = newWindow("Date / Time", 320, 240)
  window.margined = true

  let grid = newGrid()
  grid.padded = true
  window.child = grid

  let
    dateTimeLabel = newLabel()
    dateLabel = newLabel()
    timeLabel = newLabel()

    dateTimePicker = newDateTimePicker((dt: DateTimePicker) => (dateTimeLabel.text = dt.time.format("ddd MMM d HH:mm:ss UUUU")))
    datePicker = newDatePicker((dt: DateTimePicker) => (dateLabel.text = dt.time.format("yyyy-MM-dd")))
    timePicker = newTimePicker((dt: DateTimePicker) => (timeLabel.text = dt.time.format("hh:mm:ss")))

    nowButton = newButton("Now", (_: Button) => (timePicker.time = now(); datePicker.time = now()))
    epochButton = newButton("Unix epoch", (_: Button) => (dateTimePicker.time = dateTime(1969, mDec, 31, 19)))

  grid.add(dateTimePicker, 0, 0, 2, 1, true, AlignFill, false, AlignStart)
  grid.add(datePicker, 0, 1, 1, 1, true, AlignFill, false, AlignStart)
  grid.add(timePicker, 1, 1, 1, 1, true, AlignFill, false, AlignStart)

  grid.add(dateTimeLabel, 0, 2, 2, 1, true, AlignCenter, false, AlignCenter)
  grid.add(dateLabel, 0, 3, 1, 1, true, AlignCenter, false, AlignCenter)
  grid.add(timeLabel, 1, 3, 1, 1, true, AlignCenter, false, AlignCenter)
  
  grid.add(nowButton, 0, 4, 1, 1, true, AlignFill, true, AlignEnd)
  grid.add(epochButton, 1, 4, 1, 1, true, AlignFill, true, AlignEnd)

  show window
  mainLoop()

when isMainModule:
  init()
  main()
