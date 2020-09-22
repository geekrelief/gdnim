task build, "build task":
  echo "build task"

task plugin, "plugin task":
  echo "plugin task calling buildTask "
  buildTask()