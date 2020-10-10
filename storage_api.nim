import msgpack4nim, tables
export msgpack4nim, tables

import tables
type
  OnBeforeReload* = proc() {.closure, gcsafe.}

{.push nimcall, importc, dynlib:"_dlls/storage.dll"}

proc getBeforeReloadProcs*():Table[string, OnBeforeReload]
proc putData*(id:sink string, data:sink string)
proc registerBeforeReloadProc*(id:sink string, beforeReload:OnBeforeReload):string