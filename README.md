https://docs.google.com/presentation/d/1biVTXz3gK39o9Dwn-jxoF9ux6jUNhgwwYWMy0ohwx8Q/edit?usp=sharing

# TODOs

- add command line options
	- output file
	- folder name (.pex/)
	- whether to remove temporary files
	- pass compiler options to clang
- test portability to and from PowerPC
- enforce same clang version on origin and target systems


# Challenges

- Mismatching clang versions on origin and target can cause issues. For example clang version 3.8 cannot handle the ll files that are created by clang 6.0. The reason is that clang 6.0 adds a line with the `source_filename` to the ll file.
