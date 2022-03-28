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
    [ -n "$difference" ] && printf "Test %s FAILED.\nDiff expected (%s) vs actual (%s):\n%s" "$1" "$f" "./${f##*/}" "$difference"
  done
}

test_block_exec() {
  die() { printf '%s\n' "$1" >&2 && exit 1; }

  testdir="$tempdir"/exec_block
  mkdir "$testdir"
  cp exec_block.md "$testdir"/exec_block.md

  # Run both blocks and check for expected output
  vim -c 'silent 9 | ExecPrevBlock | $ | ExecPrevBlock | wqall' "$testdir"/exec_block.md
  [ "$(sed -n 12p "$testdir"/exec_block.md)" = 'Correct!' ] || die "Test exec_block FAILED. Did not find 'Correct!'"
  grep "^$(whoami).*grep vim" "$testdir"/exec_block.md >/dev/null 2>&1 || die "Test exec_block FAILED. Did not find 'grep vim' in process list"

  # Change the second block & test for expected output
  vim -c '17norm A | grep -v grep' -c '17 | ExecPrevBlock | wqall' "$testdir"/exec_block.md
  grep "^$(whoami).*grep vim" "$testdir"/exec_block.md >/dev/null 2>&1 && die "Test exec_block FAILED. Found 'grep vim' in process list when running second time"
}

# Run the tests
test_block_exec
for i in all_in_one_file only_specific_language two_different_languages simple_macros example_1 example_2 example_3 indented_tangle_directive; do run_test "$i"; done

rm -r "$tempdir"
trap - INT TERM EXIT
