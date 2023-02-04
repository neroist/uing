import std/random

import uing
from uing/rawui import nil

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

var
  progress: array[NUM_ROWS, array[NUM_COLUMNS, int]]

proc modelNumColumns(mh: ptr TableModelHandler, m: ptr rawui.TableModel): cint {.cdecl.} = NUM_COLUMNS
proc modelNumRows(mh: ptr TableModelHandler, m: ptr rawui.TableModel): cint {.cdecl.} = NUM_ROWS

proc modelColumnType(mh: ptr TableModelHandler, m: ptr rawui.TableModel, col: cint): TableValueType {.cdecl.} =
  #echo "type"

  if col in [COLUMN_ID, COLUMN_PROCESS, COLUMN_PASSED]:
    result = TableValueTypeInt
  else:
    result = TableValueTypeString

proc modelCellValue(mh: ptr TableModelHandler, m: ptr rawui.TableModel, row, col: cint): ptr rawui.TableValue {.cdecl.} =
  if col == COLUMN_ID:
    result = newTableValue($(row+1)).impl
  elif col == COLUMN_PROCESS:
    if progress[row][col] == 0:
      progress[row][col] = rand(100)
    result = newTableValue(progress[row][col]).impl
  #elif col == COLUMN_PASSED:
  #  if progress[row][col] > 60:
  #    result = newTableValue(1).impl
  #  else:
  #    result = newTableValue(0).impl
  elif col == COLUMN_ACTION:
    result = newTableValue("Apply").impl
  else:
    result = newTableValue("row " & $row & " x col " & $col).impl


proc modelSetCellValue(mh: ptr TableModelHandler, m: ptr rawui.TableModel, row, col: cint, val: ptr rawui.TableValue) {.cdecl.} =
  #echo "setCellValue"

  if col == COLUMN_PASSED:
    echo rawui.tableValueInt(val)
  elif col == COLUMN_ACTION:
    rawui.tableModelRowChanged(m, row)

var
  mh: TableModelHandler
  p: TableParams
  tp {.used.}: TableTextColumnOptionalParams 

proc main() =
  var mainwin: Window

  var menu = newMenu("File")
  menu.addQuitItem(
    proc(): bool =
      mainwin.destroy()
      return true
  )

  mainwin = newWindow("Table", 640, 480, true)
  mainwin.margined = true

  let box = newVerticalBox(true)
  mainwin.child = box

  mh.numColumns = modelNumColumns
  mh.columnType = modelColumnType
  mh.numRows = modelNumRows
  mh.cellValue  = modelCellValue
  mh.setCellValue = modelSetCellValue

  p.model = rawui.newTableModel(addr mh)
  p.rowBackgroundColorModelColumn = 4
 
  let table = newTable(addr p)
  table.addTextColumn("ID", COLUMN_ID, TableModelColumnNeverEditable, nil)
  table.addTextColumn("First Name", COLUMN_FIRST_NAME, TableModelColumnAlwaysEditable, nil)
  table.addTextColumn("Last Name", COLUMN_LAST_NAME, TableModelColumnAlwaysEditable, nil)
  table.addTextColumn("Address", COLUMN_ADRESS, TableModelColumnAlwaysEditable, nil)
  table.addProgressBarColumn("Progress", COLUMN_PROCESS)
  table.addCheckboxColumn("Passed", COLUMN_PASSED, TableModelColumnAlwaysEditable)
  table.addButtonColumn("Action", COLUMN_ACTION, TableModelColumnAlwaysEditable)

  box.add(table, true)
  show(mainwin)

init()
main()
mainLoop()
