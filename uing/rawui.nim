## Low level wrapper for libui-ng. 
## 
## Documentation mainly from `ui.h <https://github.com/libui-ng/libui-ng/blob/master/ui.h>`_
## 
## Documentation is only added when neccessary, see `ui.h <https://github.com/libui-ng/libui-ng/blob/master/ui.h>`_
## for documentation
## 
## :Author: Jasmine

when defined(useLibUiDll):
  when defined(windows):
    const
      dllName* = "libui.dll"
  elif defined(macosx):
    const
      dllName* = "libui.dylib"
  else:
    const
      dllName* = "libui.so(|.0)"

  {.pragma: libui, dynlib: dllName.}

elif defined(useLibUiStaticLib):
  when defined(windows):
    const libName* = "libui.lib"
  else:
    const libName* = "libui.a"

  {.passL: libname.}
  {.pragma: libui.}

else:
  {.pragma: libui.}

  when defined(linux):
    from strutils import replace

    const 
      cflags = (staticExec"pkg-config --cflags gtk+-3.0").replace('\L', ' ')
      lflags = (staticExec"pkg-config --libs gtk+-3.0").replace('\L', ' ')

    {.passC: cflags.}
    {.passL: lflags.}

    # add missing linking flags
    when defined(posix) and not defined(genode):
      {.passL: "-lm".}

  {.compile: ("./libui/common/*.c", "common_$#.obj").}

  when defined(windows):
    {.compile: ("./libui/windows/*.cpp", "win_$#.obj").}
    
  elif defined(macosx):
    {.compile: ("./libui/darwin/*.m", "osx_$#.obj").}

    {.passL: "-framework OpenGL".}
    {.passL: "-framework CoreAudio".}
    {.passL: "-framework AudioToolbox".}
    {.passL: "-framework AudioUnit".}
    {.passL: "-framework Carbon".}
    {.passL: "-framework IOKit".}
    {.passL: "-framework Cocoa".}

  else:
    {.compile: ("./libui/unix/*.c", "unix_$#.obj").}

  when defined(windows):
    when defined(gcc):
      {.passL: "-lstdc++".} # gives warnings when passed to linker with clang 

    when defined(clang) or defined(gcc):
      {.passL: "-lwindowscodecs".} # compiling with clang needs this for some reason
      {.passL: "-lwinspool".}
      {.passL: "-lcomdlg32".}
      {.passL: "-ladvapi32".}
      {.passL: "-lshell32".}
      {.passL: "-lole32".}
      {.passL: "-loleaut32".}

      {.passL: "-luuid".}
      {.passL: "-lcomctl32".}
      {.passL: "-ld2d1".}
      {.passL: "-ldwrite".}
      {.passL: "-luxTheme".}
      {.passL: "-lusp10".}
      {.passL: "-lgdi32".}
      {.passL: "-luser32".}
      {.passL: "-lkernel32".}

    when defined(cpu64):
      {.link: "../res/resources.o".} # resources.o is 64-bit
      {.link: "../res/winim64.res".}
    else:
      {.link: "../res/winim32.res".}

  when defined(vcc):
    {.passC: "/EHsc".}
    {.passC: "/wd4312".} # disable warning: 'type cast': conversion from 'int' to 'HMENU' of greater size
 
    {.link: "windowscodecs.lib".}
    {.link: "kernel32.lib".}
    {.link: "user32.lib".}
    {.link: "gdi32.lib".}
    {.link: "winspool.lib".}
    {.link: "comdlg32.lib".}
    {.link: "advapi32.lib".}
    {.link: "shell32.lib".}
    {.link: "ole32.lib".}
    {.link: "oleaut32.lib".}
    {.link: "uuid.lib".}
    {.link: "comctl32.lib".}

    {.link: "d2d1.lib".}
    {.link: "dwrite.lib".}
    {.link: "UxTheme.lib".}
    {.link: "Usp10.lib".}

    {.link: "../res/resources.res".}
    {.link: "../res/winimvcc.res".}

type
  ForEach* {.size: sizeof(cint).} = enum
    ## ForEach represents the return value from one of libui-ng's various ForEach functions.

    ForEachContinue,
    ForEachStop,

  InitOptions* {.bycopy.} = object
    size*: csize_t

when NimMajor < 2:
  {.deadCodeElim: on.}

proc init*(options: ptr InitOptions): cstring {.cdecl, importc: "uiInit", libui.}
proc uninit*() {.cdecl, importc: "uiUninit", libui.}
proc freeInitError*(err: cstring) {.cdecl, importc: "uiFreeInitError", libui.}
proc main*() {.cdecl, importc: "uiMain", libui.}
proc mainSteps*() {.cdecl, importc: "uiMainSteps", libui.}
proc mainStep*(wait: cint): cint {.cdecl, importc: "uiMainStep", libui.}
proc quit*() {.cdecl, importc: "uiQuit", libui.}
proc queueMain*(f: proc (data: pointer) {.cdecl.}; data: pointer) {.cdecl,importc: "uiQueueMain", libui.}

proc timer*(milliseconds: cint; f: proc (data: pointer): cint {.cdecl.}; data: pointer) {.
    cdecl, importc: "uiTimer", libui.}
proc onShouldQuit*(f: proc (data: pointer): cint {.cdecl.}; data: pointer) {.cdecl,
    importc: "uiOnShouldQuit", libui.}
proc freeText*(text: cstring) {.cdecl, importc: "uiFreeText", libui.}

type
  Control* {.inheritable, pure, bycopy.} = object 
    ## Base class for GUI controls providing common methods.
    
    signature*      : uint32
    osSignature*    : uint32
    typeSignature*  : uint32
    destroy*        : proc (a1: ptr Control) {.cdecl.}
    handle*         : proc (a1: ptr Control): int {.cdecl.}
    parent*         : proc (a1: ptr Control): ptr Control {.cdecl.}
    setParent*      : proc (a1: ptr Control; a2: ptr Control) {.cdecl.}
    toplevel*       : proc (a1: ptr Control): cint {.cdecl.}
    visible*        : proc (a1: ptr Control): cint {.cdecl.}
    show*           : proc (a1: ptr Control) {.cdecl.}
    hide*           : proc (a1: ptr Control) {.cdecl.}
    enabled*        : proc (a1: ptr Control): cint {.cdecl.}
    enable*         : proc (a1: ptr Control) {.cdecl.}
    disable*        : proc (a1: ptr Control) {.cdecl.}

template control*(this: untyped): untyped =
  (cast[ptr Control]((this)))

proc controlDestroy*(c: ptr Control) {.cdecl, importc: "uiControlDestroy",
                                   libui.}

proc controlHandle*(c: ptr Control): int {.cdecl, importc: "uiControlHandle",
                                      libui.}

proc controlParent*(c: ptr Control): ptr Control {.cdecl, importc: "uiControlParent",
    libui.}

proc controlSetParent*(c: ptr Control; parent: ptr Control) {.cdecl,
    importc: "uiControlSetParent", libui.}

proc controlToplevel*(c: ptr Control): cint {.cdecl, importc: "uiControlToplevel",
    libui.}

proc controlVisible*(c: ptr Control): cint {.cdecl, importc: "uiControlVisible",
                                        libui.}

proc controlShow*(c: ptr Control) {.cdecl, importc: "uiControlShow", libui.}

proc controlHide*(c: ptr Control) {.cdecl, importc: "uiControlHide", libui.}

proc controlEnabled*(c: ptr Control): cint {.cdecl, importc: "uiControlEnabled",
                                        libui.}

proc controlEnable*(c: ptr Control) {.cdecl, importc: "uiControlEnable",
                                  libui.}

proc controlDisable*(c: ptr Control) {.cdecl, importc: "uiControlDisable",
                                   libui.}

proc allocControl*(n: csize_t; oSsig: uint32; typesig: uint32; typenamestr: cstring): ptr Control {.
    cdecl, importc: "uiAllocControl", libui.}

proc freeControl*(c: ptr Control) {.cdecl, importc: "uiFreeControl", libui.}

proc controlVerifySetParent*(c: ptr Control; parent: ptr Control) {.cdecl,
    importc: "uiControlVerifySetParent", libui.}

proc controlEnabledToUser*(c: ptr Control): cint {.cdecl,
    importc: "uiControlEnabledToUser", libui.}

proc userBugCannotSetParentOnToplevel*(`type`: cstring) {.cdecl,
    importc: "uiUserBugCannotSetParentOnToplevel", libui.}

type
  Window* = object of Control

template window*(this: untyped): untyped =
  (cast[ptr Window]((this)))


proc windowTitle*(w: ptr Window): cstring {.cdecl, importc: "uiWindowTitle",
                                       libui.}

proc windowSetTitle*(w: ptr Window; title: cstring) {.cdecl,
    importc: "uiWindowSetTitle", libui.}

proc windowPosition*(w: ptr Window; x: ptr cint; y: ptr cint) {.cdecl, importc: "uiWindowPosition",
                                       libui.}

proc windowSetPosition*(w: ptr Window; x: cint; y: cint) {.cdecl,
    importc: "uiWindowSetPosition", libui.}

