Here we have two different languages, which should be tangled to two different files.
<!-- :Tangle(python) DIRNAME/FILENAME.py -->
<!-- :Tangle(ruby) DIRNAME/FILENAME.rb -->

Define the Ruby method:

```ruby
def add(a,b)
  a+b
end
```

Define the Python method

```python
def add(a,b):
    return a+b
```

Call the Ruby method:

```ruby
puts add(1,2)
```

Call the Python method:

```python
print(add(1,2))
```

And some shell that will be ignored:

```sh
echo "We're done!"
```
