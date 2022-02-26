#!/bin/sh

tempdir="$(mktemp -d)"
trap 'rm -r $tempdir' INT TERM EXIT


# args: name
greeter() {
  printf "Hello, %s!\n" "$1"
}

# args: numbers a,b to add
adder() {
  a="$1"
  b="$2"
  echo $((a+b)) > "$tempdir"/the_answer
}


greeter there
adder 23 19


rm -r "$tempdir"
trap - INT TERM EXIT