proc windowOnPositionChanged*(w: ptr Window; f: proc (sender: ptr Window;
    senderData: pointer) {.cdecl.}; data: pointer) {.cdecl,
    importc: "uiWindowOnPositionChanged", libui.}

proc windowContentSize*(w: ptr Window; width: ptr cint; height: ptr cint) {.cdecl,
    importc: "uiWindowContentSize", libui.}

proc windowSetContentSize*(w: ptr Window; width: cint; height: cint) {.cdecl,
    importc: "uiWindowSetContentSize", libui.}

proc windowFullscreen*(w: ptr Window): cint {.cdecl, importc: "uiWindowFullscreen",
    libui.}

proc windowSetFullscreen*(w: ptr Window; fullscreen: cint) {.cdecl,
    importc: "uiWindowSetFullscreen", libui.}

proc windowOnContentSizeChanged*(w: ptr Window; f: proc (sender: ptr Window;
    senderData: pointer) {.cdecl.}; data: pointer) {.cdecl,
    importc: "uiWindowOnContentSizeChanged", libui.}

proc windowOnClosing*(w: ptr Window; f: proc (sender: ptr Window; senderData: pointer): cint {.
    cdecl.}; data: pointer) {.cdecl, importc: "uiWindowOnClosing", libui.}

proc windowOnFocusChanged*(w: ptr Window; f: proc (sender: ptr Window;
    senderData: pointer) {.cdecl.}; data: pointer) {.cdecl,
    importc: "uiWindowOnFocusChanged", libui.}

proc windowFocused*(w: ptr Window): cint {.cdecl, importc: "uiWindowFocused",
                                      libui.}

proc windowBorderless*(w: ptr Window): cint {.cdecl, importc: "uiWindowBorderless",
    libui.}

proc windowSetBorderless*(w: ptr Window; borderless: cint) {.cdecl,
    importc: "uiWindowSetBorderless", libui.}

proc windowSetChild*(w: ptr Window; child: ptr Control) {.cdecl,
    importc: "uiWindowSetChild", libui.}

proc windowMargined*(w: ptr Window): cint {.cdecl, importc: "uiWindowMargined",
                                       libui.}

proc windowSetMargined*(w: ptr Window; margined: cint) {.cdecl,
    importc: "uiWindowSetMargined", libui.}

proc windowResizeable*(w: ptr Window): cint {.cdecl, importc: "uiWindowResizeable",
    libui.}

proc windowSetResizeable*(w: ptr Window; resizeable: cint) {.cdecl,
    importc: "uiWindowSetResizeable", libui.}

proc newWindow*(title: cstring; width: cint; height: cint; hasMenubar: cint): ptr Window {.
    cdecl, importc: "uiNewWindow", libui.}

type
  Button* = object of Control

template button*(this: untyped): untyped =
  (cast[ptr Button]((this)))


proc buttonText*(b: ptr Button): cstring {.cdecl, importc: "uiButtonText",
                                      libui.}

proc buttonSetText*(b: ptr Button; text: cstring) {.cdecl, importc: "uiButtonSetText",
    libui.}

proc buttonOnClicked*(b: ptr Button; f: proc (sender: ptr Button; senderData: pointer) {.
    cdecl.}; data: pointer) {.cdecl, importc: "uiButtonOnClicked", libui.}

proc newButton*(text: cstring): ptr Button {.cdecl, importc: "uiNewButton",
                                        libui.}

type
  Box* = object of Control

template box*(this: untyped): untyped =
  (cast[ptr Box]((this)))


proc boxAppend*(b: ptr Box; child: ptr Control; stretchy: cint) {.cdecl,
    importc: "uiBoxAppend", libui.}

proc boxNumChildren*(b: ptr Box): cint {.cdecl, importc: "uiBoxNumChildren",
                                    libui.}

proc boxDelete*(b: ptr Box; index: cint) {.cdecl, importc: "uiBoxDelete", libui.}

proc boxPadded*(b: ptr Box): cint {.cdecl, importc: "uiBoxPadded", libui.}

proc boxSetPadded*(b: ptr Box; padded: cint) {.cdecl, importc: "uiBoxSetPadded",
    libui.}

proc newHorizontalBox*(): ptr Box {.cdecl, importc: "uiNewHorizontalBox",
                                libui.}

proc newVerticalBox*(): ptr Box {.cdecl, importc: "uiNewVerticalBox", libui.}

type
  Checkbox* = object of Control

template checkbox*(this: untyped): untyped =
  (cast[ptr Checkbox]((this)))


proc checkboxText*(c: ptr Checkbox): cstring {.cdecl, importc: "uiCheckboxText",
    libui.}

proc checkboxSetText*(c: ptr Checkbox; text: cstring) {.cdecl,
    importc: "uiCheckboxSetText", libui.}

proc checkboxOnToggled*(c: ptr Checkbox; f: proc (sender: ptr Checkbox;
    senderData: pointer) {.cdecl.}; data: pointer) {.cdecl,
    importc: "uiCheckboxOnToggled", libui.}

proc checkboxChecked*(c: ptr Checkbox): cint {.cdecl, importc: "uiCheckboxChecked",
    libui.}

proc checkboxSetChecked*(c: ptr Checkbox; checked: cint) {.cdecl,
    importc: "uiCheckboxSetChecked", libui.}

proc newCheckbox*(text: cstring): ptr Checkbox {.cdecl, importc: "uiNewCheckbox",
    libui.}

type
  Entry* = object of Control

template entry*(this: untyped): untyped =
  (cast[ptr Entry]((this)))


proc entryText*(e: ptr Entry): cstring {.cdecl, importc: "uiEntryText", libui.}

proc entrySetText*(e: ptr Entry; text: cstring) {.cdecl, importc: "uiEntrySetText",
    libui.}

proc entryOnChanged*(e: ptr Entry;
                    f: proc (sender: ptr Entry; senderData: pointer) {.cdecl.};
                    data: pointer) {.cdecl, importc: "uiEntryOnChanged",
                                   libui.}

proc entryReadOnly*(e: ptr Entry): cint {.cdecl, importc: "uiEntryReadOnly",
                                     libui.}

proc entrySetReadOnly*(e: ptr Entry; readonly: cint) {.cdecl,
    importc: "uiEntrySetReadOnly", libui.}

proc newEntry*(): ptr Entry {.cdecl, importc: "uiNewEntry", libui.}

proc newPasswordEntry*(): ptr Entry {.cdecl, importc: "uiNewPasswordEntry",
                                  libui.}

proc newSearchEntry*(): ptr Entry {.cdecl, importc: "uiNewSearchEntry", libui.}

type
  Label* = object of Control

template label*(this: untyped): untyped =
  (cast[ptr Label]((this)))


proc labelText*(l: ptr Label): cstring {.cdecl, importc: "uiLabelText", libui.}

proc labelSetText*(l: ptr Label; text: cstring) {.cdecl, importc: "uiLabelSetText",
    libui.}

proc newLabel*(text: cstring): ptr Label {.cdecl, importc: "uiNewLabel", libui.}

type
  Tab* = object of Control

template tab*(this: untyped): untyped =
  (cast[ptr Tab]((this)))


proc tabAppend*(t: ptr Tab; name: cstring; c: ptr Control) {.cdecl,
    importc: "uiTabAppend", libui.}

proc tabInsertAt*(t: ptr Tab; name: cstring; index: cint; c: ptr Control) {.cdecl,
    importc: "uiTabInsertAt", libui.}

proc tabDelete*(t: ptr Tab; index: cint) {.cdecl, importc: "uiTabDelete", libui.}

proc tabNumPages*(t: ptr Tab): cint {.cdecl, importc: "uiTabNumPages", libui.}

proc tabMargined*(t: ptr Tab; index: cint): cint {.cdecl, importc: "uiTabMargined",
    libui.}

proc tabSetMargined*(t: ptr Tab; index: cint; margined: cint) {.cdecl,
    importc: "uiTabSetMargined", libui.}

proc newTab*(): ptr Tab {.cdecl, importc: "uiNewTab", libui.}

type
  Group* = object of Control

template group*(this: untyped): untyped =
  (cast[ptr Group]((this)))


proc groupTitle*(g: ptr Group): cstring {.cdecl, importc: "uiGroupTitle",
                                     libui.}

proc groupSetTitle*(g: ptr Group; title: cstring) {.cdecl, importc: "uiGroupSetTitle",
    libui.}

proc groupSetChild*(g: ptr Group; c: ptr Control) {.cdecl, importc: "uiGroupSetChild",
    libui.}

proc groupMargined*(g: ptr Group): cint {.cdecl, importc: "uiGroupMargined",
                                     libui.}

proc groupSetMargined*(g: ptr Group; margined: cint) {.cdecl,
    importc: "uiGroupSetMargined", libui.}

proc newGroup*(title: cstring): ptr Group {.cdecl, importc: "uiNewGroup",
                                       libui.}

type
  Spinbox* = object of Control

template spinbox*(this: untyped): untyped =
  (cast[ptr Spinbox]((this)))


