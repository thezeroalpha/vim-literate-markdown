# Indented tangle directive
Having indentation should not matter.

For example, let's say we have stuff in a list:
- Item one
    <!-- :Tangle DIRNAME/FILENAME.out -->
    ```sh
    echo 'this should tangle out.'
    ```
