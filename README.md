Warning: This repo has been tailored for my system. If you happen to find this,
feel free to customize it yourself.

# Gdnim #
gdnim bootstraps a [godot-nim](https://github.com/pragmagic/godot-nim) project,
with a customized build of godot-nim that enables easier project managment. It's
killer feature is automated, hot code reloading through the use of scenes as
resources for components and a Watcher node.

## Quick Start ##
 - Configure the build.ini for your setup
 - Compile the build script: nim c build
 - Build the godot binaries: ./build gdengine update
 - Generate the godot-nim bindings: ./build genapi
 - Build watcher and components: ./build cleanbuild
 - Generate a component specifying base class module: ./build my_comp node_2d
 - Modify components/my_comp.nim
 - Run editor: ./build gd
 - Run scene using component, make a modification to component: ./build
 - Hot reload should occur (check console or editor console for output)

### Main commands ###
 - Run Godot: ./build gd
 - Hot Reload your script (after modification): ./build
 - If you need to restart the app, build and move the dll with then run again: ./build -m

## Prerequites ##
  - VSCode
  - [custom version of godot 3.2](https://github.com/geekrelief/godot/tree/3.2_custom)
  - [Tiny C Compiler](https://github.com/mirror/tinycc) (fast compiles, but does not support threads)
  - [nim](https://github.com/nim-lang/Nim) v1.5.1+ which has gc:arc and bug fixes.
  - [msgpack4nim](https://nimble.directory/pkg/msgpack4nim)
  - [anycase](https://nimble.directory/pkg/anycase)
  - [PMunch optionsutils](https://github.com/PMunch/nim-optionsutils)
  - vcc, gcc (optional, but required for threads)

## Project Setup ##
Gdnim is like the [godot-nim-stub](https://github.com/pragmagic/godot-nim-stub)

It uses a customized build script and [custom version of godot 3.2](https://github.com/geekrelief/godot/tree/3.2_custom) which unloads gdnative libraries when their resource is no longer
referenced. It removes the dependency on nake and nimscript and is easier to
customize and understand than the godot-nim-stub. It also uses a custom version
of the godot-nim bindings in the deps/godot directory.

The project is developed and tested only on Windows.
Modify the build.ini, build.nim and tasks.nim script for your needs.
build.ini expects some paths to my godot 3.2 custom engine source and editor executables.

The app folder contains the stub godot project. Generated files are stored in
app/_dlls, app/_gdns, app/_tscn.  You create godot-nim classes in the components
folder, import the hot module to register the component with the Watcher module.
The watcher.gdns should autoload in the godot project.

See the temp_comp example in the components folder.

Use the build script to download the godot source, compile the engine, create
godot-nim bindings api, compile the watcher and components, etc.

## Tips ##
 - If the godot app crashes, or your component gets into a weird state where it
can't reload cleanly. Close the app and run ./build -m to move the safe dll to
the hot dll path and rerun the app.

## Implementation details ##
Watcher monitors the _dlls folder for updates and coordinates the reload process
with the components. The components use the hot module save and load macros to
persist data. To set up a component for reloading, the component needs to:
 - implement the method enter_tree, call hot.register with the component and optionally specify the save method
 - by default the save proc is named 'reload' that returns seq[byte], make sure to {.gdExport.} it
 - the save proc uses the hot.save macro to specify member fields to save
 - to reload the data, after registering you can call the hot.load macro if it exists like register(comp)?.load(self.data)

When a component is compiled it generates a nativescript file (gdns),
scene file (tscn), and a library file (safe dll). If the godot editor is in
focus with the project opened the safe dll cannot be copied to the hot dll path.

When the project application is running, update and build the components.
Watcher will check if safe dll is newer than hot dll and start a reload if so.

### Nim notes ###
The godot-nim library has been customized to use new gc ARC and removes
cruft code to support nim pre gc:arc/orc.
Use the build script to generate the godotapi into the deps folder.

Gdnim, and the godot-nim bindings are built against nim's devel branch.

### Compiler notes ###
Gdnim also makes use of tcc, the [Tiny C Compiler](https://github.com/mirror/tinycc).
It compiles much faster than gcc or vcc, but crashes when compiling with threads:on.
Vcc and gcc both support threads. Clean builds with vcc and gcc are slow.
Vcc can generate lots of warnings about incompatible types, while gcc
requires some additional dlls to run. See tasks.nim's final task.