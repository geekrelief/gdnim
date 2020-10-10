import msgpack4nim, tables
export msgpack4nim, tables

type
  OnBeforeReload* = proc() {.closure, gcsafe.}

var beforeReloadData:Table[string, string]
var beforeReloadProcs:Table[string, OnBeforeReload]

when not defined(exportStorage):
  {.push nimcall, importc, dynlib:"_dlls/storage.dll"}
  # used by Watcher
  proc getBeforeReloadProcs*():Table[string, OnBeforeReload]

  #used by components
  proc putData*(id:sink string, data:sink string)
  proc registerBeforeReloadProc*(id:sink string, beforeReload:OnBeforeReload):string
else:
  # --- implementation
  {.push nimcall, exportc, dynlib.}
  proc getBeforeReloadProcs*():Table[string, OnBeforeReload] =
    beforeReloadProcs

  proc putData*(id:sink string, data:sink string) =
    beforeReloadData[id] = data

  proc registerBeforeReloadProc*(id:sink string, beforeReload:OnBeforeReload):string =
    beforeReloadProcs[id] = beforeReload
    var data = ""
    discard beforeReloadData.take(id, data)
    result = data
