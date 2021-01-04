# Gdnim #

gdnim is a testbed for experimental features for [godot-nim] projects.  It relies on a [custom build][godot 3.2 custom] of the [godot engine] and [godot-nim] that enables hot reloading of dlls using a Watcher node and easier project managment.

It's also a testbed for experimental features that might never make it into [godot-nim].

*NOTE*: This only works on Windows and Linux platforms so far. There's been a little work done to get it working for Mac, but a PR will be gladly accepted.

- [Gdnim](#gdnim)
  - [Why](#why?)
  - [Quick Setup Guide](#quick-setup-guide)
  - [Quick Dev Guide](#quick-dev-guide)
  - [Prerequites](#prerequites)
  - [Project Structure](#project-structure)
    - [Files and Folders](#files-and-folders)
  - [Setup](#setup)
  - [Tasks](#tasks)
  - [Tips](#tips)
  - [Implementation details](#implementation-details)
    - [Nim notes](#nim-notes)
    - [Compiler notes](#compiler-notes)

## Why? ##

The goal is to streamline and speed up the process of development for [godot-nim] by adding experimental features like:
  - rapid iteration features: hot-reloading, (TODO) nimscript integration
  - match gdscript features, e.g.: signal declarations and async signal handling
  - experimental support for Nim (devel branch), e.g.: gc:ORC support, IC
  - experimental support for Godot 4.0, e.g.: GDNative 4.0 (when it's stable)
  - reducing tedium: auto-recompilation on save, auto-generation of artifacts like nim, gdns, tscn files; proc and macros to reduce boilerplate

Hopefully, some of this will make it back into godot-nim.
## Quick Setup Guide ##

 - Clone - [godot 3.2 custom]
     If this is looking stale, create an issue I'll update it with godot's latest commits
 - Compile the build script: `nim c build`
 - Configure the `build.ini` with the location of the [custom repo][godot 3.2 custom], etc.
 - See available tasks: `./build help`
 - Download Nim prerequisite libraries: `./build prereqs`
 - Build the godot binaries: `./build gdengine`
 - Generate the godot-nim bindings: `./build genapi`
 - Build watcher and components: `./build cleanbuild`

## Quick Dev Guide ##
 - Generate a new component specifying base class module, for example: `./build gencomp my_comp node_2d`
 - Modify `components/my_comp.nim`
 - Launch godot editor, and play your scene: `./build gd` (if this fails, launch godot manually, or see the [Setup](#setup) section)
 - Start the component file watcher for recompilation `./build cwatch`
 - Make a modification to component, the component watcher will rebuild the component.
 - Hot reload should occur if there were no compiler errors.
 - **Note:** The hot module contains save and load macros to persist state between reloads.

## Prerequites ##
  - VSCode
  - [godot 3.2 custom]
  - or [godot 3.2 with gdnative unload]
  - [nim](https://github.com/nim-lang/Nim) use stable or devel 3b963a81,
    - the commit after breaks godot-nim. [bug report](https://github.com/pragmagic/godot-nim/issues/81)
  - Nim Libraries (downloaded with `./build prereqs`)
    - [compiler](https://nimble.directory/pkg/compiler)
    - [msgpack4nim](https://nimble.directory/pkg/msgpack4nim)
    - [anycase](https://nimble.directory/pkg/anycase)
    - [PMunch optionsutils](https://github.com/PMunch/nim-optionsutils)
  - gcc is the recommended compiler for most cases
    - gcc, vcc, and tcc are supported
    - (see [Compiler notes](#compiler-notes) below for details on differences)

## Project Structure ##
Gdnim uses a customized build script and [a custom version of godot 3.2][godot 3.2 custom] merged with [godot 3.2 with gdnative unload] which unloads gdnative libraries when their resource is no longer referenced. It removes the dependency on nake and nimscript which can be buggy and limited. Nimscript doesn't allow the use of exportc functions to check for file modification times. Gdnim also uses a custom version of the godot-nim bindings in the deps/godot directory, to begin future-proofing it for modern versions of nim (using GC ORC).

### Files and Folders ###
 - `/app`: This is the godot project folder.
    - `/app/_dlls`: Location for `./build` compiled, component libraries (.dll's, .so's). If you have other dlls you want to store here, modify tasks.nim. See `task cleandll`, or put your dlls somewhere else.
    - `/app/_gdns`: Location for `./build gencomp` generated NativeScript files. These are checked and regenerated for each component nim file. So they're safe to delete when you want to remove a component.
    - `/app/_tscn`: Location for `./build gencomp` generated tscn files. Customize these for your needs.
    - `/app/scenes`: (Optional) Location for your own scenes to keep separate from _tscn.
 - `deps/godot`: Custom version of godot-nim bindings. You can move this and update the location in `build.ini`
 - `deps/tcc`: tcc stuff
 - `build.nim`: The build script, compiled with `nim c build`, includes the `tasks.nim`
 - `tasks.nim`: Build tasks are specified here for updating / compiling the godot engine, generating / compiling  components, running the godot editor, etc. After modifying rebuild with `nim c build`.
 - `watcher.nim`: The Watcher node that monitors changes to registered components. In a new godot project set watcher.gdns to autoload.
 - `hot.nim`: The module used by components to register with the Watcher node. Also has save / load macros for persisting data between reloads.
 - `build.ini`: Configuration file used to specify directories and settings. This is read at runtime.
 - `components`: Where nim component files live. Components must have unique identifiers. Dlls are generated from these components.


## Setup ##
The project is primarily, developed and tested on Windows / Linux. (Mac support PR welcome)
Modify the build.ini, build.nim and tasks.nim script for your needs.
build.ini expects some paths to my [godot 3.2 custom engine source][godot 3.2 custom] and editor executables.

If you have all my mods from build.ini's merge_branches in your git repo you can, run
`./build gdengine update`.  Otherwise stick to using 3.2_custom, which I update periodically
with commits from godot's 3.2 branch by rebasing.

The app folder contains the stub godot project. You create "components" which are the classes that can reload by
running the `./build gencomp your_module_name godot_base_class_name`.  A nim file will appear in
the components folder. Generated files are stored in `app/_dlls`, `app/_gdns`, `app/_tscn`.
Run the godot editor. The `watcher.tscn` should autoload in the godot project.

See the examples in the `components` folder.

See `./build help` for available tasks like downloading the godot source, compiling the engine, generating godot-nim bindings api, compiling the watcher and components, etc.

`./build gd` Launches the godot editor.  On Windows it spawns a terminal using Terminal. On Linux there
isn't a general way to support launching the editor from a terminal for all distributions
(as far as I know), so modify the `task gd` for your system.

## Tasks ##
  The build system consists of `build.nim`, `tasks.nim`, `build.nim.cfg` and `build.ini`.  `build.nim` includes `tasks.nim` and reads `build.ini` at runtime.  To compile the build system run: `nim c build`.

  Tasks are defined in `tasks.nim`.  You can customize it for your needs, just make sure to recompile. Changes to `build.ini` are picked up when `./build` executes. Find out what tasks are available by inspecting that file or running `./build help`

  By default running `./build` will build any components that have changed.  If you supply an argument with no task name: `./build my_comp` the argument is assumed to be a component.

## Tips ##
 - If the godot app crashes, or your component gets into a weird state where it can't reload cleanly. Close the app and run `./build -m` to move the safe dll to the hot dll path and rerun the app.
 - If the app is crashing when trying to reload, try force rebuilding the component `./build -f comp_name` or deleting the dll and rebuilding.
- If all else fails, `./build cleanbuild` to rebuild the dlls from scratch.


## Implementation details ##
Watcher monitors the `app/_dlls` folder for updates and coordinates the reload process
with the components. The components use the hot module save and load macros to
persist data with Watcher.

To set up a component for reloading, the component needs to:
 - call `hot.register` which registers the component name with the Watcher node. Typically, done when or after `enter_tree()` runs, so the component can find the Watcher. If you run `./build gencomp`, the template does this automatically.
 - `hot.register` has two versions. A simple register that is called with the component name, where the node expects to manage its own reload process, and a one where you can specify another node responsible for saving and reloading the component.
 - to persist data between reloads Watcher needs to call a saver proc and loader proc on nodes.
 - by default the saver proc is named `reload`, that returns `seq[byte]`, with a `{.gdExport.}` pragma so Watcher can find it
 - the saver proc uses the hot.save macro to specify member fields to save e.g. `save(self.data)`. Valid data types are anything msgpack4nim accepts.
 - to reload the data, after registering you can call the `hot.load` macro like `register(comp)?.load(self.data)`. Watcher will return previously persisted data after a component is registered so the node can complete initialization.
 - for situations where you want to be able to reload a component but the responsiblity for persisting its data falls on some other component pass the saver/loader node and saver/loader proc to `register`.  See the `components/gun.nim` example. You might want to instance multiple copies of a component and group their data together for persistence. Watcher has a table for all persisted data indexed by the component name.

When a component is compiled it generates a library file (safe dll). If the godot editor is not in focus with the project opened the safe dll can be copied to the hot dll path. Otherwise, you'll get a warning that the dll can't be moved and reload will fail.

When the project application is running, update and build the components.
Watcher will check if safe dll is newer than hot dll and start a reload if so.


### Nim notes ###
The godot-nim library in deps has been customized to use the new gc:ORC and prep it for future versions of nim. This is why ORC is suitable for games: https://nim-lang.org/blog/2020/12/08/introducing-orc.html
Use the build script to generate the godotapi into the deps folder.
Gdnim, and the godot-nim bindings are built against the nim devel branch.


### Compiler notes ###

 * GCC is the recommended compiler for most use cases. It supports all the features in gdnim, and is the middle of pack in terms of compilation speed.
   - Install gcc with scoop [scoop](https://scoop.sh/). Gcc will be in your user's ~/scoop/apps/gcc directory.
   - Or use the latest builds for MinGW64 here: http://winlibs.com/.

    gcc requires some additional dlls in the `_dlls` folder to run. Using gcc on Windows, tasks.nim's final task checks for a couple dll's to support threading.

 * VCC is only available on Windows.  It produces the smallest dlls, but has the longest compile times. Vcc + Visual Studio is useful for crash debugging purposes.

 * TCC [Tiny C Compiler](https://github.com/mirror/tinycc)
TCC has the fastest compile times, but crashes when compiling with threads:on. If compiling on windows, read `deps/tcc/README.md` to make tcc work with the `asynchdispatch` module. Tcc is not as well supported as the other compilers, and may not support all features of gdnim.



[godot engine]:https://github.com/godotengine/godot
[godot-nim]:https://github.com/pragmagic/godot-nim
[godot-nim-stub]:https://github.com/pragmagic/godot-nim-stub
[godot 3.2 custom]:https://github.com/geekrelief/godot/tree/3.2_custom
[godot 3.2 with gdnative unload]:https://github.com/geekrelief/godot/tree/3.2_gdnative_unload