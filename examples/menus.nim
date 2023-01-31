import std/sugar

import uing

proc main = 
  var 
    window: Window
    enb: MenuItem
    about: MenuItem

  let fileMenu = newMenu("File")
  fileMenu.addItem("New")
  fileMenu.addItem("Open", (_: MenuItem, win: Window) => (discard win.openFile()))
  fileMenu.addSeparator()
  fileMenu.addCheckItem("Should Quit")
  let quitItem = fileMenu.addQuitItem(
    proc: bool {.closure.} =
      window.destroy()
      return true
  )

  let editMenu = newMenu("Edit")
  disable editMenu.addItem("Undo")
  editMenu.addSeparator()
  let checkMe = editMenu.addCheckItem("Check Me\tTest")
  editMenu.addItem("A&ccele&&rator T_es__t")
  let preferences = editMenu.addPreferencesItem()

  let testMenu = newMenu("Test")
  let enable = testMenu.addCheckItem(
    "Enable Below item", 
    proc (s: MenuItem, _: Window) = 
      if s.checked: enable enb
      else: disable enb
  )
  enable.checked = true
  enb = testMenu.addCheckItem("This Will Be Enabled")
  testMenu.addItem("Force Above Checked", (_: MenuItem, win: Window) => (enable.checked = true))
  testMenu.addItem("Force Above Unchecked", (_: MenuItem, win: Window) => (enable.checked = false))
  testMenu.addSeparator()
  testMenu.addItem("What Window?", (s: MenuItem, _: Window) => (echo "menu item clicked on window"))
  let resize = testMenu.addCheckItem("Enable Resize", (s: MenuItem, win: Window) => (window.resizeable = s.checked))
  resize.checked = true

  let moreTestsMenu = newMenu("More Tests")
  moreTestsMenu.addCheckItem(
    "Quit Item Enabled",
    proc (s: MenuItem, _: Window) =
      if s.checked: enable quitItem
      else: disable quitItem
  ).checked = true
  moreTestsMenu.addCheckItem(
    "Preferences Item Enabled",
    proc (s: MenuItem, _: Window) =
      if s.checked: enable preferences
      else: disable preferences
  ).checked = true
  moreTestsMenu.addCheckItem(
    "About Item Enabled",
    proc (s: MenuItem, _: Window) =
      if s.checked: enable about
      else: disable about
  ).checked = true
  moreTestsMenu.addSeparator()
  moreTestsMenu.addCheckItem(
    "Check Me Item Enabled",
    proc (s: MenuItem, _: Window) =
      if s.checked: enable checkMe
      else: disable checkMe
  ).checked = true

  let multiMenu = newMenu("Multi")
  multiMenu.addSeparator()
  multiMenu.addSeparator()
  multiMenu.addItem("Item && Item && Item")
  multiMenu.addSeparator()
  multiMenu.addSeparator()
  multiMenu.addItem("Item __ Item __ Item")
  multiMenu.addSeparator()
  multiMenu.addSeparator()

  let helpMenu = newMenu("Help")
  helpMenu.addItem("Help")
  about = helpMenu.addAboutItem()

  window = newWindow("Using the Menubar", 320, 240, true)

  show window
  mainLoop()


when isMainModule:
  init()
  main()