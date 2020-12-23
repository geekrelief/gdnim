#TCC handleapi.h#

If it is missing, copy `handleapi.h` into your tcc `win32/include` folder if you're compiling for windows.

This is required for coroutine-like signal handling, which makes use of nim's `asynchdispatch` module when compiling for windows.