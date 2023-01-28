import uing

proc main = 
  let window = newWindow("Hello World!", 300, 25)
  let label = newLabel("Hello, World!")

  window.child = label

  show window
  mainLoop()

when isMainModule:
  init()
  main()