proc spinboxValue*(s: ptr Spinbox): cint {.cdecl, importc: "uiSpinboxValue",
                                      libui.}

proc spinboxSetValue*(s: ptr Spinbox; value: cint) {.cdecl,
    importc: "uiSpinboxSetValue", libui.}

proc spinboxOnChanged*(s: ptr Spinbox; f: proc (sender: ptr Spinbox; senderData: pointer) {.
    cdecl.}; data: pointer) {.cdecl, importc: "uiSpinboxOnChanged", libui.}

proc newSpinbox*(min: cint; max: cint): ptr Spinbox {.cdecl, importc: "uiNewSpinbox",
    libui.}

type
  Slider* = object of Control

template slider*(this: untyped): untyped =
  (cast[ptr Slider]((this)))


proc sliderValue*(s: ptr Slider): cint {.cdecl, importc: "uiSliderValue",
                                    libui.}

proc sliderSetValue*(s: ptr Slider; value: cint) {.cdecl, importc: "uiSliderSetValue",
    libui.}

proc sliderHasToolTip*(s: ptr Slider): cint {.cdecl, importc: "uiSliderHasToolTip",
    libui.}

proc sliderSetHasToolTip*(s: ptr Slider; hasToolTip: cint) {.cdecl,
    importc: "uiSliderSetHasToolTip", libui.}

proc sliderOnChanged*(s: ptr Slider; f: proc (sender: ptr Slider; senderData: pointer) {.
    cdecl.}; data: pointer) {.cdecl, importc: "uiSliderOnChanged", libui.}

proc sliderOnReleased*(s: ptr Slider; f: proc (sender: ptr Slider; senderData: pointer) {.
    cdecl.}; data: pointer) {.cdecl, importc: "uiSliderOnReleased", libui.}

proc sliderSetRange*(s: ptr Slider; min: cint; max: cint) {.cdecl,
    importc: "uiSliderSetRange", libui.}

proc newSlider*(min: cint; max: cint): ptr Slider {.cdecl, importc: "uiNewSlider",
    libui.}

type
  ProgressBar* = object of Control

template progressBar*(this: untyped): untyped =
  (cast[ptr ProgressBar]((this)))


proc progressBarValue*(p: ptr ProgressBar): cint {.cdecl,
    importc: "uiProgressBarValue", libui.}

proc progressBarSetValue*(p: ptr ProgressBar; n: cint) {.cdecl,
    importc: "uiProgressBarSetValue", libui.}

proc newProgressBar*(): ptr ProgressBar {.cdecl, importc: "uiNewProgressBar",
                                      libui.}

type
  Separator* = object of Control

template separator*(this: untyped): untyped =
  (cast[ptr Separator]((this)))


proc newHorizontalSeparator*(): ptr Separator {.cdecl,
    importc: "uiNewHorizontalSeparator", libui.}

proc newVerticalSeparator*(): ptr Separator {.cdecl,
    importc: "uiNewVerticalSeparator", libui.}

type
  Combobox* = object of Control

template combobox*(this: untyped): untyped =
  (cast[ptr Combobox]((this)))


proc comboboxAppend*(c: ptr Combobox; text: cstring) {.cdecl,
    importc: "uiComboboxAppend", libui.}

proc comboboxInsertAt*(c: ptr Combobox; index: cint; text: cstring) {.cdecl,
    importc: "uiComboboxInsertAt", libui.}

proc comboboxDelete*(c: ptr Combobox; index: cint) {.cdecl,
    importc: "uiComboboxDelete", libui.}

proc comboboxClear*(c: ptr Combobox) {.cdecl, importc: "uiComboboxClear",
                                   libui.}

proc comboboxNumItems*(c: ptr Combobox): cint {.cdecl, importc: "uiComboboxNumItems",
    libui.}

proc comboboxSelected*(c: ptr Combobox): cint {.cdecl, importc: "uiComboboxSelected",
    libui.}

proc comboboxSetSelected*(c: ptr Combobox; index: cint) {.cdecl,
    importc: "uiComboboxSetSelected", libui.}

proc comboboxOnSelected*(c: ptr Combobox; f: proc (sender: ptr Combobox;
    senderData: pointer) {.cdecl.}; data: pointer) {.cdecl,
    importc: "uiComboboxOnSelected", libui.}

proc newCombobox*(): ptr Combobox {.cdecl, importc: "uiNewCombobox", libui.}

type
  EditableCombobox* = object of Control

template editableCombobox*(this: untyped): untyped =
  (cast[ptr EditableCombobox]((this)))


proc editableComboboxAppend*(c: ptr EditableCombobox; text: cstring) {.cdecl,
    importc: "uiEditableComboboxAppend", libui.}

proc editableComboboxText*(c: ptr EditableCombobox): cstring {.cdecl,
    importc: "uiEditableComboboxText", libui.}

proc editableComboboxSetText*(c: ptr EditableCombobox; text: cstring) {.cdecl,
    importc: "uiEditableComboboxSetText", libui.}

proc editableComboboxOnChanged*(c: ptr EditableCombobox; f: proc (
    sender: ptr EditableCombobox; senderData: pointer) {.cdecl.}; data: pointer) {.
    cdecl, importc: "uiEditableComboboxOnChanged", libui.}

proc newEditableCombobox*(): ptr EditableCombobox {.cdecl,
    importc: "uiNewEditableCombobox", libui.}

type
  RadioButtons* = object of Control

template radioButtons*(this: untyped): untyped =
  (cast[ptr RadioButtons]((this)))


proc radioButtonsAppend*(r: ptr RadioButtons; text: cstring) {.cdecl,
    importc: "uiRadioButtonsAppend", libui.}

proc radioButtonsSelected*(r: ptr RadioButtons): cint {.cdecl,
    importc: "uiRadioButtonsSelected", libui.}

proc radioButtonsSetSelected*(r: ptr RadioButtons; index: cint) {.cdecl,
    importc: "uiRadioButtonsSetSelected", libui.}

proc radioButtonsOnSelected*(r: ptr RadioButtons; f: proc (sender: ptr RadioButtons;
    senderData: pointer) {.cdecl.}; data: pointer) {.cdecl,
    importc: "uiRadioButtonsOnSelected", libui.}

proc newRadioButtons*(): ptr RadioButtons {.cdecl, importc: "uiNewRadioButtons",
                                        libui.}

type
  Tm* {.importc: "struct tm", header: "time.h", bycopy.} = object 
    tm_sec*   : cint ## seconds [0,61]
    tm_min*   : cint ## minutes [0,59]
    tm_hour*  : cint ## hour [0,23]
    tm_mday*  : cint ## day of month [1,31]
    tm_mon*   : cint ## month of year [0,11]
    tm_year*  : cint ## years since 1900
    tm_wday*  : cint ## day of week [0,6] (Sunday = 0)
    tm_yday*  : cint ## day of year [0,365]
    tm_isdst* : cint ## daylight savings flag

  DateTimePicker* = object of Control

template dateTimePicker*(this: untyped): untyped =
  (cast[ptr DateTimePicker]((this)))


proc dateTimePickerTime*(d: ptr DateTimePicker; time: ptr Tm) {.cdecl,
    importc: "uiDateTimePickerTime", libui.}

proc dateTimePickerSetTime*(d: ptr DateTimePicker; time: ptr Tm) {.cdecl,
    importc: "uiDateTimePickerSetTime", libui.}

proc dateTimePickerOnChanged*(d: ptr DateTimePicker; f: proc (
    sender: ptr DateTimePicker; senderData: pointer) {.cdecl.}; data: pointer) {.cdecl,
    importc: "uiDateTimePickerOnChanged", libui.}

proc newDateTimePicker*(): ptr DateTimePicker {.cdecl,
    importc: "uiNewDateTimePicker", libui.}

proc newDatePicker*(): ptr DateTimePicker {.cdecl, importc: "uiNewDatePicker",
                                        libui.}

proc newTimePicker*(): ptr DateTimePicker {.cdecl, importc: "uiNewTimePicker",
                                        libui.}

type
  MultilineEntry* = object of Control

template multilineEntry*(this: untyped): untyped =
  (cast[ptr MultilineEntry]((this)))


proc multilineEntryText*(e: ptr MultilineEntry): cstring {.cdecl,
    importc: "uiMultilineEntryText", libui.}

proc multilineEntrySetText*(e: ptr MultilineEntry; text: cstring) {.cdecl,
    importc: "uiMultilineEntrySetText", libui.}

proc multilineEntryAppend*(e: ptr MultilineEntry; text: cstring) {.cdecl,
    importc: "uiMultilineEntryAppend", libui.}

proc multilineEntryOnChanged*(e: ptr MultilineEntry; f: proc (
    sender: ptr MultilineEntry; senderData: pointer) {.cdecl.}; data: pointer) {.cdecl,
    importc: "uiMultilineEntryOnChanged", libui.}

proc multilineEntryReadOnly*(e: ptr MultilineEntry): cint {.cdecl,
    importc: "uiMultilineEntryReadOnly", libui.}

proc multilineEntrySetReadOnly*(e: ptr MultilineEntry; readonly: cint) {.cdecl,
    importc: "uiMultilineEntrySetReadOnly", libui.}

