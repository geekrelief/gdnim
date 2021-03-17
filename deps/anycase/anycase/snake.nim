import anycase/words
from strutils import join, capitalizeAscii

proc snake*(str: string): string =
  let parts = words(str)

  return join(parts, "_")
