
#instance meta data required for hot reload
const HotMetaInstanceId* = "hot_meta_instance_id"
const HotMetaIsReloading* = "hot_meta_is_reloading"
const HotMetaPositionInParent* = "hot_meta_position_in_parent"

# component proc name auto-defined in gdnim for custom data saving
const HotUnload* = "hot_unload"

# watcher signal names
const WatcherReloadingStart* = "reloading_start"
const WatcherReloadingComplete* = "reloading_complete"
const WatcherReloadingFailed* = "reloading_failed"
const WatcherInstanceUnloaded* = "instance_unloaded"
const WatcherInstanceLoaded* = "instance_loaded"

# compilation defined symbols
const does_reload* {.booldefine.}: bool = true
const is_tool* {.booldefine.}: bool = false

const baseDllDir* {.strdefine.}: string = ""
const baseTscnDir* {.strdefine.}: string = ""
const dllPrefix* {.strdefine.}: string = ""
const dllExt* {.strdefine.}: string = "unknown"