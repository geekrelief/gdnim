import msgpack4nim, tables
export msgpack4nim, tables

type
  OnBeforeReload* = proc() {.closure, gcsafe.}

when not defined(exportStorage):
  {.push nimcall, importc, dynlib:"_dlls/storage.dll"}
  # used by Watcher
  proc getBeforeReloadProcs*():Table[string, OnBeforeReload]

  #used by components
  proc putData*(id:string, data: string)
  proc registerBeforeReloadProc*(id: string, beforeReload:OnBeforeReload):string
else:
  var beforeReloadData:Table[string, string]
  var beforeReloadProcs:Table[string, OnBeforeReload]

  # --- implementation
  {.push nimcall, exportc, dynlib.}
  proc getBeforeReloadProcs*():Table[string, OnBeforeReload] =
    beforeReloadProcs

  proc putData*(id: string, data: string) =
    beforeReloadData[id] = data

  proc registerBeforeReloadProc*(id: string, beforeReload:OnBeforeReload):string =
    var nid = id & "" #need to create a newString otherwise we'll get a crash on copy
    beforeReloadProcs[nid] = beforeReload
    var data = ""
    discard beforeReloadData.take(nid, data)
    result = data
