import std/random
import std/sugar

from uing/rawui import nil
import uing

randomize()

const
  NUM_COLUMNS = 7
  NUM_ROWS = 10

  COLUMN_ID = 0
  COLUMN_FIRST_NAME = 1
  COLUMN_LAST_NAME = 2
  COLUMN_ADRESS = 3
  COLUMN_PROCESS = 4
  COLUMN_PASSED = 5
  COLUMN_ACTION = 6

let progress = collect: 
  for row in 0..<NUM_ROWS:
    rand(100)

proc modelNumColumns(mh: ptr TableModelHandler, m: ptr rawui.TableModel): cint {.cdecl.} = NUM_COLUMNS
proc modelNumRows(mh: ptr TableModelHandler, m: ptr rawui.TableModel): cint {.cdecl.} = NUM_ROWS

proc modelColumnType(mh: ptr TableModelHandler, m: ptr rawui.TableModel, col: cint): TableValueType {.cdecl.} =
  if col in [COLUMN_PROCESS, COLUMN_PASSED]:
    result = TableValueTypeInt
  else:
    result = TableValueTypeString

proc modelCellValue(mh: ptr TableModelHandler, m: ptr rawui.TableModel, row, col: cint): ptr rawui.TableValue {.cdecl.} =
  case col:
    of COLUMN_ID:
      result = newTableValue($(row+1)).impl
    of COLUMN_PROCESS:
      result = newTableValue(progress[row]).impl
    of COLUMN_PASSED:
      result = newTableValue(progress[row] > 60).impl
    of COLUMN_ACTION:
      result = newTableValue("Apply").impl
    else:
      result = newTableValue("row " & $row & " x col " & $col).impl

proc modelSetCellValue(mh: ptr TableModelHandler, m: ptr rawui.TableModel, row, col: cint, val: ptr rawui.TableValue) {.cdecl.} =
  if col == COLUMN_ACTION:
    rawui.tableModelRowChanged(m, row)

proc main() =
  var mainwin: Window

  let menu = newMenu("File")
  menu.addQuitItem(
    proc(): bool =
      mainwin.destroy()
      return true
  )

  mainwin = newWindow("Table", 640, 480, true)
  mainwin.margined = true

  let box = newVerticalBox(true)
  mainwin.child = box

  var mh: TableModelHandler
  mh.numColumns = modelNumColumns
  mh.columnType = modelColumnType
  mh.numRows = modelNumRows
  mh.cellValue = modelCellValue
  mh.setCellValue = modelSetCellValue

  var p: TableParams
  p.model = newTableModel(addr mh).impl
  p.rowBackgroundColorModelColumn = -1
 
  let table = newTable(addr p)
  table.addTextColumn("ID", COLUMN_ID, TableModelColumnNeverEditable)
  table.addTextColumn("First Name", COLUMN_FIRST_NAME, TableModelColumnAlwaysEditable)
  table.addTextColumn("Last Name", COLUMN_LAST_NAME, TableModelColumnAlwaysEditable)
  table.addTextColumn("Address", COLUMN_ADRESS, TableModelColumnAlwaysEditable)
  table.addProgressBarColumn("Progress", COLUMN_PROCESS)
  table.addCheckboxColumn("Passed", COLUMN_PASSED, TableModelColumnAlwaysEditable)
  table.addButtonColumn("Action", COLUMN_ACTION, TableModelColumnAlwaysEditable)

  box.add table, true
  
  show mainwin
  mainLoop()

init()
main()
