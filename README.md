![License: MIT](https://img.shields.io/badge/license-MIT-green) ![Arch: x86/ARM](https://img.shields.io/badge/arch-x86%2FARM-blue) ![Dependencies: clang](https://img.shields.io/badge/dependencies-clang-red) ![lang: C/bash](https://img.shields.io/badge/lang-bash%2FC-blueviolet)

# Working Documents

- https://docs.google.com/presentation/d/1biVTXz3gK39o9Dwn-jxoF9ux6jUNhgwwYWMy0ohwx8Q/edit?usp=sharing
- https://hackmd.io/bBzsgc8UQgaThXf8I4qtPw?both
- https://www.mathcha.io/editor/xqGoS6lfvrhP8zGO7cY9wg6zs20zne2U1Qzg7x (read only)

# Usage

When a special NAME for a bundle was introduced at link time, it can be called
(instead of the default plattform triple) with `PEXFILE NAME`.
If NAME was not introduced at link time, recompilation is forced from IR and the
resulting bundle is named NAME.

# Challenges

- Mismatching clang versions on origin and target can cause issues. For example clang version 3.8 cannot handle the ll files that are created by clang 6.0. The reason is that clang 6.0 adds a line with the `source_filename` to the ll file.
- Also `-g` (Compilerflag) does not work between at least those specific clang versions.


# Sources

https://www.linuxjournal.com/node/1005818