proc newMultilineEntry*(): ptr MultilineEntry {.cdecl,
    importc: "uiNewMultilineEntry", libui.}

proc newNonWrappingMultilineEntry*(): ptr MultilineEntry {.cdecl,
    importc: "uiNewNonWrappingMultilineEntry", libui.}

type
  MenuItem* = object of Control

template menuItem*(this: untyped): untyped =
  (cast[ptr MenuItem]((this)))


proc menuItemEnable*(m: ptr MenuItem) {.cdecl, importc: "uiMenuItemEnable",
                                    libui.}

proc menuItemDisable*(m: ptr MenuItem) {.cdecl, importc: "uiMenuItemDisable",
                                     libui.}

proc menuItemOnClicked*(m: ptr MenuItem; f: proc (sender: ptr MenuItem;
    window: ptr Window; senderData: pointer) {.cdecl.}; data: pointer) {.cdecl,
    importc: "uiMenuItemOnClicked", libui.}

proc menuItemChecked*(m: ptr MenuItem): cint {.cdecl, importc: "uiMenuItemChecked",
    libui.}

proc menuItemSetChecked*(m: ptr MenuItem; checked: cint) {.cdecl,
    importc: "uiMenuItemSetChecked", libui.}

type
  Menu* = object of Control

template menu*(this: untyped): untyped =
  (cast[ptr Menu]((this)))


proc menuAppendItem*(m: ptr Menu; name: cstring): ptr MenuItem {.cdecl,
    importc: "uiMenuAppendItem", libui.}

proc menuAppendCheckItem*(m: ptr Menu; name: cstring): ptr MenuItem {.cdecl,
    importc: "uiMenuAppendCheckItem", libui.}

proc menuAppendQuitItem*(m: ptr Menu): ptr MenuItem {.cdecl,
    importc: "uiMenuAppendQuitItem", libui.}

proc menuAppendPreferencesItem*(m: ptr Menu): ptr MenuItem {.cdecl,
    importc: "uiMenuAppendPreferencesItem", libui.}

proc menuAppendAboutItem*(m: ptr Menu): ptr MenuItem {.cdecl,
    importc: "uiMenuAppendAboutItem", libui.}

proc menuAppendSeparator*(m: ptr Menu) {.cdecl, importc: "uiMenuAppendSeparator",
                                     libui.}

proc newMenu*(name: cstring): ptr Menu {.cdecl, importc: "uiNewMenu", libui.}

proc openFile*(parent: ptr Window): cstring {.cdecl, importc: "uiOpenFile",
    libui.}

proc openFolder*(parent: ptr Window): cstring {.cdecl, importc: "uiOpenFolder",
    libui.}

proc saveFile*(parent: ptr Window): cstring {.cdecl, importc: "uiSaveFile",
    libui.}

proc msgBox*(parent: ptr Window; title: cstring; description: cstring) {.cdecl,
    importc: "uiMsgBox", libui.}

proc msgBoxError*(parent: ptr Window; title: cstring; description: cstring) {.cdecl,
    importc: "uiMsgBoxError", libui.}

type
  Area* = object of Control

  Modifiers* {. size: sizeof(cint) .} = enum
    ## Keyboard modifier keys. 
    ## 
    ## Usable as bitmasks.
    
    ModifierCtrl  = 1 shl 0, ## Control key.
    ModifierAlt   = 1 shl 1, ## Alternate/Option key.
    ModifierShift = 1 shl 2, ## Shift key.
    ModifierSuper = 1 shl 3, ## Super/Command/Windows key

  ExtKey* {. size: sizeof(cint) .} = enum
    ExtKeyEscape = 1, 
    ExtKeyInsert,  ## equivalent to "Help" on Apple keyboards 
    ExtKeyDelete, 
    ExtKeyHome, 
    ExtKeyEnd, 
    ExtKeyPageUp, 
    ExtKeyPageDown, 
    ExtKeyUp, 
    ExtKeyDown, 
    ExtKeyLeft, 
    ExtKeyRight, 
    ExtKeyF1,     ## F1..F12 are guaranteed to be consecutive
    ExtKeyF3, 
    ExtKeyF4, 
    ExtKeyF5, 
    ExtKeyF6, 
    ExtKeyF7, 
    ExtKeyF8, 
    ExtKeyF9, 
    ExtKeyF10, 
    ExtKeyF11, 
    ExtKeyF12, 
    ExtKeyN0,     ## numpad keys; independent of Num Lock state
    ExtKeyN1,     ## N0..N9 are guaranteed to be consecutive
    ExtKeyN2, 
    ExtKeyN3, 
    ExtKeyN4, 
    ExtKeyN5, 
    ExtKeyN6,
    ExtKeyN7, 
    ExtKeyN8, 
    ExtKeyN9, 
    ExtKeyNDot, 
    ExtKeyNEnter, 
    ExtKeyNAdd, 
    ExtKeyNSubtract, 
    ExtKeyNMultiply, 
    ExtKeyNDivide

  AreaDrawParams* {.bycopy.} = object
    context*   : ptr DrawContext
    areaWidth* : cdouble
    areaHeight*: cdouble
    clipX*     : cdouble
    clipY*     : cdouble
    clipWidth* : cdouble
    clipHeight*: cdouble

  AreaMouseEvent* {.bycopy.} = object
    x*         : cdouble
    y*         : cdouble
    areaWidth* : cdouble
    areaHeight*: cdouble
    down*      : cint
    up*        : cint
    count*     : cint
    modifiers* : Modifiers
    held1To64* : uint64

  AreaKeyEvent* {.bycopy.} = object
    key*       : char
    extKey*    : ExtKey
    modifier*  : Modifiers
    modifiers* : Modifiers
    up*        : cint

  DrawContext* = object

  AreaHandler* {.bycopy.} = object
    draw*         : proc (a1: ptr AreaHandler; a2: ptr Area; a3: ptr AreaDrawParams) {.cdecl.}
    mouseEvent*   : proc (a1: ptr AreaHandler; a2: ptr Area; a3: ptr AreaMouseEvent) {.cdecl.}
    mouseCrossed* : proc (a1: ptr AreaHandler; a2: ptr Area; left: cint) {.cdecl.}
    dragBroken*   : proc (a1: ptr AreaHandler; a2: ptr Area) {.cdecl.}
    keyEvent*     : proc (a1: ptr AreaHandler; a2: ptr Area; a3: ptr AreaKeyEvent): cint {.cdecl.}

type
  WindowResizeEdge* {. size: sizeof(cint) .} = enum
    WindowResizeEdgeLeft, 
    WindowResizeEdgeTop, 
    WindowResizeEdgeRight, 
    WindowResizeEdgeBottom, 
    WindowResizeEdgeTopLeft, 
    WindowResizeEdgeTopRight, 
    WindowResizeEdgeBottomLeft, 
    WindowResizeEdgeBottomRight


template area*(this: untyped): untyped =
  (cast[ptr Area]((this)))


proc areaSetSize*(a: ptr Area; width: cint; height: cint) {.cdecl,
    importc: "uiAreaSetSize", libui.}

proc areaQueueRedrawAll*(a: ptr Area) {.cdecl, importc: "uiAreaQueueRedrawAll",
                                    libui.}
proc areaScrollTo*(a: ptr Area; x: cdouble; y: cdouble; width: cdouble; height: cdouble) {.
    cdecl, importc: "uiAreaScrollTo", libui.}

proc areaBeginUserWindowMove*(a: ptr Area) {.cdecl,
    importc: "uiAreaBeginUserWindowMove", libui.}
proc areaBeginUserWindowResize*(a: ptr Area; edge: WindowResizeEdge) {.cdecl,
    importc: "uiAreaBeginUserWindowResize", libui.}
proc newArea*(ah: ptr AreaHandler): ptr Area {.cdecl, importc: "uiNewArea",
    libui.}
proc newScrollingArea*(ah: ptr AreaHandler; width: cint; height: cint): ptr Area {.cdecl,
    importc: "uiNewScrollingArea", libui.}

type
  DrawPath* = object

  DrawBrushType* {. size: sizeof(cint) .} = enum
    DrawBrushTypeSolid, 
    DrawBrushTypeLinearGradient, 
    DrawBrushTypeRadialGradient, 
    DrawBrushTypeImage

  DrawLineCap* {. size: sizeof(cint) .} = enum
    DrawLineCapFlat, 
    DrawLineCapRound, 
    DrawLineCapSquare

  DrawLineJoin* {. size: sizeof(cint) .} = enum
    DrawLineJoinMiter, 
    DrawLineJoinRound, 
    DrawLineJoinBevel

  DrawFillMode* {. size: sizeof(cint) .} = enum
    DrawFillModeWinding, 
    DrawFillModeAlternate

  DrawBrush* {.bycopy.} = object
    `type`*     : DrawBrushType
    r*          : cdouble
    g*          : cdouble
    b*          : cdouble
    a*          : cdouble
    x0*         : cdouble
    y0*         : cdouble
    x1*         : cdouble
    y1*         : cdouble
    outerRadius*: cdouble
    # perhaps instead an array?
    stops*      : ptr UncheckedArray[DrawBrushGradientStop]
    numStops*   : csize_t

  DrawStrokeParams* {.bycopy.} = object
    cap*       : DrawLineCap
    join*      : DrawLineJoin
    thickness* : cdouble ## if this is 0 on windows there will be a crash with dashing
    miterLimit*: cdouble
    dashes*    : ptr cdouble
    numDashes* : csize_t
    dashPhase* : cdouble

  DrawMatrix* {.bycopy.} = object
    m11*: cdouble
    m12*: cdouble
    m21*: cdouble
    m22*: cdouble
    m31*: cdouble
    m32*: cdouble

  DrawBrushGradientStop* {.bycopy.} = object
    pos*: cdouble
    r*  : cdouble
    g*  : cdouble
    b*  : cdouble
    a*  : cdouble

