import std/unittest

import uing

suite "Test Grid":
  # setup
  init()

  let window = newWindow("Grid Test", 200, 200)
  let grid = newGrid()
  let widget = newLabel("test1")

  # tests
  test "Grid can add items":
    grid.add(widget, 0, 0, 1, 1, true, AlignCenter, true, AlignCenter)

  test "Grid can insert at":
    grid.insertAt(newLabel("test2"), widget, AtBottom, 1, 1, 1, 1, true, AlignCenter, true, AlignCenter)

  test "Grid can set padded":
    grid.padded = true
    check grid.padded

    grid.padded = false
    check not grid.padded

  # teardown
  window.child = grid
  show window

  mainSteps()
  discard mainStep(1)

  uing.quit()
    