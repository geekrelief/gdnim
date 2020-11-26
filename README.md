**Warning:** This repo has been tailored for my system. If you happen to find this,
feel free to customize it yourself.

# Gdnim #
gdnim bootstraps a [godot-nim](https://github.com/pragmagic/godot-nim) project,
with a customized build of godot-nim that enables easier project managment. It's
killer feature is automated, hot code reloading through the use of scenes as
resources for components and a Watcher node.

## Quick Start ##
 - Clone - [godot 3.2 custom](https://github.com/geekrelief/godot/tree/3.2_custom)
     If this is looking stale, create an issue I'll update it with godot's latest commits
 - Configure the build.ini for your setup
 - Compile the build script: nim c build
 - Build the godot binaries: ./build gdengine
 - Generate the godot-nim bindings: ./build genapi
 - Build watcher and components: ./build cleanbuild

 - Generate a new component specifying base class module: ./build gencomp my_comp node_2d
 - Modify components/my_comp.nim
 - Run editor: ./build gd
 - Run scene using component, make a modification to component: ./build
 - Hot reload should occur (check console or editor console for output)
 - **Note:** The hot module contains save and load macros to persist state between reloads.

### Main commands ###
 - Run Godot: ./build gd
 - Hot Reload your script (after modification): ./build
 - If you need to restart the app, build and move the dll with then run again: ./build -m

## Prerequites ##
  - VSCode
  - [godot 3.2 custom](https://github.com/geekrelief/godot/tree/3.2_custom)
  - or [godot 3.2 with gdnative unload](https://github.com/geekrelief/godot/tree/3.2_gdnative_unload)
  - [Tiny C Compiler](https://github.com/mirror/tinycc) (fast compiles, but does not support threads)
  - [nim](https://github.com/nim-lang/Nim) v1.5.1+ which has gc:arc and bug fixes.
  - [compiler](https://nimble.directory/pkg/compiler)
  - [msgpack4nim](https://nimble.directory/pkg/msgpack4nim)
  - [anycase](https://nimble.directory/pkg/anycase)
  - [PMunch optionsutils](https://github.com/PMunch/nim-optionsutils)
  - vcc, gcc (optional, but required for threads)

## Project Structure ##
Gdnim uses a customized build script and [a custom version of godot 3.2](https://github.com/geekrelief/godot/tree/3.2_custom) merged with [godot 3.2 with gdnative unload](https://github.com/geekrelief/godot/tree/3.2_gdnative_unload) which unloads gdnative libraries when their resource is no longer referenced. It removes the dependency on nake and nimscript which can be buggy and limited. Nimscript doesn't allow the use of exportc functions to check for file modification times. Gdnim also uses a custom version of the godot-nim bindings in the deps/godot directory, to begin future-proofing it for modern versions of nim (using GC ORC/ARC).

### Files and Folders ###
 - `/deps/godot`: Custom version of godot-nim bindings. You can move this and update the location in `build.ini`
 - `build.nim`: The build script, compiled with `nim c build`, includes the `tasks.nim`
 - `tasks.nim`: Build tasks are specified here for updating / compiling the godot engine, generating / compiling  components, running the godot editor, etc.
 - `watcher.nim`: The Watcher node that monitors changes to registered components. In a new godot project set watcher.gdns to autoload.
 - `hot.nim`: The module used by components to register with the Watcher node. Also has save / load macros for persisting data between reloads.
 - `build.ini`: Configuration file used to specify directories and settings.
 - `/components`: Where nim component files live. Components must have unique identifiers. Dlls are generated from these components.


## Setup ##

The project is developed and tested only on Windows.
Modify the build.ini, build.nim and tasks.nim script for your needs.
build.ini expects some paths to my godot 3.2 custom engine source and editor executables.

If you have all my mods from build.ini's merge_branches in your git repo you can, run
`./build gdengine update`.  Otherwise stick to using 3.2_custom, which I update periodically
with commits from godot's 3.2 branch by rebasing.

The app folder contains the stub godot project. You create "components" which are the classes that can reload by
running the `./build gencomp your_module_name godot_base_class_name`.  A nim file will appear in
the components folder. Generated files are stored in app/_dlls, app/_gdns, app/_tscn.
Run the godot editor. The watcher.gdns should autoload in the godot project.

See the temp_comp example in the components folder.

Use the build script to download the godot source, compile the engine, create godot-nim bindings api, compile the watcher and components, etc.

## Tips ##
 - If the godot app crashes, or your component gets into a weird state where it
can't reload cleanly. Close the app and run ./build -m to move the safe dll to
the hot dll path and rerun the app.

## Implementation details ##
Watcher monitors the _dlls folder for updates and coordinates the reload process
with the components. The components use the hot module save and load macros to
persist data with Watcher.

To set up a component for reloading, the component needs to:
 - call hot.register which registers the component name with the Watcher node. Typically, done on or after `enter_tree()` so the component can find the Watcher.
 - hot.register has two versions. A simple register that is called with the component name, where the node expects to manage its own reload process, and a one where you can specify another node responsible for saving and reloading the component.
 - to persist data between reloads Watcher needs to call a saver proc and loader proc on nodes.
 - by default the saver proc is named `reload`, that returns seq[byte], with a {.gdExport.} pragma so Watcher can find it
 - the saver proc uses the hot.save macro to specify member fields to save e.g. `save(self.data)`. Valid data types are anything msgpack4nim accepts.
 - to reload the data, after registering you can call the hot.load macro like `register(comp)?.load(self.data)`. Watcher will return previously persisted data after a component is registered so the node can complete initialization.
 - for situations where you want to be able to reload a component but the responsiblity for persisting its data falls on some other component use the other register method. You might want to instance multiple copies of a component and group their data together for persistence. Watcher has a table for all persisted data indexed by the component name.

When a component is compiled it generates a library file (safe dll). If the godot editor is not in focus with the project opened the safe dll can be copied to the hot dll path. Otherwise, you'll get a warning that the dll can't be moved and reload will fail.

When the project application is running, update and build the components.
Watcher will check if safe dll is newer than hot dll and start a reload if so.

### Nim notes ###
The godot-nim library in deps has been customized to use the new gc ARC and prep it for future versions of nim.
Use the build script to generate the godotapi into the deps folder.
Gdnim, and the godot-nim bindings are built against nim's devel branch.

### Compiler notes ###
Gdnim also makes use of tcc, the [Tiny C Compiler](https://github.com/mirror/tinycc). It compiles much faster than gcc or vcc, but crashes when compiling with threads:on. Vcc and gcc both support threads. Clean builds with vcc and gcc are slow. Vcc can generate lots of warnings about incompatible types, while gcc requires some additional dlls to run. If you want to use gcc, see tasks.nim's final task where gcc dlls are checked.