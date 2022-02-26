<!-- :Tangle(python) DIRNAME/FILENAME.py -->
This file has different languages.
Only python blocks should be tangled to the output file, everything else should be ignored.

The python:

```python
def some_method(x):
    print(x)
```

This should be ignored:

```sh
echo "Should not be tangled"
```

And this should be tangled:

```python
some_method(2)
# Here's a comment for good measure
```

And ignored:

```r
frame <- data.frame(somecol=c(1,2))
```
