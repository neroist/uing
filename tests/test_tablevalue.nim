import std/unittest

import uing

suite "Test TableValue":
  # setup
  init()

  let window = newWindow("TableValue Test", 200, 200)
  let str = newTableValue("Test")
  let num = newTableValue(4)
  let color = newTableValue(0.004, 0.365, 0.322)
  # TODO image

  # tests
  test "TableValue string":
    check $str == "Test"
    
    expect ValueError:
      discard $num

  test "TableValue int":
    check num.getInt() == 4
    
    expect ValueError:
      discard str.getInt()

  test "TableValue color":
    check color.color == (0.004, 0.365, 0.322, 1.0)
    
    expect ValueError:
      discard str.color
  
  # teardown
  show window

  mainSteps()
  discard mainStep(1)

  uing.quit()
  