const
  DrawDefaultMiterLimit* = 10.0 ## This is the default for both Cairo and Direct2D 

proc drawNewPath*(fillMode: DrawFillMode): ptr DrawPath {.cdecl,
    importc: "uiDrawNewPath", libui.}
proc drawFreePath*(p: ptr DrawPath) {.cdecl, importc: "uiDrawFreePath", libui.}
proc drawPathNewFigure*(p: ptr DrawPath; x: cdouble; y: cdouble) {.cdecl,
    importc: "uiDrawPathNewFigure", libui.}
proc drawPathNewFigureWithArc*(p: ptr DrawPath; xCenter: cdouble; yCenter: cdouble;
                              radius: cdouble; startAngle: cdouble; sweep: cdouble;
                              negative: cint) {.cdecl,
    importc: "uiDrawPathNewFigureWithArc", libui.}
proc drawPathLineTo*(p: ptr DrawPath; x: cdouble; y: cdouble) {.cdecl,
    importc: "uiDrawPathLineTo", libui.}

proc drawPathArcTo*(p: ptr DrawPath; xCenter: cdouble; yCenter: cdouble;
                   radius: cdouble; startAngle: cdouble; sweep: cdouble;
                   negative: cint) {.cdecl, importc: "uiDrawPathArcTo",
                                   libui.}
proc drawPathBezierTo*(p: ptr DrawPath; c1x: cdouble; c1y: cdouble; c2x: cdouble;
                      c2y: cdouble; endX: cdouble; endY: cdouble) {.cdecl,
    importc: "uiDrawPathBezierTo", libui.}

proc drawPathCloseFigure*(p: ptr DrawPath) {.cdecl, importc: "uiDrawPathCloseFigure",
    libui.}

proc drawPathAddRectangle*(p: ptr DrawPath; x: cdouble; y: cdouble; width: cdouble;
                          height: cdouble) {.cdecl,
    importc: "uiDrawPathAddRectangle", libui.}
proc drawPathEnded*(p: ptr DrawPath): cint {.cdecl, importc: "uiDrawPathEnded",
                                        libui.}
proc drawPathEnd*(p: ptr DrawPath) {.cdecl, importc: "uiDrawPathEnd", libui.}
proc drawStroke*(c: ptr DrawContext; path: ptr DrawPath; b: ptr DrawBrush;
                p: ptr DrawStrokeParams) {.cdecl, importc: "uiDrawStroke",
                                        libui.}
proc drawFill*(c: ptr DrawContext; path: ptr DrawPath; b: ptr DrawBrush) {.cdecl,
    importc: "uiDrawFill", libui.}

proc drawMatrixSetIdentity*(m: ptr DrawMatrix) {.cdecl,
    importc: "uiDrawMatrixSetIdentity", libui.}
proc drawMatrixTranslate*(m: ptr DrawMatrix; x: cdouble; y: cdouble) {.cdecl,
    importc: "uiDrawMatrixTranslate", libui.}
proc drawMatrixScale*(m: ptr DrawMatrix; xCenter: cdouble; yCenter: cdouble; x: cdouble;
                     y: cdouble) {.cdecl, importc: "uiDrawMatrixScale",
                                 libui.}
proc drawMatrixRotate*(m: ptr DrawMatrix; x: cdouble; y: cdouble; amount: cdouble) {.
    cdecl, importc: "uiDrawMatrixRotate", libui.}
proc drawMatrixSkew*(m: ptr DrawMatrix; x: cdouble; y: cdouble; xamount: cdouble;
                    yamount: cdouble) {.cdecl, importc: "uiDrawMatrixSkew",
                                      libui.}
proc drawMatrixMultiply*(dest: ptr DrawMatrix; src: ptr DrawMatrix) {.cdecl,
    importc: "uiDrawMatrixMultiply", libui.}
proc drawMatrixInvertible*(m: ptr DrawMatrix): cint {.cdecl,
    importc: "uiDrawMatrixInvertible", libui.}
proc drawMatrixInvert*(m: ptr DrawMatrix): cint {.cdecl,
    importc: "uiDrawMatrixInvert", libui.}
proc drawMatrixTransformPoint*(m: ptr DrawMatrix; x: ptr cdouble; y: ptr cdouble) {.cdecl,
    importc: "uiDrawMatrixTransformPoint", libui.}
proc drawMatrixTransformSize*(m: ptr DrawMatrix; x: ptr cdouble; y: ptr cdouble) {.cdecl,
    importc: "uiDrawMatrixTransformSize", libui.}
proc drawTransform*(c: ptr DrawContext; m: ptr DrawMatrix) {.cdecl,
    importc: "uiDrawTransform", libui.}

proc drawClip*(c: ptr DrawContext; path: ptr DrawPath) {.cdecl, importc: "uiDrawClip",
    libui.}
proc drawSave*(c: ptr DrawContext) {.cdecl, importc: "uiDrawSave", libui.}
proc drawRestore*(c: ptr DrawContext) {.cdecl, importc: "uiDrawRestore",
                                    libui.}

type
  Attribute* = object
  AttributedString* = object

  AttributeType* {.size: sizeof(cint).} = enum
    AttributeTypeFamily, 
    AttributeTypeSize, 
    AttributeTypeWeight, 
    AttributeTypeItalic, 
    AttributeTypeStretch, 
    AttributeTypeColor, 
    AttributeTypeBackground, 
    AttributeTypeUnderline, 
    AttributeTypeUnderlineColor, 
    AttributeTypeFeatures


proc freeAttribute*(a: ptr Attribute) {.cdecl, importc: "uiFreeAttribute",
                                    libui.}

proc attributeGetType*(a: ptr Attribute): AttributeType {.cdecl,
    importc: "uiAttributeGetType", libui.}

proc newFamilyAttribute*(family: cstring): ptr Attribute {.cdecl,
    importc: "uiNewFamilyAttribute", libui.}

proc attributeFamily*(a: ptr Attribute): cstring {.cdecl,
    importc: "uiAttributeFamily", libui.}

proc newSizeAttribute*(size: cdouble): ptr Attribute {.cdecl,
    importc: "uiNewSizeAttribute", libui.}

proc attributeSize*(a: ptr Attribute): cdouble {.cdecl, importc: "uiAttributeSize",
    libui.}

type
  TextWeight* {.size: sizeof(cint).} = enum
    ## `TextWeight` represents possible text weights. These roughly
    ## map to the OS/2 text weight field of TrueType and OpenType
    ## fonts, or to CSS weight numbers. The named constants are
    ## nominal values; the actual values may vary by font and by OS,
    ## though this isn't particularly likely. Any value between
    ## `TextWeightMinimum` and `TextWeightMaximum`, inclusive,
    ## is allowed.
    ## 
    ## Note that due to restrictions in early versions of Windows, some
    ## fonts have "special" weights be exposed in many programs as
    ## separate font families. This is perhaps most notable with
    ## Arial Black. libui-ng does not do this, even on Windows (because the
    ## DirectWrite API libui-ng uses on Windows does not do this); to
    ## specify Arial Black, use family Arial and weight `TextWeightBlack`.

    TextWeightMinimum      = 0,
    TextWeightThin         = 100,
    TextWeightUltraLight   = 200,
    TextWeightLight        = 300,
    TextWeightBook         = 350,
    TextWeightNormal       = 400,
    TextWeightMedium       = 500,
    TextWeightSemiBold     = 600,
    TextWeightBold         = 700,
    TextWeightUltraBold    = 800,
    TextWeightHeavy        = 900,
    TextWeightUltraHeavy   = 950,
    TextWeightMaximum      = 1000

  TextItalic* {.size: sizeof(cint).} = enum
    ## `TextItalic` represents possible italic modes for a font. Italic
    ## represents "true" italics where the slanted glyphs have custom
    ## shapes, whereas oblique represents italics that are merely slanted
    ## versions of the normal glyphs. Most fonts usually have one or the
    ## other.

    TextItalicNormal, 
    TextItalicOblique, 
    TextItalicItalic


proc newWeightAttribute*(weight: TextWeight): ptr Attribute {.cdecl,
    importc: "uiNewWeightAttribute", libui.}

proc attributeWeight*(a: ptr Attribute): TextWeight {.cdecl,
    importc: "uiAttributeWeight", libui.}

