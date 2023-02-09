import std/unittest

import uing

suite "Test Widget Generics":
  # setup
  init()

  let window = newWindow("Widget Test", 200, 200)
  let button = newButton("")

  # tests
  test "Widget can be hidden":
    hide button

  test "Widget can be shown":
    show button

  test "Widget can be disabled":
    disable button
    check button.enabled == false

  test "Widget can be enabled":
    enable button

  test "Widget can set parent":
    button.parent = window

  test "Widget can be detached":
    button.parent = nil

  test "Widget can get handle":
    discard button.handle

  test "Widget can get signature":
    discard button.signature

  test "Widget can get type signature":
    discard button.typeSignature

  test "Widget can get OS signature":
    discard button.osSignature

  test "Widget can get is top level":
    check button.topLevel == false # remember, we detached the widget

  test "Widget can get is visible":
    check button.visible == true

  test "Widget can verify if parent can be set":
    button.verifySetParent(button)

  test "Widget can get is enabled to users":
    check button.enabledToUser == true

  # teardown
  window.child = button
  show window

  mainSteps()
  discard mainStep(1)

  uing.quit()
    