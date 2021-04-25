# Gdnim #

gdnim is a testbed for experimental features for [godot-nim] projects that implements hot reloading of dlls as well as features for ease of development.

**WARNING** gdnim is not battle tested / production ready. Use [godot-nim] if you need something stable.

*NOTE* A new macro `gdnim` was added to replace `gdobj` for defining classes. See the `gdobj` branch for the old samples.
*NOTE* This only works on Windows and Linux platforms so far. There's been a little work done to get it working for Mac, but a PR will be gladly accepted.

- [Gdnim](#gdnim)
  - [Why](#why?)
  - [Quick Setup Guide](#quick-setup-guide)
  - [Quick Dev Guide](#quick-dev-guide)
  - [Prerequisites](#prerequisites)
  - [Hot Reloading Switch](#hot-reloading-switch)
  - [Component Setup](#component-setup)
    - [Component Walkthrough](#component-walkthrough)
    - [Hot Reloading Sections](#hot-reloading-sections)
    - [Component Methods](#component-methods)
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
  - experimental support for Nim (devel branch), e.g.: gc:ORC support, IC
  - reducing tedium / boilerplate / error proneness:
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


## Quick Dev Guide ##
 - To **make a new nim component** run: `./build gencomp my_comp node_2d`. The nim file is created for you in `components` See [Setup](#setup) for details.
 - Edit as needed `components/my_comp.nim`
 - Build the component: `./build -m` (`-m` moves the safe dll to the hot dll path)
 - Launch godot editor with: `./build gd` (if this fails, launch godot manually, or see the [Setup](#setup) section)
 - Open, edit (as needed) and play the generated component scene file: `_tscn/my_comp.tscn`
 - Start the component file watcher for recompilation `./build cwatch`
 - Make a modification to component, the component watcher will rebuild the component.
 - Hot reload should occur if there were no compiler errors.
 - **Note:** The hot module contains save and load macros to persist state between reloads. See examples in `components`


## Prerequisites ##

  - [godot engine 3.x]: or my custom repo [godot 3.x custom]
  - [nim](https://github.com/nim-lang/Nim) use stable or devel 3b963a81,
    - the commit after breaks godot-nim. [bug report](https://github.com/pragmagic/godot-nim/issues/81)
  - Nim Libraries (downloaded with `./build prereqs`)
    - [compiler](https://nimble.directory/pkg/compiler)
    - [msgpack4nim](https://nimble.directory/pkg/msgpack4nim)
    - [anycase](https://nimble.directory/pkg/anycase)
    - [PMunch optionsutils](https://github.com/PMunch/nim-optionsutils)
  - gcc is the default
    - gcc, vcc, and tcc are supported
    - (see [Compiler notes](#compiler-notes) below for details on differences)
  - Windows only: https://github.com/microsoft/terminal used to launch the godot editor.


## Hot Reloading Switch ##
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

## Component Setup ##
Create a component by running `./build gencomp [name] [godot_class]`.  `name` is the name of your component, and `godot_class` is the class from which it derives. Both should be in snake_case.

For example `./build gencomp my_node node2d` generates a `my_node.nim` file in `/components`. And a matching tscn, gdns, and gdnlib file in the directories specified in `build.ini`.

To delete a component run: `./build delcomp [name]`.

New components are generated from template strings defined in `tasks.nim`. Customize it for your needs. Remember to recompile `./build` with `nim c build` with any change to `tasks.nim`.


## Component Walkthrough ##

By default, the `gdnim` macro is used to make hot reloading more convenient. `gdnim` is layered on top of the godot-nim `gdobj` macro. Let's examine an example component `gun.nim` to understand its parts.

```nim
import gdnim

gdnim Gun of Sprite:
  var
    bulletRes: PackedScene
    bulletSpawnPoint: Node2D
    nextBulletId {.gdExport.}: int64
    fireTime: float64
    fireInterval: float64 = 0.3

  unload:
    save()

  dependencies:
    bullet:
      self.bulletRes = load("res://_tscn/bullet.tscn") as PackedScene

  reload:
    self.bulletSpawnPoint = self.get_node("BulletSpawnPoint") as Node2D

    var button_fireSingle = self.get_parent().get_node("Button_FireSingle")
    discard button_fireSingle.connect("pressed", self, "fire_single")

  proc createBullet(v: Vector2, p: Vector2) =
    if self.bulletRes == nil: return
    var id = self.nextBulletId
    inc self.nextBulletId
    var b = self.bulletRes.instance()
    discard toV b.call("set_data", [id, v, p])
    self.get_tree().root.add_child(b)

  proc fire_single() {.gdExport.} =
    for i in 0..10:
      self.createBullet(vec2(120.0 + i.toFloat * 6.0, 0.0), self.bulletSpawnPoint.global_position)

    self.createBullet(vec2(120.0, 0.0), self.bulletSpawnPoint.global_position)
    self.createBullet(vec2(100.0, 0.0), self.bulletSpawnPoint.global_position)

  method process(delta: float64) =
    self.fireTime += delta
    if self.fireTime > self.fireInterval:
      self.createBullet(vec2(70.0, 0.0), self.bulletSpawnPoint.global_position)
      self.fireTime = 0

```

`gun.nim` was generated with `./build gencomp gun sprite`

```nim
import gdnim
gdnim Gun of Sprite:
```

Here we import `gdnim` which pulls in the `godot`, `hot`, and `utils` modules. The `godot` module comes from `godot-nim`, `hot` is gdnim's hot reloading code that works with `watcher.nim` in the Watcher node, `utils` has convenience procs for working with `godot-nim`.

The `gdnim` macro like `gdobj` implements a DSL with OO like features. Here `Gun` is a type that derives from `Sprite`.

```nim
  var
    bulletRes: PackedScene
    bulletSpawnPoint: Node2D
    nextBulletId {.gdExport.}: int64
    fireTime: float64
    fireInterval: float64 = 0.3
```

We define our variables here. Notice that `PackedScene` and `Node2D` are referenced here without an `import` statement. The `gdnim` macro processes variables to see if they are part of the godot api in `deps/godotapi` and generates an `import` statement for them automatically. If you use the `gdobj` macro you'll have to import the modules with an import statement like `import godotapi / [packed_scene, node2d]`.

`{.gdExport.}` not only makes a variable accessible in the godot editor, but will also be saved and restored by `Watcher` during reload. All properties of an `Object` are saved if they appear in `getPropertyListImpl()`.

Any variable compatible with Variant, except for those of VariantType.Object, are automatically saved.  If you need to save data that references Objects use the `save()/load()` macros.


### Hot Reloading Sections ###

Here we have sections that define our reloading behavior.

```nim

  unload:
    save()

  dependencies:
    bullet:
      self.bulletRes = load("res://_tscn/bullet.tscn") as PackedScene

  reload:
    self.bulletSpawnPoint = self.get_node("BulletSpawnPoint") as Node2D

    var button_fireSingle = self.get_parent().get_node("Button_FireSingle")
    discard button_fireSingle.connect("pressed", self, "fire_single")
```

In `unload`, we call `save()` which is a macro for saving special data that can't be automatically saved by Watcher . In this case, we don't do anything here, we could replace `save()` with `discard`. Behind the scenes, `unload` calls `self.queue_free()` to free the node and nils any references to objects like `bulletRes` automatically. If we wanted, we could pass any non-"ref object" data to `save()`. See the example from `bullet.nim` below.

`dependencies` references other components that `gun` depends on to work.  Here `bullet` is another component and we need to load a reference to its scene to instantiate it. If the `bullet` component reloads, `gun` must free its reference to `self.bulletRes`. This is done automatically for you via the `gdnim` macro. The code in `dependencies` for all dependent components is run in the `ready` method before code in `reload` so any references are accessible.

`reload` contains code that is run each time the component is loaded. It is placed in the `ready` method. If we wanted we could access the `self.bulletRes` reference safely here since `dependencies` runs its code first.

The last reloading section is `once`. Code in this section only runs in the very first load of a component **instance**. In other words, when a node is instanced `once` is run. If the node's component code needs to reload, `once` is skipped. If another node is created for the component again, `once` will run for the instance.

Here we have code from `bullet.nim`.

```nim
  var startTime: MonoTime

  once:
    self.startTime = getMonoTime()

  unload:
    save(self.startTime)

  reload:
    load(self.startTime)
```

When `bullet` is instanced we initialize `self.startTime` in `once`.  If it reloads we want to save its `startTime`, so it appears in roughly the same position it left off before the reload. In `unload` we call `save()` and pass in the identifier for the data we want to save `self.startTime`. The macro serializes the data using msgpack4nim as a string and returns it to Watcher for storage. In `reload`, when the component is reloaded the automatically serialized data is restored first before ready, then `load(self.startTime)` retrieves the data from Watcher, deserializes it and stores the value into `self.startTime`.

Generally, the identifiers you pass to `save()` and `load()` should match. If for some reason you want to reload and not restore some data you can prefix the identifier with `!`.

For example:

```nim

  var
    startTime: MonoTime
    endTime: MonoTime

  once:
    self.startTime = getMonoTime()

  unload:
    save(self.startTime, self.endTime)

  reload:
    load(self.startTime, !self.endTime)
```

Here we added another variable `endTime`, but we don't want to restore the `endTime` on reload. If you have auto saved properties you don't want restored, you'll have to manually reinitialize the value of the property on `reload`.

### Component Methods ###

Returning to `gun.nim`:

```nim
  proc createBullet(v: Vector2, p: Vector2) =
    if self.bulletRes == nil: return
    var id = self.nextBulletId
    inc self.nextBulletId
    var b = self.bulletRes.instance()
    discard toV b.call("set_data", [id, v, p])
    self.get_tree().root.add_child(b)

  proc fire_single() {.gdExport.} =
    for i in 0..10:
      self.createBullet(vec2(120.0 + i.toFloat * 6.0, 0.0), self.bulletSpawnPoint.global_position)

    self.createBullet(vec2(120.0, 0.0), self.bulletSpawnPoint.global_position)
    self.createBullet(vec2(100.0, 0.0), self.bulletSpawnPoint.global_position)
```

The `createBullet` proc creates a bullet using the `self.bulletRes` reference. We use `call` to access `bullet`'s `set_data` proc.  The `toV` is a helper macro in `utils.nim` that makes it cleaner to call a function with Variant arguments.

Notice `fire_single` has the `{.gdExport.}` pragma so we can `connect` to it. When calling `connect` Godot uses snake_case for its function names.

```nim
    discard button_fireSingle.connect("pressed", self, "fire_single")
```

So while `{.gdExport.}` will automatically convert CamelCase to snake_case, we stick with snake_case to avoid accidentally making the method name invisible to Godot.

```nim
  method process(delta: float64) =
    self.fireTime += delta
    if self.fireTime > self.fireInterval:
      self.createBullet(vec2(70.0, 0.0), self.bulletSpawnPoint.global_position)
      self.fireTime = 0
```

Finally, we have the `process` method. In Godot's Node class we have virtual functions https://docs.godotengine.org/en/stable/classes/class_node.html, like `_ready`, `_process`, `_input`, etc which `godot-nim` processes using `method`. Since nim does not allow underscores in front of identifiers, `godot-nim` automatically assumes methods are for virtual functions and binds the function with a prefixed underscore.

Unfortunately, Godot is not consistent with its virtual function names, and sometimes you'll find a virtual function without a prefixed underscore. To export the method name "as is", add a `{.gdExport.}` pragma to the method. See `components/tools/main_screen.nim` for an example.

## Tips ##
 - Flags used with `./build`
    - By default, builds any modified component `.nim` for hot reload.
    - `./build comp compName` is the same as `./build compName`. Only component `compName` is built.
    - `-m` or `--move`: `./build -m` builds and moves the dll from the safe to hot path. Use when the game is closed to prevent Watcher from reloading on start.
    - `-f` or `--force`: `./build -f` force builds the components.
    - `--ini:custom_build.ini`: pass in your own ini file for different build configurations.
 - If the godot app crashes, or your component gets into a weird state where it can't reload cleanly. Close the app and run `./build -m` to move the safe dll to the hot dll path and rerun the app.
 - If the app is crashing when trying to reload, try force rebuilding the component `./build -f comp_name` or deleting the dll and rebuilding.
- If all else fails, `./build cleanbuild` to rebuild the dlls from scratch.
- If you get some type of crash when running your game, you probably have a `NilAccess` error in your code.
- Another cause of crashes could be from calling Godot's virtual functions by accident.  For example, you might try calling `get` or `get_property_list`. This might cause a crash because `_get` and `_get_property_list` are virtual functions in Godot. In godot-nim, Godot's `_get` is mapped to godot-nim's `method get`, and Godot's `get` is mapped to godot-nim's `getImpl`.  See `deps/godotapi/objects.nim` for examples.

## Sample Projects ##
 - [HeartBeast's Action RPG](https://github.com/geekrelief/gdnim_hb_arpg)


## Project Structure ##
Gdnim uses a customized build script and [godot engine 3.x] which unloads gdnative libraries when their resource is no longer referenced. It removes the dependency on nake and nimscript. Nimscript doesn't allow the use of exportc functions to check for file modification times. Gdnim also uses a custom version of the godot-nim bindings in the deps/godot directory, to begin future-proofing it for modern versions of nim (using GC ORC).

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
   - **WARNING**: GDNative reloading of tool scripts is broken. If you enable and disable the plugin, or unfocus the editor window while the plugin is enabled which will cause the plugin to reload, you might get a crash. You also might get warnings about leaked resources, when the plugin is enabled while the editor is closed. As a workaround, gdnlib's reloadable flag is set to false, so the plugin will not reload when the editor is unfocused. To see your changes, close the editor and reopen after compilation.



## Project Setup ##
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
Watcher monitors the `app/_dlls` folder for updates and coordinates the reload process with the components. The components use the hot module save and load macros to persist data with Watcher.

**NOTE** Below details how to hot reloading works when using the `gdobj` macro.  Using the `gdnim` macro reduces the boilerplate for the setup, and does all this stuff for you. See the `gdobj` branch `components` for samples.

To set up a component for reloading, the component needs to:
 - call `hot.register` which registers the component name with the Watcher node. Typically, done when `ready()` runs, so the component can find the Watcher. If you run `./build gencomp`, the template generated nim file will include register for you.
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


## License ##
This project is licensed under the MIT license. Read [LICENSE](https://github.com/geekrelief/gdnim/blob/master/LICENSE) file for details.

Copyright (c) 2018 Xored Software, Inc.

Copyright (c) 2020 Don-Duong Quach

[godot engine 3.x]:https://github.com/godotengine/godot/tree/3.x
[godot-nim]:https://github.com/pragmagic/godot-nim
[godot-nim-stub]:https://github.com/pragmagic/godot-nim-stub
[godot 3.x custom]:https://github.com/geekrelief/godot/tree/3.x_custom