proc newItalicAttribute*(italic: TextItalic): ptr Attribute {.cdecl,
    importc: "uiNewItalicAttribute", libui.}

proc attributeItalic*(a: ptr Attribute): TextItalic {.cdecl,
    importc: "uiAttributeItalic", libui.}

type
  TextStretch* {.size: sizeof(cint).} = enum
    ## `TextStretch` represents possible stretches (also called "widths")
    ## of a font.
    ## 
    ## Note that due to restrictions in early versions of Windows, some
    ## fonts have "special" stretches be exposed in many programs as
    ## separate font families. This is perhaps most notable with
    ## Arial Condensed. libui does not do this, even on Windows (because
    ## the DirectWrite API libui-ng uses on Windows does not do this); to
    ## specify Arial Condensed, use family Arial and stretch
    ## `TextStretchCondensed`.

    TextStretchUltraCondensed,
    TextStretchExtraCondensed,
    TextStretchCondensed,
    TextStretchSemiCondensed,
    TextStretchNormal,
    TextStretchSemiExpanded,
    TextStretchExpanded,
    TextStretchExtraExpanded,
    TextStretchUltraExpanded

proc newStretchAttribute*(stretch: TextStretch): ptr Attribute {.cdecl,
    importc: "uiNewStretchAttribute", libui.}

proc attributeStretch*(a: ptr Attribute): TextStretch {.cdecl,
    importc: "uiAttributeStretch", libui.}

proc newColorAttribute*(r: cdouble; g: cdouble; b: cdouble; a: cdouble): ptr Attribute {.
    cdecl, importc: "uiNewColorAttribute", libui.}

proc attributeColor*(a: ptr Attribute; r: ptr cdouble; g: ptr cdouble; b: ptr cdouble;
                    alpha: ptr cdouble) {.cdecl, importc: "uiAttributeColor",
                                       libui.}

proc newBackgroundAttribute*(r: cdouble; g: cdouble; b: cdouble; a: cdouble): ptr Attribute {.
    cdecl, importc: "uiNewBackgroundAttribute", libui.}

type
  Underline* {.size: sizeof(cint).} = enum
    ## `Underline` specifies a type of underline to use on text.

    UnderlineNone, 
    UnderlineSingle, 
    UnderlineDouble, 
    UnderlineSuggestion, ## wavy or dotted underlines used for spelling/grammar checkers 

  UnderlineColor* {.size: sizeof(cint).} = enum
    ## `UnderlineColor` specifies the color of any underline on the text it
    ## is applied to, regardless of the type of underline. In addition to
    ## being able to specify a custom color, you can explicitly specify
    ## platform-specific colors for suggestion underlines; to use them
    ## correctly, pair them with `UnderlineSuggestion` (though they can
    ## be used on other types of underline as well).
    ## 
    ## If an underline type is applied but no underline color is
    ## specified, the text color is used instead. If an underline color
    ## is specified without an underline type, the underline color
    ## attribute is ignored, but not removed from the `AttributedString`.

    UnderlineColorCustom,
    UnderlineColorSpelling,
    UnderlineColorGrammar,
    UnderlineColorAuxiliary, ## for instance, the color used by smart replacements on macOS or in Microsoft Office   


proc newUnderlineAttribute*(u: Underline): ptr Attribute {.cdecl,
    importc: "uiNewUnderlineAttribute", libui.}

proc attributeUnderline*(a: ptr Attribute): Underline {.cdecl,
    importc: "uiAttributeUnderline", libui.}

proc newUnderlineColorAttribute*(u: UnderlineColor; r: cdouble; g: cdouble; b: cdouble;
                                a: cdouble): ptr Attribute {.cdecl,
    importc: "uiNewUnderlineColorAttribute", libui.}

proc attributeUnderlineColor*(a: ptr Attribute; u: ptr UnderlineColor; r: ptr cdouble;
                             g: ptr cdouble; b: ptr cdouble; alpha: ptr cdouble) {.cdecl,
    importc: "uiAttributeUnderlineColor", libui.}

type
  OpenTypeFeatures* = object

  OpenTypeFeaturesForEachFunc* = proc (otf: ptr OpenTypeFeatures; a: char; b: char;
                                    c: char; d: char; value: uint32; data: pointer): ForEach {.
      cdecl.}


proc newOpenTypeFeatures*(): ptr OpenTypeFeatures {.cdecl,
    importc: "uiNewOpenTypeFeatures", libui.}

proc freeOpenTypeFeatures*(otf: ptr OpenTypeFeatures) {.cdecl,
    importc: "uiFreeOpenTypeFeatures", libui.}

proc openTypeFeaturesClone*(otf: ptr OpenTypeFeatures): ptr OpenTypeFeatures {.cdecl,
    importc: "uiOpenTypeFeaturesClone", libui.}

proc openTypeFeaturesAdd*(otf: ptr OpenTypeFeatures; a: char; b: char; c: char; d: char;
                         value: uint32) {.cdecl, importc: "uiOpenTypeFeaturesAdd",
                                        libui.}

proc openTypeFeaturesRemove*(otf: ptr OpenTypeFeatures; a: char; b: char; c: char; d: char) {.
    cdecl, importc: "uiOpenTypeFeaturesRemove", libui.}

proc openTypeFeaturesGet*(otf: ptr OpenTypeFeatures; a: char; b: char; c: char; d: char;
                         value: ptr uint32): cint {.cdecl,
    importc: "uiOpenTypeFeaturesGet", libui.}

proc openTypeFeaturesForEach*(otf: ptr OpenTypeFeatures;
                             f: OpenTypeFeaturesForEachFunc; data: pointer) {.cdecl,
    importc: "uiOpenTypeFeaturesForEach", libui.}

proc newFeaturesAttribute*(otf: ptr OpenTypeFeatures): ptr Attribute {.cdecl,
    importc: "uiNewFeaturesAttribute", libui.}

proc attributeFeatures*(a: ptr Attribute): ptr OpenTypeFeatures {.cdecl,
    importc: "uiAttributeFeatures", libui.}

type
  AttributedStringForEachAttributeFunc* = proc (s: ptr AttributedString;
      a: ptr Attribute; start: csize_t; `end`: csize_t; data: pointer): ForEach {.cdecl.}


proc newAttributedString*(initialString: cstring): ptr AttributedString {.cdecl,
    importc: "uiNewAttributedString", libui.}

proc freeAttributedString*(s: ptr AttributedString) {.cdecl,
    importc: "uiFreeAttributedString", libui.}

proc attributedStringString*(s: ptr AttributedString): cstring {.cdecl,
    importc: "uiAttributedStringString", libui.}

proc attributedStringLen*(s: ptr AttributedString): csize_t {.cdecl,
    importc: "uiAttributedStringLen", libui.}

proc attributedStringAppendUnattributed*(s: ptr AttributedString; str: cstring) {.
    cdecl, importc: "uiAttributedStringAppendUnattributed", libui.}

proc attributedStringInsertAtUnattributed*(s: ptr AttributedString; str: cstring;
    at: csize_t) {.cdecl, importc: "uiAttributedStringInsertAtUnattributed",
                 libui.}

proc attributedStringDelete*(s: ptr AttributedString; start: csize_t; `end`: csize_t) {.
    cdecl, importc: "uiAttributedStringDelete", libui.}

proc attributedStringSetAttribute*(s: ptr AttributedString; a: ptr Attribute;
                                  start: csize_t; `end`: csize_t) {.cdecl,
    importc: "uiAttributedStringSetAttribute", libui.}

proc attributedStringForEachAttribute*(s: ptr AttributedString;
                                      f: AttributedStringForEachAttributeFunc;
                                      data: pointer) {.cdecl,
    importc: "uiAttributedStringForEachAttribute", libui.}

proc attributedStringNumGraphemes*(s: ptr AttributedString): csize_t {.cdecl,
    importc: "uiAttributedStringNumGraphemes", libui.}

proc attributedStringByteIndexToGrapheme*(s: ptr AttributedString; pos: csize_t): csize_t {.
    cdecl, importc: "uiAttributedStringByteIndexToGrapheme", libui.}

proc attributedStringGraphemeToByteIndex*(s: ptr AttributedString; pos: csize_t): csize_t {.
    cdecl, importc: "uiAttributedStringGraphemeToByteIndex", libui.}

type
  FontDescriptor* {.bycopy.} = object
    ## `FontDescriptor` provides a complete description of a font where
    ## one is needed. Currently, this means as the default font of a
    ## DrawTextLayout and as the data returned by `FontButton <#FontButton>`_.
    ## 
    ## All the members operate like the respective `Attribute`s.
    
    family* : cstring
    size*   : cdouble
    weight* : TextWeight
    italic* : TextItalic
    stretch*: TextStretch


proc loadControlFont*(f: ptr FontDescriptor) {.cdecl, importc: "uiLoadControlFont",
    libui.}
proc freeFontDescriptor*(desc: ptr FontDescriptor) {.cdecl,
    importc: "uiFreeFontDescriptor", libui.}

