# Sizes

Check the size of files/folders in human readable output, ascending ordered by size in.

Usage:

```shell script
sizes.sh [-v] [-f filename]

f - Target this file/directory instead of the current directory
v - List the files in f (or current directory) instead of the directory itself
```

Example:
```shell script
sizes.sh -vf
```

Output:

```text
4.0K    /absolute/path/to/scripts/bash/sizes/README.md
4.0K    /absolute/path/to/scripts/bash/sizes/sizes.sh
```
