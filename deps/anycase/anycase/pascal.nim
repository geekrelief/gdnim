import anycase/words
from strutils import join, capitalizeAscii
from sequtils import map

proc pascal*(str: string): string =
  let parts = words(str)
  let capitalizedParts = map(parts, capitalizeAscii)

  return join(capitalizedParts)
