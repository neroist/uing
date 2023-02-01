import std/sugar
import std/times

import uing

var entry: MultilineEntry

proc sayTime(): bool = 
  entry.add now().format("ddd MMM d HH:mm:ss UUUU") & '\n'

  return true

proc main =
  let window = newWindow("Hello", 320, 240)
  window.margined = true

  let vbox = newVerticalBox(true)
  window.child = vbox

  let btn = newButton("Say Something", (_: Button) => entry.add "Saying something\n")
  vbox.add btn

  entry = newMultilineEntry()
  entry.readonly = true
  vbox.add entry, true

  timer(1000, sayTime)

  show window
  mainLoop()

when isMainModule:
  init()
  main()
  