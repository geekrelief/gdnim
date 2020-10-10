import tables
type
  OnBeforeReload = proc() {.closure, gcsafe.}

var beforeReloadData:Table[string, string]
var beforeReloadProcs:Table[string, OnBeforeReload]

{.push nimcall, exportc, dynlib.}
# used by Watcher
proc getBeforeReloadProcs():Table[string, OnBeforeReload] =
  beforeReloadProcs

#used by components
proc putData(id:sink string, data:sink string) =
  beforeReloadData[id] = data

# used by components
proc registerBeforeReloadProc(id:sink string, beforeReload:OnBeforeReload):string =
  beforeReloadProcs[id] = beforeReload
  var data = ""
  discard beforeReloadData.take(id, data)
  result = data
