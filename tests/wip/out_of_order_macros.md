# Out of order macros
<!-- :Tangle(ruby) <the block> -->
```ruby
x = "whatever"
```

<!-- :Tangle(ruby) <^> output.rb -->
```ruby
def something
    <<the block>>
    x
end
```
