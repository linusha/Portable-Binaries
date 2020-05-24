https://docs.google.com/presentation/d/1biVTXz3gK39o9Dwn-jxoF9ux6jUNhgwwYWMy0ohwx8Q/edit?usp=sharing

# TODOs

- add command line options
	- output file
	- folder name (.pex/)
	- whether to remove temporary files
	- pass compiler options to clang
- test portability to and from PowerPC

# Changes to make to IR to get portability

-  remove lines starting with `source_filename` that get iontroduced when building the IR on ARM 
