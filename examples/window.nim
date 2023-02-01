import uing

proc main =
  let window = newWindow("Window Title", 300, 30)

  show window
  mainLoop()

when isMainModule:
  init()
  main()
  