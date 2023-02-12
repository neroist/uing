import std/unittest

import uing

suite "Test Slider":
  # setup
  init()

  let window = newWindow("Slider Test", 200, 200)
  let slider = newSlider(0..100)

  # tests
  test "Slider can set value":
    slider.value = 5
    check slider.value == 5

  test "Slider can set has tool tip":
    slider.hasToolTip = true
    check slider.hasToolTip

    slider.hasToolTip = false
    check not slider.hasToolTip

  test "Slider can set range":
    slider.range = 0..200
  
  # teardown
  window.child = slider
  show window

  mainSteps()
  mainStep(1)

  uing.quit()
  