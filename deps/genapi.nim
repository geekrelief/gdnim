import parsecfg, os, strformat, godotapigen, strutils

var buildini = commandLineParams()[0].split("--ini:")[1]
var config = loadConfig(buildini)
let depsDir = config.getSectionValue("Dir", "deps")
let gd_bin = config.getSectionValue("Godot", "tools_release_bin")

removeDir(depsDir / "godotapi")

let apidir = depsDir / "godotapi"
createDir apidir
let cmd = &"{gd_bin} --gdnative-generate-json-api {apidir}/api.json"
if (execShellCmd cmd) != 0:
  echo &"Could not generate api with '{cmd}'"
  quit -1
genApi(apidir, apidir / "api.json")
removeFile(apidir / "api.json")
removeDir "logs"
