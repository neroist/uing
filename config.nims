# Documentation config

when getCommand() == "doc":
  --git.url:"https://github.com/neroist/uing"
  --git.devel:main
  --git.commit:main

  # generate doc for genui aswell
  # error-prone but works
  switch("import", "uing/genui")
  
  --outDir:docs
  --project
  