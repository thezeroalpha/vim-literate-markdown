# Example 3
Example 3 from the Vim documentation.

<!-- :Tangle(python) <^> DIRNAME/FILENAME.py -->
```python
<<function definitions>>

def main():
    <<main code>>

if __name__ == '__main__':
    main()
```

<!-- :Tangle(python) <function definitions> -->
```python
def double(n):
    x = 2*n
    return x
```

<!-- :Tangle(python) <> <main code> -->
```python
<<n definition>>
print("Double of %d is %d" % (n, double(n)))
```

<!-- :Tangle(python) <n definition> -->
```python
n = 34.5
```
