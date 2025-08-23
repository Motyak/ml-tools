
# synopsis
./mlp.sh -o output_file input_file args...

# example
./mlp.sh -o myprog.ml myprog.mlp -I .

# omitting the -o option will create an associated %.ml file
# ,.. so this has the same effect as previous command
./mlp.sh myprog.mlp -I .

# you can also output in the stdout
./mlp.sh -o - myprog.mlp -I .

# diff mode allows you to compare a modified target file..
# ..with its original module once preprocessed
./mlp.sh diff -o myprog.ml myprog.mlp -I .
#        ^~~~~ just prefix the arguments with `diff`

---

Modules (.mlp files exporting symbols) should have their
`include` directives, if any, at the very top.

A `package main` line allows to separate <code to always export>
from <code to only export when pre-processing as the main file>.

There should be no `include` directive starting from the `package main` line.

---

# concat generated std.ml with existing src.ml to an output file
cat <(./mlp.sh -o - include/std.mlp -I include) src.ml > output.ml

# generate all std/ .ml files from their respective .mlp
for f in include/*.mlp; do ./mlp.sh $f -I include; done
