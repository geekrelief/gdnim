import anycase/words
from strutils import join, capitalizeAscii
from sequtils import map, concat

proc camel*(str: string): string =
  let parts = words(str)
  let capitalizedParts = map(parts[1..parts.len - 1], capitalizeAscii)

  return join(concat([parts[0..0], capitalizedParts]))
