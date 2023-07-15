# Notepad example - utxt (https://github.com/neroist/utxt)

import std/os

import uing

var 
  file = try: paramStr(1)
         except: ""
  showFullPath: bool
  entry: MultilineEntry

proc getFilename(): string = 
  result = file

  if result != "":
    result = if showFullPath:
      file.expandFilename()
    else:
      file.extractFilename()

proc saveAs(_: MenuItem, win: Window) = 
  let filename = win.saveFile()

  if filename == "":
    return

  writeFile(filename, entry.text)

  win.title = getFilename()

proc save(m: MenuItem, win: Window) = 
  if file != "":
    writeFile(file, entry.text)
  else:
    saveAs(m, win)

proc open(_: MenuItem, win: Window) =
  let filename = win.openFile()

  if filename == "":
    return
  
  file = filename
  win.title = getFilename()
  entry.text = readFile file

proc new(_: MenuItem, win: Window) =
  let filename = win.saveFile()

  if filename == "":
    return
  
  file = filename
  win.title = getFilename()
  entry.text = "" 

proc showFullFilePath(item: MenuItem, win: Window) = 
  showFullPath = item.checked
  win.title = getFilename()

proc wrapText(item: MenuItem, win: Window) = 
  let text = entry.text

  if item.checked:
    entry = newMultilineEntry()
    entry.text = text
    win.child = entry
  else:
    entry = newNonWrappingMultilineEntry()
    entry.text = text
    win.child = entry

  
proc main = 
  var window: Window

  let fileMenu = newMenu("File")
  fileMenu.addItem("New", new)
  fileMenu.addItem("Open", open)
  fileMenu.addItem("Save", save)
  fileMenu.addItem("Save As", saveAs)
  fileMenu.addQuitItem(
    proc: bool =
      window.destroy()
      return true
  )

  let windowMenu = newMenu("Window")
  windowMenu.addCheckItem("Show Full File Path", showFullFilePath)
  windowMenu.addCheckItem("Wrap Text", wrapText)

  window = newWindow(getFilename(), 800, 600, true)

  if not file.fileExists() and file != "":
    # create file
    writeFile(file, "")

    window.msgBox("Created File", "Created file " & file)

  entry = newNonWrappingMultilineEntry()
  if file != "": entry.text = readFile file
  window.child = entry

  show window
  mainLoop()

when isMainModule:
  init()
  main()
