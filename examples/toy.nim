# Test & show the new high level wrapper

import uing

proc main*() =
  var mainwin: Window

  var menu = newMenu("File")

  menu.addItem("Open", proc(_: MenuItem, win: Window) =
    let filename = win.openFile()

    if filename.len == 0:
      win.error("No file selected", "Don't be alarmed!")
    else:
      win.msgBox("File selected", filename)
  )

  menu.addItem("Save", proc(_: MenuItem, win: Window) =
    let filename = win.saveFile()

    if filename.len == 0:
      win.error("No file selected", "Don't be alarmed!")
    else:
      win.msgBox("File selected (don't worry, it's still there)", filename)
  )
  
  menu.addQuitItem(
    proc(): bool =
      mainwin.destroy()
      return true
  )

  menu = newMenu("Edit")
  menu.addCheckItem("Checkable Item")
  menu.addSeparator()
  disable menu.addItem("Disabled Item")
  menu.addPreferencesItem()

  menu = newMenu("Help")
  menu.addItem("Help")
  menu.addAboutItem()

  mainwin = newWindow("libui-ng Control Gallery", 640, 480, true)
  mainwin.margined = true

  let box = newVerticalBox(true)
  mainwin.child = box

  let group = newGroup("Basic Controls", true)
  box.add group

  let inner = newVerticalBox(true)
  group.child = inner

  inner.add newButton("Button", proc(_: Button) = mainwin.error("Error", "Rotec"))

  show mainwin
  mainLoop()

init()
main()
