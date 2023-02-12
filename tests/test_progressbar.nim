import std/unittest

import uing

suite "Test ProgressBar":
  # setup
  init()

  let window = newWindow("ProgressBar Test", 200, 200)
  let progressBar = newProgressBar()

  # tests
  test "ProgressBar can set value":
    progressBar.value = 51
    check progressBar.value == 51

  test "ProgressBar can be set indeterminate":
    progressBar.value = -1
    check progressBar.value == -1
  
  # teardown
  window.child = progressBar
  show window

  mainSteps()
  mainStep(1)

  uing.quit()
  