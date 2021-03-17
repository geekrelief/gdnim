import anycase/words
from strutils import join

proc kebab*(str: string): string =
  let parts = words(str)

  return join(parts, "-")