type
  DrawTextLayout* = object

  DrawTextAlign* {.size: sizeof(cint).} = enum
    ## `DrawTextAlign` specifies the alignment of lines of text in a
    ## `DrawTextLayout`.
    
    DrawTextAlignLeft,
    DrawTextAlignCenter
    DrawTextAlignRight

  DrawTextLayoutParams* {.bycopy.} = object
    ## `DrawTextLayoutParams` describes a `DrawTextLayout`.
    ## `defaultFont` is used to render any text that is not attributed
    ## sufficiently in `string`. `width` determines the width of the bounding
    ## box of the text; the height is determined automatically.
    
    string*      : ptr AttributedString
    defaultFont* : ptr FontDescriptor
    width*       : cdouble
    align*       : DrawTextAlign

proc drawNewTextLayout*(params: ptr DrawTextLayoutParams): ptr DrawTextLayout {.cdecl,
    importc: "uiDrawNewTextLayout", libui.}

proc drawFreeTextLayout*(tl: ptr DrawTextLayout) {.cdecl,
    importc: "uiDrawFreeTextLayout", libui.}

proc drawText*(c: ptr DrawContext; tl: ptr DrawTextLayout; x: cdouble; y: cdouble) {.cdecl,
    importc: "uiDrawText", libui.}

proc drawTextLayoutExtents*(tl: ptr DrawTextLayout; width: ptr cdouble;
                           height: ptr cdouble) {.cdecl,
    importc: "uiDrawTextLayoutExtents", libui.}

type
  FontButton* = object of Control

template fontButton*(this: untyped): untyped =
  (cast[ptr FontButton]((this)))


proc fontButtonFont*(b: ptr FontButton; desc: ptr FontDescriptor) {.cdecl,
    importc: "uiFontButtonFont", libui.}

proc fontButtonOnChanged*(b: ptr FontButton; f: proc (sender: ptr FontButton;
    senderData: pointer) {.cdecl.}; data: pointer) {.cdecl,
    importc: "uiFontButtonOnChanged", libui.}

proc newFontButton*(): ptr FontButton {.cdecl, importc: "uiNewFontButton",
                                    libui.}

proc freeFontButtonFont*(desc: ptr FontDescriptor) {.cdecl,
    importc: "uiFreeFontButtonFont", libui.}

type
  ColorButton* = object of Control

template colorButton*(this: untyped): untyped =
  (cast[ptr ColorButton]((this)))


proc colorButtonColor*(b: ptr ColorButton; r: ptr cdouble; g: ptr cdouble;
                      bl: ptr cdouble; a: ptr cdouble) {.cdecl,
    importc: "uiColorButtonColor", libui.}

proc colorButtonSetColor*(b: ptr ColorButton; r: cdouble; g: cdouble; bl: cdouble;
                         a: cdouble) {.cdecl, importc: "uiColorButtonSetColor",
                                     libui.}

proc colorButtonOnChanged*(b: ptr ColorButton; f: proc (sender: ptr ColorButton;
    senderData: pointer) {.cdecl.}; data: pointer) {.cdecl,
    importc: "uiColorButtonOnChanged", libui.}

proc newColorButton*(): ptr ColorButton {.cdecl, importc: "uiNewColorButton",
                                      libui.}

type
  Form* = object of Control

template form*(this: untyped): untyped =
  (cast[ptr Form]((this)))


proc formAppend*(f: ptr Form; label: cstring; c: ptr Control; stretchy: cint) {.cdecl,
    importc: "uiFormAppend", libui.}

proc formNumChildren*(f: ptr Form): cint {.cdecl, importc: "uiFormNumChildren",
                                      libui.}

proc formDelete*(f: ptr Form; index: cint) {.cdecl, importc: "uiFormDelete",
                                       libui.}

proc formPadded*(f: ptr Form): cint {.cdecl, importc: "uiFormPadded", libui.}

proc formSetPadded*(f: ptr Form; padded: cint) {.cdecl, importc: "uiFormSetPadded",
    libui.}

proc newForm*(): ptr Form {.cdecl, importc: "uiNewForm", libui.}

type
  Align* {.size: sizeof(cint).} = enum
    ## Alignment specifiers to define placement within the reserved area.
    ## 
    ## Used in `Grid`
    
    AlignFill,   ## Fill area
    AlignStart,  ## Place at start.
    AlignCenter, ## Place in center
    AlignEnd     ## Place at end

  At* {.size: sizeof(cint).} = enum
    ## Placement specifier to define placement in relation to another widget.
    ## 
    ## Used in `Grid`
    
    AtLeading,  ## Place before widget. 
    AtTop,      ## Place above widget. 
    AtTrailing, ## Place behind widget. 
    AtBottom    ## Place below widget.


type
  Grid* = object of Control

template grid*(this: untyped): untyped =
  (cast[ptr Grid]((this)))


proc gridAppend*(g: ptr Grid; c: ptr Control; left: cint; top: cint; xspan: cint;
                yspan: cint; hexpand: cint; halign: Align; vexpand: cint; valign: Align) {.
    cdecl, importc: "uiGridAppend", libui.}

proc gridInsertAt*(g: ptr Grid; c: ptr Control; existing: ptr Control; at: At; xspan: cint;
                  yspan: cint; hexpand: cint; halign: Align; vexpand: cint;
                  valign: Align) {.cdecl, importc: "uiGridInsertAt", libui.}

proc gridPadded*(g: ptr Grid): cint {.cdecl, importc: "uiGridPadded", libui.}

proc gridSetPadded*(g: ptr Grid; padded: cint) {.cdecl, importc: "uiGridSetPadded",
    libui.}

proc newGrid*(): ptr Grid {.cdecl, importc: "uiNewGrid", libui.}

type
  Image* = object

proc newImage*(width: cdouble; height: cdouble): ptr Image {.cdecl,
    importc: "uiNewImage", libui.}

proc freeImage*(i: ptr Image) {.cdecl, importc: "uiFreeImage", libui.}

proc imageAppend*(i: ptr Image; pixels: pointer; pixelWidth: cint; pixelHeight: cint;
                 byteStride: cint) {.cdecl, importc: "uiImageAppend", libui.}

type
  TableValueType* {.size: sizeof(cint).} = enum
    ## `TableValue <#TableValue>`_ types.

    TableValueTypeString, 
    TableValueTypeImage, 
    TableValueTypeInt, 
    TableValueTypeColor 

  Color* {.bycopy.} = object
    r* : cdouble
    g* : cdouble
    b* : cdouble
    a* : cdouble

  TableValueInner* {.bycopy, union.} = object
    str*   : cstring
    img*   : ptr Image
    i*     : cint
    color* : Color

  TableValue* {.bycopy.} = object
    kind* : TableValueType
    u*    : TableValueInner


proc freeTableValue*(v: ptr TableValue) {.cdecl, importc: "uiFreeTableValue",
                                      libui.}

proc tableValueGetType*(v: ptr TableValue): TableValueType {.cdecl,
    importc: "uiTableValueGetType", libui.}

proc newTableValueString*(str: cstring): ptr TableValue {.cdecl,
    importc: "uiNewTableValueString", libui.}

proc tableValueString*(v: ptr TableValue): cstring {.cdecl,
    importc: "uiTableValueString", libui.}

proc newTableValueImage*(img: ptr Image): ptr TableValue {.cdecl,
    importc: "uiNewTableValueImage", libui.}

proc tableValueImage*(v: ptr TableValue): ptr Image {.cdecl,
    importc: "uiTableValueImage", libui.}

proc newTableValueInt*(i: cint): ptr TableValue {.cdecl,
    importc: "uiNewTableValueInt", libui.}

proc tableValueInt*(v: ptr TableValue): cint {.cdecl, importc: "uiTableValueInt",
    libui.}

proc newTableValueColor*(r: cdouble; g: cdouble; b: cdouble; a: cdouble): ptr TableValue {.
    cdecl, importc: "uiNewTableValueColor", libui.}

proc tableValueColor*(v: ptr TableValue; r: ptr cdouble; g: ptr cdouble; b: ptr cdouble;
                     a: ptr cdouble) {.cdecl, importc: "uiTableValueColor",
                                    libui.}

type
  SortIndicator* {.size: sizeof(cint).} = enum
    SortIndicatorNone, 
    SortIndicatorAscending, 
    SortIndicatorDescending

type
  TableModel* = pointer

