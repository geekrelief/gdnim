import anycase/words
from strutils import join

proc plain*(str: string): string =
  let parts = words(str)

  return join(parts, " ")
