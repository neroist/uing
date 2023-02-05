# UIng

### [**Documentation**](https://neroist.github.io/uing/uing.html)

A fork of [ui](https://github.com/nim-lang/ui) that wraps
[libui-ng](https://github.com/libui-ng/libui-ng) instead of the old and unmaintained
[libui](https://github.com/andlabs/libui) library. It
also provides a high-level Nim binding for it.

To get started, install using Nimble:

```bash
nimble install uing
```

or add it to your project's Nimble file:

```nim
requires "uing"
```

## Runtime Requirements

* Windows: Windows Vista SP2 with Platform Update or newer
* Unix: GTK+ 3.10 or newer
* Mac OS X: OS X 10.8 or newer

## Dependencies

- `gtk+-3.0`

Linux: `$ sudo apt-get install libgtk-3-dev`

You should then be able to compile the sample code in the
[`examples/`](examples/)
directory and run the [tests](tests/) successfully.

## Static vs. dynamic linking

This library installs the C sources for libui-ng and statically compiles them
into your application.

Static compilation is the default behaviour, but if you would prefer to depend
on a DLL instead, pass the `-d:useLibUiDll` to the Nim compiler. You will
then need to bundle your application with a `libui.dll`, `libui.dylib`, or `libui.so`
for Windows, macOS, and Linux respectively.
Build instructions and requirements can be found in [libui-ng's README](https://github.com/libui-ng/libui-ng#readme)

In addition, if you would rather want to compile with a static library, pass
`-d:useLibUiStaticLib` to the Nim compiler instead. You will then need a `libui.lib` for Windows and a `libui.a` for other platforms. Again, Build instructions
and requirements can be found in [libui-ng's README](https://github.com/libui-ng/libui-ng#readme)

Static and dynamic libraries (e.g. `libui.so`, `libui.lib`) can be found in the
[releases page](https://github.com/neroist/uing/releases/latest)

###### Made with ❤️ with Nim
