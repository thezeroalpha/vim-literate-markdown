<!-- :Tangle(sh) DIRNAME/FILENAME.sh -->
# Simple macros
Testing simple macro tangling.

<!-- :Tangle(sh) <^>  -->
```sh
#!/bin/sh
<<mktemp and trap>>

<<define functions>>

<<main>>

<<untrap>>
```

We will work in a temporary directory:

<!-- :Tangle(sh) <mktemp and trap> -->
```sh
tempdir="$(mktemp -d)"
trap 'rm -r $tempdir' INT TERM EXIT
```

We want to also cancel the trap once we're ready to exit normally:

<!-- :Tangle(sh) <untrap> -->
```sh
rm -r "$tempdir"
trap - INT TERM EXIT
```

Now to define some functions.
First, a greeter:

<!-- :Tangle(sh) <define functions> -->
```sh
# args: name
greeter() {
  printf "Hello, %s!\n" "$1"
}
```

And an adder (wow I'm so creative):

<!-- :Tangle(sh) <define functions>+ -->
```sh
# args: numbers a,b to add
adder() {
  a="$1"
  b="$2"
  echo $((a+b)) > "$tempdir"/the_answer
}
```

Then we'll do some work and actually call the functions.

<!-- :Tangle(sh) <main> -->
```sh
greeter there
adder 23 19
```
