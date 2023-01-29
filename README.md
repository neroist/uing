# UIng
A fork of [ui](https://github.com/nim-lang/ui) that wraps [libui-ng](https://github.com/libui-ng/libui-ng) instead of the old and unmaintained [libui](https://github.com/andlabs/libui) library.


This package wraps the [libui-ng](https://github.com/libui-ng/libui-ng) C library. It
also provides a high-level Nim binding for it.

To get started, install using Nimble:

```bash
nimble install https://github.com/neroist/uing
```

or add it to your project's Nimble file:

```nim
requires "https://github.com/neroist/uing"
```

### Dependencies
- `gtk+-3.0`

Linux: `$ sudo apt-get install libgtk-3-dev`

OSX: `$ brew install gtk+3`


You should then be able to compile the sample code in the
[`examples/`](examples/)
directory successfully.

## Static vs. dynamic linking

This library installs the C sources for libui and statically compiles them
into your application.

Static compilation is the default behaviour, but if you would prefer to depend
on a DLL instead, pass the `-d:useLibUiDll` to the Nim compiler. You will
then need to bundle your application with a libui.dll, libui.dylib, or libui.so
for Windows, macOS, and Linux respectively.
