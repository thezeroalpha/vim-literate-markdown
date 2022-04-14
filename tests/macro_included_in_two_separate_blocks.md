# Including a macro in two separate blocks
<!-- :Tangle(ruby) <^> DIRNAME/FILENAME.rb -->
```ruby
def whatever
    <<block 1>>
    <<block 2>>
end
```

<!-- :Tangle(ruby) <> <block 1> -->
```ruby
<<to include>>
puts x
```

<!-- :Tangle(ruby) <> <block 2> -->
```ruby
<<to include>>
x
```

<!-- :Tangle(ruby) <to include> -->
```ruby
x = "whatever"
```

