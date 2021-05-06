# Gdnim #

gdnim is a testbed for experimental features for [godot-nim] projects that implements hot reloading of dlls as well as features for ease of development.

**WARNING** gdnim is not battle tested / production ready. Use [godot-nim] if you need something stable.

*NOTE* A new macro `gdnim` was added to replace `gdobj` for defining classes. See the `gdobj` branch for the old samples.

- [Gdnim](#gdnim)
  - [Why](#why?)
  - [Quick Setup Guide](#quick-setup-guide)
  - [Quick Dev Guide](#quick-dev-guide)
  - [Prerequisites](#prerequisites)
  - [Component Setup](#component-setup)
  - [Hot Reloading Setup](#hot-reloading-setup)
    - [Hot Reloading Switch](#hot-reloading-switch)
  - [Tips](#tips)
  - [Sample Projects](#sample-projects)
  - [Project Structure](#project-structure)
    - [Files and Folders](#files-and-folders)
  - [Project Setup](#project-setup)
  - [Tasks](#tasks)
  - [Implementation details](#implementation-details)
    - [Nim notes](#nim-notes)
    - [Compiler notes](#compiler-notes)
  - [License](#license)

## Why? ##

The goal is to streamline and speed up the process of development for [godot-nim] by adding experimental features like:
  - hot reloading
  - match gdscript features, e.g.: signal declarations, async signal handling, field accessors
  - support for modern Nim e.g.: gc:ORC support, IC
  - reducing boilerplate, error proneness:
    - file watcher recompiles on save
    - generation of files for scripts and editor plugins (.nim, .gdns, .tscn, etc)
    - generated Godot API includes exports for referenced classes. For example you don't need to `import godotapi / [scene_tree]` on `node` since node exports `scene_tree`, unless you want autocompletion from nimsuggest.
    - automatic nil'ing Godot types on `exit_tree` to stop console warnings. e.g.: `self.myResource = nil` in `exit_tree` is defined automatically.


## Quick Setup Guide ##

 - Compile the build script: `nim c build`
 - Configure the `build.ini` with the location of godot bin files. If you have your own build of godot you can configure the repo source directory and use `./build gdengine`
 - See available tasks: `./build help`
 - Download Nim prerequisite libraries and generate the godot-nim bindings: `./build prereqs`
 - Build watcher and components: `./build cleanbuild`

For a new project (sample code removed), branching from `master`: `./build init [branch_name]`


## Quick Dev Guide ##
 - To **make a new nim component** run: `./build gencomp my_comp node_2d`. The nim file is created for you in `components` See [Setup](#setup) for details.
 - Edit as needed `components/my_comp.nim`
 - Build the component: `./build -m` (`-m` moves the safe dll to the hot dll path)
 - Launch godot editor with: `./build gd` (if this fails, launch godot manually, or see the [Setup](#setup) section)
 - Open, edit (as needed) and play the generated component scene file: `_tscn/my_comp.tscn`
 - Start the component file watcher for recompilation `./build cwatch`
 - Make a modification to component, the component watcher will rebuild the component.
 - Hot reload should occur if there were no compiler errors.


## Prerequisites ##

  - [godot engine 3.x]: or my custom repo [godot 3.x custom]
  - [nim](https://github.com/nim-lang/Nim) use stable or devel 3b963a81,
    - the commit after breaks `{.pure.}`. [bug report](https://github.com/nim-lang/Nim/issues/16462)
  - Nim Libraries (downloaded with `./build prereqs`)
    - [compiler](https://nimble.directory/pkg/compiler)
    - [msgpack4nim](https://nimble.directory/pkg/msgpack4nim)
    - [PMunch optionsutils](https://github.com/PMunch/nim-optionsutils)
  - gcc is the default
    - gcc, vcc, and tcc are supported
    - (see [Compiler notes](#compiler-notes) below for details on differences)
  - Windows only: https://github.com/microsoft/terminal used to launch the godot editor.

## Component Setup ##
Create a component by running `./build gencomp [name] [godot_class]`.  `name` is the name of your component, and `godot_class` is the class from which it derives. Both should be in snake_case.

For example `./build gencomp my_node node_2d` generates a `my_node.nim` file in `/components`. And a matching tscn, gdns, and gdnlib file in the directories specified in `build.ini`.

To delete a component run: `./build delcomp [name]`.

New components are generated from template strings defined in `tasks.nim`. Customize it for your needs. Remember to recompile `./build` with `nim c build` with any change to `tasks.nim`.

## Hot Reloading Setup ##
The `gdnim` macro is a layer over godot-nim's `gdobj` macro that interacts with the `Watcher` to enable hot reloading. There are four sections to consider when setting up for hot reloading.

 - `first:` Takes a body of code that is only run during initialization. It executes at the top of `enter_tree`.
 - `dependencies:` Declares other components as dependencies. Used when referencing other component instances. If references to other components are held but not defined in `dependencies` hot reloading will fail if the dependency needs to reload.
 - `unload:` Used to perform data serialization for data that can't be saved as a `{.gdExport.}`. Call the `save()` macro to store the data with Watcher.
 - `reload:` Declares that the component is hot reloadable. This takes a body of code that is run on a the top of `enter_tree`, but after `first`. Call the `load()` macro to retrieve any data stored with Watcher via `save()`.

 You can choose not to define the `enter_tree` method and put its code inside the `reload:` section.

 You can use the proc `isNewInstance()` to check the reloading state of a component instance. This is useful for initialization or adding children dynamically.

### Hot Reloading Switch ###
A top level `gdnim` macro is implemented to replace the use of `gdobj`. See below for [implementation details](#implementation-details)

- **Hot reloading** makes use of components as sub-scenes.  A component is a unit that has a `.tscn` scene file, with the root node containing the `.gdns` nativescript attached, pointing to the `.nim` code file generated dynamic library. The correct setup for reloading is a hierarchy of scenes. See `/app/scenes/main.tscn` and how it references the other component scenes from `/app/_tscn`.
- In the autoload settings, the Watcher scene is loaded which monitors the `/app/_dlls` folder for changes.
- Setup a component properly for reloading, use the `gdnim` macro to define your class.

See `components` for samples on how to set things up for reloading.

- **Disable hot reloading** This will stop compilation of the Watcher, delete the Watcher files, and disable the reloading parts of the components.
  - Edit `build.ini`, under `[Hot]`, set `reload="off"`.
  - Do a clean build. `./build cleanbuild`
  - Modify `project.godot` `Autoload` so the Watcher isn't loaded.

- **Re-enable hot reloading**
  - Edit `build.ini`, under `[Hot]`, set `reload="on"`.
  - Do a clean build. `./build cleanbuild`
  - Modify `project.godot` `Autoload` so the Watcher is loaded.  Select `_tscn/watcher.tscn` to load.

## Tips ##
 - Flags used with `./build`
    - By default, builds any modified component `.nim` for hot reload.
    - `./build comp compName` is the same as `./build compName`. Only component `compName` is built.
    - `./build` will build all changed components for hot reloading.
    - `-m` or `--move`: `./build -m` builds and moves the dll from the safe to hot path. Use when the game is closed to prevent Watcher from reloading on start.
    - `-f` or `--force`: `./build -f` force builds the components.
    - `--ini:custom_build.ini`: pass in your own ini file for different build configurations.
 - If the godot app crashes, or your component gets into a weird state where it can't reload cleanly. Close the app and run `./build -m` to move the safe dll to the hot dll path and rerun the app.
 - If the app is crashing when trying to reload, try force rebuilding the component `./build -f comp_name` or deleting the dll and rebuilding.
 - If all else fails, `./build cleanbuild` to rebuild the dlls from scratch.
### Debugging Crashes ###
 - On Windows you can get a stacktrace of a crash if you use `vcc` as the compiler and set the `build_kind` to `debug`.
- If you get some type of crash when running your game, you probably have a `NilAccess` error in your code. Using the `ifValid` macro in `utils` you can wrap your code in a nil check, and it'll print to the console if a nil access is detected. You can do toggle the output with `build.ini`'s `verbose_nil_check`.
- Another cause of crashes could be from calling Godot's virtual functions by accident.  For example, you might try calling `get` or `get_property_list`. This might cause a crash because `_get` and `_get_property_list` are virtual functions in Godot. In godot-nim, Godot's `_get` is mapped to godot-nim's `method get`, and Godot's `get` is mapped to godot-nim's `getImpl`.  See `deps/godotapi/objects.nim` for examples.

## Sample Projects ##
 - [HeartBeast's Action RPG](https://github.com/geekrelief/gdnim_hb_arpg) (old but shows how you can breakdown a project into components)


## Project Structure ##
Gdnim uses a customized build script and [godot engine 3.x] which unloads gdnative libraries when their resource is no longer referenced. It removes the dependency on nake and nimscript, but requires you to recompile `build.nim` if you change `build.nim` or `tasks.nim`. Gdnim also uses a custom version of the godot-nim bindings in the deps/godot directory.

### Files and Folders ###
 - You can customize the location of folders in `build.ini`.
 - `app`: This is the godot project folder.
    - `app/_dlls`: Location for `./build` compiled, component libraries (.dll's, .so's). If you have other dlls you want to store here, modify tasks.nim. See `task cleandll`, or put your dlls somewhere else.
    - `app/_gdns`: Location for `./build gencomp` generated NativeScript files. These are checked and regenerated for each component nim file. So they're safe to delete when you want to remove a component.
    - `app/_tscn`: Location for `./build gencomp` generated tscn files. Customize these for your needs.
    - `app/scenes`: (Optional) Location for your own scenes to keep separate from _tscn.
 - `deps/app`: A blank godot project used when creating a new project with `./build init`.
 - `deps/godot`: Custom version of godot-nim bindings. You can move this and update the location in `build.ini`
 - `deps/tcc`: tcc header required on Windows for asyncdispatch
 - `deps/watcher`: scene files for Watcher. When `reload` is re-enabled, the Watcher scene files are copied from here to `app`.
 - `build.nim`: The build script, compiled with `nim c build`, includes the `tasks.nim`
 - `tasks.nim`: Build tasks are specified here for updating / compiling the godot engine, generating / compiling  components, running the godot editor, etc. You can modify the templates used to generate component files up top. After modifying rebuild with `nim c build`.
 - `gdnim/watcher.nim`: The Watcher node that monitors changes to registered components. In a new godot project set `_tscn/watcher.tscn` to autoload in Project Settings.
 - `gdnim/gdnim.nim`: Included in every component, imports and exports godot-nim and stuff below.
    - `gdnim/globals.nim`: Defines constants and symbols used for hot reloading and Watcher signals.
    - `gdnim/hot.nim`: The module implements the `gdnim`, `save`, `load` and other macros to make interacting with Watcher and hot reloading easier.
    - `gdnim/utils.nim`: This module contains helper procs and macros.
 - `build.ini`: The default configuration file used to specify directories and settings. This is read when `./build` is run. A different config file can be set using the `--ini` flag. Example: `./build --ini:my_config.ini cleanbuild`
 - `components`: Where `.nim` component files live. Components must have unique identifiers across the project. Dlls are generated from these components.
 - `components/tools`: Where nim files for tool / editor plugins go. Generated with `./build gentool my_tool_name`
   - **WARNING**: GDNative reloading of tool scripts is broken. If you enable and disable the plugin, or unfocus the editor window while the plugin is enabled which will cause the plugin to reload, you might get a crash. You also might get warnings about leaked resources, when the plugin is enabled while the editor is closed. As a workaround, gdnlib's reloadable flag is set to false, so the plugin will not reload when the editor is unfocused. To see your changes, close the editor and reopen after compilation.


## Project Setup ##
Modify the `build.ini`, `build.nim` and `tasks.nim` script for your needs. `build.ini` expects some paths the godot engine repo and editor executables.

If you're not interested in building godot from source, you can use Godot 3.x and ignore the `./build gdengine` command. If you want to use `./build gd` or `./build play` to launch the editor or app fill out the paths to your editor binaries.

The rest of the settings under `build.ini`'s `[Godot]` section are for building godot from source.
If you have all my mods from `build.ini`'s merge_branches in your git repo you can, run `./build gdengine update`.  Otherwise stick to using [godot engine 3.x].

The `app` folder contains the godot project. You can use `./build init branch_name` to create a new gdnim project on a new branch.

You create "components" which are the classes that can reload by running the `./build gencomp your_module_name godot_base_class_name`.  A nim file will appear in the `components` folder. Generated files are stored in `app/_dlls`, `app/_gdns`, `app/_tscn`.

See the examples in the `components` folder.

See `./build help` for available tasks like downloading the godot source, compiling the engine, generating godot-nim bindings api, compiling the watcher and components, etc.

`./build gd` Launches the godot editor.  On Windows it spawns a terminal using Terminal. On Linux there
isn't a general way to support launching the editor from a terminal for all distributions
(as far as I know), so modify the `task gd` for your system.


## Tasks ##
xxx  The build system consists of `build.nim`, `tasks.nim`, `build.nim.cfg` and `build.ini`.  `build.nim` includes `tasks.nim` and reads `build.ini` at runtime.  To compile the build system run: `nim c build`.

  Tasks are defined in `tasks.nim`.  You can customize it for your needs, just make sure to recompile. Changes to `build.ini` are picked up when `./build` executes. Find out what tasks are available by inspecting that file or running `./build help`

  By default running `./build` will build any components that have changed.  If you supply an argument with no task name: `./build my_comp` the argument is assumed to be a component.


## Implementation details ##
Watcher monitors the `app/_dlls` folder for updates and coordinates the reload process with the components. The components use the hot module save and load macros to persist data with Watcher.

**NOTE** Below details how to hot reloading works when using the `gdobj` macro.  Using the `gdnim` macro reduces the boilerplate for the setup, and does all this stuff for you. See the `gdobj` branch `components` for samples.

To set up a component for reloading, the component needs to:
 - Call `hot.register_instance` which registers the component name with the Watcher node. Typically, done when godot's `Node.enter_tree()` runs, so the component can find the Watcher. The `gdnim` macro defines this if you have a `reload:` section.
 - To persist data between reloads Watcher uses PackedScenes and calls `proc hot_unload(): seq[byte] {.gdExport.}` on the Node to serialize custom data. The `gdnim` macro defines `hot_unload` with the `unload:` section.
 - Inside `hot_unload` the `hot.save()` macro is used to specify member fields to save.
 - To reload custom data, after registering you can call the `hot.load` macro like `register_instance(comp)?.load(self.data)`. Watcher will return previously persisted data after a component is registered so the node can complete initialization.
 - Components can be independently hot reloaded as long as they don't share an ascendant/descendant relationship in the scene hierarchy. If a component A has another component B as a descendant, a dependency needs to be defined between the components.

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


## License ##
This project is licensed under the MIT license. Read [LICENSE](https://github.com/geekrelief/gdnim/blob/master/LICENSE) file for details.

Copyright (c) 2018 Xored Software, Inc.

Copyright (c) 2020 Don-Duong Quach

[godot engine 3.x]:https://github.com/godotengine/godot/tree/3.x
[godot-nim]:https://github.com/pragmagic/godot-nim
[godot-nim-stub]:https://github.com/pragmagic/godot-nim-stub
[godot 3.x custom]:https://github.com/geekrelief/godot/tree/3.x_custom