type
  TableModelHandler* {.bycopy.} = object
    ## Developer defined methods for data retrieval and setting.
    ## 
    ## These methods get called whenever the associated `TableModel` needs to
    ## retrieve data or a `Table` wants to set data.
    ## 
    ## .. warning:: These methods are **NOT** allowed to change as soon as the
    ##          `TableModelHandler` is associated with a `TableModel`.

    numColumns*  : proc (a1: ptr TableModelHandler; a2: ptr TableModel): cint {.cdecl.} ## \
    ## Returns the number of columns in the `TableModel`.
    ##
    ## .. warning:: This value **MUST** remain constant throughout the lifetime of the `TableModel`.
    ## 
    ## .. warning:: This method is not guaranteed to be called depending on the system

    columnType*  : proc (a1: ptr TableModelHandler; a2: ptr TableModel; col: cint): TableValueType {.cdecl.} ## \
    ## Returns the column type in for of a `TableValueType`.
    ##
    ## .. warning:: This value **MUST** remain constant throughout the lifetime of the `TableModel`.
    ## 
    ## .. warning:: This method is not guaranteed to be called depending on the system
                                                                                                                
    numRows*     : proc (a1: ptr TableModelHandler; a2: ptr TableModel) : cint {.cdecl.} ## \ 
    ## Returns the number of rows in the `TableModel`.

    cellValue*   : proc (mh: ptr TableModelHandler; m: ptr TableModel; row: cint; col: cint): ptr TableValue {.cdecl.} ## \
    ## Returns the cell value for (row, col).
    ## 
    ## Make sure to use the `TableValue` constructors. The returned value
    ## must match the `TableValueType` defined in `columnType()`.
    ## 
    ## Some columns may return `nil` as a special value. Refer to the
    ## appropriate `addColumn()` documentation.
    ## 
    ## .. note:: `TableValue` objects are automatically freed when requested by
    ##       a `Table`.

    setCellValue*: proc (a1: ptr TableModelHandler; a2: ptr TableModel; row: cint; col: cint; a3: ptr TableValue) {.cdecl.} ## \
    ## Sets the cell value for (row, column).
    ## It is up to the handler to decide what to do with the value: change
    ## the model or reject the change, keeping the old value.
    ## 
    ## Some columns may call this function with `nil` as a special value.
    ## Refer to the appropriate `addColumn()` documentation.
    ## 
    ## .. note:: `TableValue` objects are automatically freed upon return when
    ##        set by a `Table`.

proc newTableModel*(mh: ptr TableModelHandler): ptr TableModel {.cdecl,
    importc: "uiNewTableModel", libui.}

proc freeTableModel*(m: ptr TableModel) {.cdecl, importc: "uiFreeTableModel",
                                      libui.}

proc tableModelRowInserted*(m: ptr TableModel; newIndex: cint) {.cdecl,
    importc: "uiTableModelRowInserted", libui.}

proc tableModelRowChanged*(m: ptr TableModel; index: cint) {.cdecl,
    importc: "uiTableModelRowChanged", libui.}

proc tableModelRowDeleted*(m: ptr TableModel; oldIndex: cint) {.cdecl,
    importc: "uiTableModelRowDeleted", libui.}

const
  TableModelColumnNeverEditable*  = (-1) ## \
  ## Parameter to editable model columns to signify all rows are never editable.
  
  TableModelColumnAlwaysEditable* = (-2) ## \
  ## Parameter to editable model columns to signify all rows are always editable.

type
  Table* = object of Control

  TableTextColumnOptionalParams* {.bycopy.} = object
    ## Optional parameters to control the appearance of text columns.
    
    colorModelColumn*: cint

  TableParams* {.bycopy.} = object
    ## Table parameters passed to `newTable()`.
    
    model*                         : ptr TableModel ## \
    ## Model holding the data to be displayed. This can **NOT** be `nil`.

    rowBackgroundColorModelColumn* : cint ## \
    ## `TableModel` column that defines background color for each row,
    ## 
    ## `TableValue.color` Background color, `nil` to use the default
    ## background color for that row.
    ## 
    ## `-1` to use the default background color for all rows.

template table*(this: untyped): untyped =
  (cast[ptr Table]((this)))


proc tableAppendTextColumn*(t: ptr Table; name: cstring; textModelColumn: cint;
                           textEditableModelColumn: cint;
                           textParams: ptr TableTextColumnOptionalParams) {.cdecl,
    importc: "uiTableAppendTextColumn", libui.}

proc tableAppendImageColumn*(t: ptr Table; name: cstring; imageModelColumn: cint) {.
    cdecl, importc: "uiTableAppendImageColumn", libui.}

proc tableAppendImageTextColumn*(t: ptr Table; name: cstring; imageModelColumn: cint;
                                textModelColumn: cint;
                                textEditableModelColumn: cint;
                                textParams: ptr TableTextColumnOptionalParams) {.
    cdecl, importc: "uiTableAppendImageTextColumn", libui.}

proc tableAppendCheckboxColumn*(t: ptr Table; name: cstring;
                               checkboxModelColumn: cint;
                               checkboxEditableModelColumn: cint) {.cdecl,
    importc: "uiTableAppendCheckboxColumn", libui.}

proc tableAppendCheckboxTextColumn*(t: ptr Table; name: cstring;
                                   checkboxModelColumn: cint;
                                   checkboxEditableModelColumn: cint;
                                   textModelColumn: cint;
                                   textEditableModelColumn: cint; textParams: ptr TableTextColumnOptionalParams) {.
    cdecl, importc: "uiTableAppendCheckboxTextColumn", libui.}

proc tableAppendProgressBarColumn*(t: ptr Table; name: cstring;
                                  progressModelColumn: cint) {.cdecl,
    importc: "uiTableAppendProgressBarColumn", libui.}

proc tableAppendButtonColumn*(t: ptr Table; name: cstring; buttonModelColumn: cint;
                             buttonClickableModelColumn: cint) {.cdecl,
    importc: "uiTableAppendButtonColumn", libui.}

proc tableHeaderVisible*(t: ptr Table): cint {.cdecl, importc: "uiTableHeaderVisible",
    libui.}

proc tableHeaderSetVisible*(t: ptr Table; visible: cint) {.cdecl,
    importc: "uiTableHeaderSetVisible", libui.}

proc newTable*(params: ptr TableParams): ptr Table {.cdecl, importc: "uiNewTable",
    libui.}

proc tableOnRowClicked*(t: ptr Table; f: proc (t: ptr Table; row: cint; data: pointer) {.
    cdecl.}; data: pointer) {.cdecl, importc: "uiTableOnRowClicked", libui.}

proc tableOnRowDoubleClicked*(t: ptr Table; f: proc (t: ptr Table; row: cint; data: pointer) {.
    cdecl.}; data: pointer) {.cdecl, importc: "uiTableOnRowDoubleClicked",
                           libui.}

proc tableHeaderSetSortIndicator*(t: ptr Table; column: cint; indicator: SortIndicator) {.
    cdecl, importc: "uiTableHeaderSetSortIndicator", libui.}

proc tableHeaderSortIndicator*(t: ptr Table; column: cint): SortIndicator {.cdecl,
    importc: "uiTableHeaderSortIndicator", libui.}

proc tableHeaderOnClicked*(t: ptr Table; f: proc (sender: ptr Table; column: cint;
    senderData: pointer) {.cdecl.}; data: pointer) {.cdecl,
    importc: "uiTableHeaderOnClicked", libui.}

proc tableColumnWidth*(t: ptr Table; column: cint): cint {.cdecl,
    importc: "uiTableColumnWidth", libui.}

proc tableColumnSetWidth*(t: ptr Table; column: cint; width: cint) {.cdecl,
    importc: "uiTableColumnSetWidth", libui.}

type
  TableColumnType* = proc (mh: ptr TableModelHandler, m: TableModel, col: int): TableValueType {.noconv.}
  TableSelectionMode* {. size: sizeof(cint) .} = enum
    ## Table selection modes.
    ## 
    ## Table selection that enforce how a user can interact with a table.
    ## 
    ## .. note:: An empty table selection is a valid state for any selection mode.
    ##          This is in fact the default upon table creation and can otherwise
    ##          triggered through operations such as row deletion.

    TableSelectionModeNone,       ## Allow no row selection.
                                  ##
                                  ## .. warning:: This mode disables all editing of text columns. Buttons
                                  ##          and checkboxes keep working though.

    TableSelectionModeZeroOrOne,  ## Allow zero or one row to be selected.

    TableSelectionModeOne,        ## Allow for exactly one row to be selected.
  
    TableSelectionModeZeroOrMany, ## Allow zero or many (multiple) rows to be selected.

  TableSelection* {.bycopy.} = object
    ## Holds an array of selected row indices for a table.
    
    numRows* : cint                     ## Number of selected rows.
    rows*    : ptr UncheckedArray[cint] ## Array containing selected row indices, `nil` on empty selection.

proc tableGetSelectionMode*(t: ptr Table): TableSelectionMode {.cdecl,
    importc: "uiTableGetSelectionMode", libui.}

proc tableSetSelectionMode*(t: ptr Table; mode: TableSelectionMode) {.cdecl,
    importc: "uiTableSetSelectionMode", libui.}

proc tableOnSelectionChanged*(t: ptr Table;
                             f: proc (t: ptr Table; data: pointer) {.cdecl.};
                             data: pointer) {.cdecl,
    importc: "uiTableOnSelectionChanged", libui.}

proc tableGetSelection*(t: ptr Table): ptr TableSelection {.cdecl,
    importc: "uiTableGetSelection", libui.}

proc tableSetSelection*(t: ptr Table; sel: ptr TableSelection) {.cdecl,
    importc: "uiTableSetSelection", libui.}

proc freeTableSelection*(s: ptr TableSelection) {.cdecl,
    importc: "uiFreeTableSelection", libui.}