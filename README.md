Warning: This repo has been tailored for my system. If you happen to find this,
feel free to customize it yourself.

gdnim bootstraps a [godot-nim](https://github.com/pragmagic/godot-nim) project,
with a customized build of godot-nim that enables easier project managment. It's
killer feature is automated, hot code reloading through the use of scenes as
resources for components and a Watcher node.

Quick Start:
 - Compile the build script: nim c build
 - Build the godot binaries: ./build gdengine update fast release
 - Generate the godot-nim bindings: ./build genapi
 - Build watcher and components: ./build cleanbuild

*Prerequites:*
  - VSCode
  - [custom version of godot 3.2](https://github.com/geekrelief/godot/tree/3.2_custom)
  - [Tiny C Compiler](https://github.com/mirror/tinycc)
  - [nim](https://github.com/nim-lang/Nim) v1.5.1+ which has gc:arc and bug fixes.
  - [msgpack4nim](https://nimble.directory/pkg/msgpack4nim)
  - [anycase](https://nimble.directory/pkg/anycase)
  - [PMunch optionsutils](https://github.com/PMunch/nim-optionsutils)
  - vcc, gcc (optional)

It uses a customized build script and [custom version of godot 3.2](https://github.com/geekrelief/godot/tree/3.2_custom) which unloads gdnative libraries when their resource is no longer
referenced. It removes the dependency on nake and nimscript and is easier to
customize and understand than the godot-nim-stub.

The project is developed and tested only on Windows.
Modify the build.nim and tasks.nim script for your needs.
tasks.nim expects some environment variables for paths
to my godot 3.2 custom engine source and editor executables.

The app folder contains the godot project. Generated files are stored in
app/_dlls, app/_gdns, app/_tscn.  You create godot-nim classes in the components
folder, import the hot module to register the component with the Watcher module.
The watcher.gdns should autoload in the godot project.

Watcher monitors the _dlls folder for updates and coordinates the reload process
with the components. The components use the hot module save and load macros to
persist data. To set up a component for reloading, the component needs to:
 - in method enter_tree, call register with the component and optionally specify the save method
 - by default the save proc is a proc named 'reload' that returns seq[byte], make sure to {.gdExport.} it
 - the save proc uses the hot module's 'save' macro to specify member fields to save
 - to reload the data, after registering you can call the hot 'load' macro if it exists like register(comp)?.load(self.data)

See the temp_comp example in the components folder.

Use the build script to download the godot source, compile the engine, create
godot-nim bindings api, compile the watcher and components, etc.

When a component is compiled it generates a nativescript file (gdns),
scene file (tscn), and a library file (safe dll). If the godot editor is in
focuse with the project opened the safe dll cannot be copied to the hot dll path.

When the project application is running, update and build the components.
Watcher will check if safe dll is newer than hot dll and start a reload if so.

The godot-nim library has been customized to use new gc ARC and removes
cruft code pre nim 1.0. Use the build script to generate the godotapi into the
deps folder.

Gdnim, and the godot-nim bindings are built against nim's devel branch.

Gdnim also makes use of tcc, the [Tiny C Compiler](https://github.com/mirror/tinycc).
It compiles much faster than gcc or vcc, though the other compilers are also
available.  Vcc is quite slow and can generate lots of warnings, while gcc
requires some additional dlls to run. See tasks.nim's final task.
