import anycase/words
from strutils import join

proc path*(str: string): string =
  let parts = words(str)

  return join(parts, "/")
