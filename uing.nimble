# Package

version       = "0.8.2"
author        = "Jasmine"
description   = "Wrapper for libui-ng, a maintained fork of libui."
license       = "MIT"
installDirs   = @["uing", "res"]
installFiles  = @["uing.nim"]

# Dependencies

requires "nim >= 1.2.0"

# Tasks

task mkdocs, "Build the documentation for uing.":
  exec"nimble doc --outDir:docs --project uing.nim"
  exec"nimble doc --outDir:docs/uing uing/genui"
