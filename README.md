# Gdnim #

gdnim is a testbed for experimental features for [godot-nim] projects that implements hot reloading of dlls as well as features for ease of development.

*NOTE*: This only works on Windows and Linux platforms so far. There's been a little work done to get it working for Mac, but a PR will be gladly accepted.

- [Gdnim](#gdnim)
  - [Why](#why?)
  - [Quick Setup Guide](#quick-setup-guide)
  - [Quick Dev Guide](#quick-dev-guide)
  - [Prerequisites](#prerequisites)
  - [Tips](#tips)
  - [Project Structure](#project-structure)
    - [Files and Folders](#files-and-folders)
  - [Setup](#setup)
  - [Tasks](#tasks)
  - [Implementation details](#implementation-details)
    - [Nim notes](#nim-notes)
    - [Compiler notes](#compiler-notes)

## Why? ##

The goal is to streamline and speed up the process of development for [godot-nim] by adding experimental features like:
  - hot reloading
  - match gdscript features, e.g.: signal declarations and async signal handling
  - experimental support for Nim (devel branch), e.g.: gc:ORC support, IC
  - (todo) support for Godot 4.0, e.g.: GDNative 4.0 (when it's stable)
  - reducing tedium / boilerplate:
    - file watcher recompiles on save
    - generation of files for scripts and editor plugins (.nim, .gdns, .tscn, etc)
    - generated Godot API includes exports for referenced classes. For example you don't need to `import godotapi / [scene_tree]` on `node` since node exports `scene_tree`.
    - automated nil'ing of references on `exit_tree`. You don't need to `self.myResource = nil` in `exit_tree`.

## Quick Setup Guide ##

 - Compile the build script: `nim c build`
 - Configure the `build.ini` with the location of godot bin files. If you have your own build of godot you can configure the repo source directory and use `./build gdengine`
 - See available tasks: `./build help`
 - Download Nim prerequisite libraries and generate the godot-nim bindings: `./build prereqs`
 - Build watcher and components: `./build cleanbuild`

## Quick Dev Guide ##
 - To **make a new nim component** run: `./build gencomp my_comp node_2d`. The nim file is created for you in `components` See [Setup](#setup) for details.
 - Edit as needed `components/my_comp.nim`
 - Build the component: `./build -m` (`-m` moves the dll to the hot dll path)
 - Launch godot editor with: `./build gd` (if this fails, launch godot manually, or see the [Setup](#setup) section)
 - Open, edit (as needed) and play the generated component scene file: `_tscn/my_comp.tscn`
 - Start the component file watcher for recompilation `./build cwatch`
 - Make a modification to component, the component watcher will rebuild the component.
 - Hot reload should occur if there were no compiler errors.
 - **Note:** The hot module contains save and load macros to persist state between reloads.

## Prerequisites ##
  - [godot engine 3.2.4+]: commit [311ca0c6 or newer](https://github.com/godotengine/godot/commit/311ca0c6f23784dfa831d8f058a335f698dcc5ea) has my patch merged for dll unloading or my custom repo [godot 3.2 custom]
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

## Tips ##
 - If the godot app crashes, or your component gets into a weird state where it can't reload cleanly. Close the app and run `./build -m` to move the safe dll to the hot dll path and rerun the app.
 - If the app is crashing when trying to reload, try force rebuilding the component `./build -f comp_name` or deleting the dll and rebuilding.
- If all else fails, `./build cleanbuild` to rebuild the dlls from scratch.
- Hot reloading makes use of components as sub-scenes. So the nativescript is attached to a node that isn't the root of a scene, when it gets reloaded, none of its children will be created. See `/app/scenes/main.tscn` and how it references the the other nodes from `/app/_tscn`.

## Project Structure ##
Gdnim uses a customized build script and [godot engine 3.2.4+] which unloads gdnative libraries when their resource is no longer referenced. It removes the dependency on nake and nimscript. Nimscript doesn't allow the use of exportc functions to check for file modification times. Gdnim also uses a custom version of the godot-nim bindings in the deps/godot directory, to begin future-proofing it for modern versions of nim (using GC ORC).

### Files and Folders ###
 - `app`: This is the godot project folder.
    - `app/_dlls`: Location for `./build` compiled, component libraries (.dll's, .so's). If you have other dlls you want to store here, modify tasks.nim. See `task cleandll`, or put your dlls somewhere else.
    - `app/_gdns`: Location for `./build gencomp` generated NativeScript files. These are checked and regenerated for each component nim file. So they're safe to delete when you want to remove a component.
    - `app/_tscn`: Location for `./build gencomp` generated tscn files. Customize these for your needs.
    - `app/scenes`: (Optional) Location for your own scenes to keep separate from _tscn.
 - `deps/godot`: Custom version of godot-nim bindings. You can move this and update the location in `build.ini`
 - `deps/tcc`: tcc header required on Windows for asyncdispatch
 - `build.nim`: The build script, compiled with `nim c build`, includes the `tasks.nim`
 - `tasks.nim`: Build tasks are specified here for updating / compiling the godot engine, generating / compiling  components, running the godot editor, etc. After modifying rebuild with `nim c build`.
 - `gdnim/watcher.nim`: The Watcher node that monitors changes to registered components. In a new godot project set `_tscn/watcher.tscn` to autoload in Project Settings.
 - `gdnim/hot.nim`: The module used by components to `register` with the Watcher node. Also has `save` / `load` macros for persisting data between reloads. When Watcher detects an updated dll, it calls the components' `hot_unload` callback to free references to components. Inside `proc hot_unload` the references to dll need to be freed. The `save` macro is used to serialize data with Watcher.  On `register`, Watcher will return the data as an `Option[MsgStream]`.  The `load` macro is used to deserialize the data. To deserialize the data, but ignore it a `!` can be prefixed to a symbol. For example:  If `save(self.speed, self.velocity)` was called in `hot_unload`, then `register(my_comp)?.load(self.speed, !self.velocity)`, will deserialize the types of `self.speed` and `self.velocity`, but `self.velocity` will not be assigned. This is used to reset values while preserving the serialization order between compiles/reloads.
 - `gdnim/utils.nim`: This module contains helper procs and macros.
 - `gdnim/gdnim.nim`: Loads and exports the gdnim `hot` and `utils` module.
 - `build.ini`: The default configuration file used to specify directories and settings. This is read at runtime. A different config file can be set using the `--ini` flag. Example: `./build --ini:my_config.ini cleanbuild`
 - `components`: Where nim component files live. Components must have unique identifiers. Dlls are generated from these components.
 - `components/tools`: Where nim files for tool / editor plugins go. Generated with `./build gentool my_tool_name`


## Setup ##
The project is primarily, developed and tested on Windows / Linux. (Mac support PR welcome).
Modify the `build.ini`, `build.nim` and `tasks.nim` script for your needs. `build.ini` expects some paths the godot engine repo and editor executables.

If you have all my mods from `build.ini`'s merge_branches in your git repo you can, run `./build gdengine update`.  Otherwise stick to using [godot engine 3.2.4+] and empty the merge_branches, and you can use `./build gdengine` to build the engine.

The `app` folder contains the stub godot project. You create "components" which are the classes that can reload by
running the `./build gencomp your_module_name godot_base_class_name`.  A nim file will appear in
the `components` folder. Generated files are stored in `app/_dlls`, `app/_gdns`, `app/_tscn`.
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

## Implementation details ##
Watcher monitors the `app/_dlls` folder for updates and coordinates the reload process
with the components. The components use the hot module save and load macros to
persist data with Watcher.

To set up a component for reloading, the component needs to:
 - call `hot.register` which registers the component name with the Watcher node. Typically, done when or after `enter_tree()` runs, so the component can find the Watcher. If you run `./build gencomp`, the template generated nim file will include register for you.
 - `hot.register` has two versions. A simple register that is called with the component name, where the node expects to manage its own reload process, and a one where you can specify another node responsible for saving and reloading the component.
 - to persist data between reloads Watcher needs to call a saver proc and loader proc on nodes.
 - by default the saver proc is a callback in your component class named `hot_unload`, that returns `seq[byte]`, with a `{.gdExport.}` pragma so Watcher can find it.
 - the saver proc uses the hot.save macro to specify member fields to save e.g. `save(self.data)`. Valid data types are anything msgpack4nim accepts.
 - the loader proc is only specified if the more complex register method is used.
 - to reload the data, after registering you can call the `hot.load` macro like `register(comp)?.load(self.data)`. Watcher will return previously persisted data after a component is registered so the node can complete initialization.
 - for situations where you want to be able to reload a component but the responsiblity for persisting its data falls on some other component pass the saver/loader node and saver/loader proc to `register`.  See the `hot.nim`. You might want to instance multiple copies of a component and group their data together for persistence. Watcher has a table for all persisted data indexed by the component name.
 - Components can be independently hot reloaded as long as they don't share an ancestor/descendant relationship in the scene hierarchy. If a component A has another component B as a descendant, you'll need to persist B's data when A is unloaded.

When a component is compiled it generates a library file (safe dll). If the godot editor is not in focus with the project opened the safe dll can be copied to the hot dll path. Otherwise, you'll get a warning that the dll can't be moved and reload will fail.

When the project application is running, update and build the components. Watcher will check if safe dll is newer than hot dll and start a reload if so.


### Nim notes ###
The godot-nim library in deps has been customized to use the new gc:ORC and prep it for future versions of nim. This is why ORC is suitable for games: https://nim-lang.org/blog/2020/12/08/introducing-orc.html
Use the build script to generate the godotapi into the deps folder.
Gdnim, and the godot-nim bindings are tested against the nim devel branch 3b963a81.

Avoid the `useMalloc` option with ORC. It'll eventually cause a crash.


### Compiler notes ###

 * GCC is the recommended compiler for most use cases. It supports all the features in gdnim, and is the middle of pack in terms of compilation speed.
   - Install gcc with scoop [scoop](https://scoop.sh/). Gcc will be in your user's ~/scoop/apps/gcc directory.
   - Or use the latest builds for MinGW64 here: http://winlibs.com/.

    gcc requires some additional dlls in the `_dlls` folder to run. Using gcc on Windows, tasks.nim's final task checks for a couple dll's to support threading.

 * VCC is only available on Windows.  It produces the smallest dlls, but has the longest compile times. Vcc + Visual Studio is useful for crash debugging purposes.

 * TCC [Tiny C Compiler](https://github.com/mirror/tinycc)
TCC has the fastest compile times, but crashes when compiling with threads:on. If compiling on windows, read `deps/tcc/README.md` to make tcc work with the `asynchdispatch` module. Tcc is not as well supported as the other compilers, and may not support all features of gdnim.


[godot engine 3.2.4+]:https://github.com/godotengine/godot
[godot-nim]:https://github.com/pragmagic/godot-nim
[godot-nim-stub]:https://github.com/pragmagic/godot-nim-stub
[godot 3.2 custom]:https://github.com/geekrelief/godot/tree/3.2_custom