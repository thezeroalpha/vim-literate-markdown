#!/bin/sh
tempdir=$(mktemp -d)
trap 'rm -r $tempdir' INT TERM EXIT

# args: test_name
run_test() {
  # Create a subdirectory specific to this test
  testdir="$tempdir"/"$1"
  mkdir "$testdir"

  # Edit the tangle targets in the test files accordingly
  sed "/:Tangle/s!DIRNAME!$testdir!; /:Tangle/s!FILENAME!$1!" "$1".md > "$testdir"/"$1".md

  # Run the tangle command
  vim -c "Tangle | qall" "$testdir"/"$1".md

  # Compare all generated files with expected files
  find "$testdir" -type f -not -name "$1".md | while read -r f;  do
    difference="$(diff "$f" "./${f##*/}")"
    [ -n "$difference" ] && printf "Test %s FAILED.\nDiff expected vs actual:\n%s" "$1" "$difference"
  done
}

for i in all_in_one_file only_specific_language two_different_languages simple_macros; do run_test "$i"; done
# rm -r "$tempdir"
trap - INT TERM EXIT
