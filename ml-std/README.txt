
# synopsis
./mlcpp.sh -o output_file input_file args...

# example
./mlcpp.sh -o myprog.ml myprog.mlp -I .

# omitting the -o option will create an associated %.ml file
# ,.. so this has the same effect as previous command
./mlcpp.sh myprog.mlp -I .

# you can also output in the stdout
./mlcpp.sh -o - myprog.mlp -I .

---

Modules (.mlp files exporting symbols) should have their
`#include`s, if any, at the very top, suceeding a `#pragma once`
to protect against multiple inclusion.

A `package main` line serves to separate between code to
always export from code to only export when pre-processing as the main file.

There should be no `#include` after the `package main` line.

---

# concat generated std.ml with existing src.ml to an output file
cat <(./mlcpp.sh -o - include/std.mlp -I include) src.ml > output.ml

# generate all std/ .ml files from their respective .mlp
for f in include/*.mlp; do ./mlcpp.sh $f -I include; done

