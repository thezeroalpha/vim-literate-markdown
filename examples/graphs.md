# Graphs
This is an example that I've actually used in my lecture notes.
Let's say I want to include a diagram, drawn programmatically.
First, I include the image:

![First diagram](first-diagram.dot.svg)

Then I can add the code, folded away in a `details` tag.

<details>
<summary>Graphviz code</summary>

<!-- :Tangle(dot) first-diagram.dot -->
```dot
graph t {
a -- b [label="x"]
a -- c [label="y"]
c -- d [label="y"]
c -- e [label="z"]
}
```

</details>

Then a second diagram, in the same way.

![Second diagram](second-diagram.dot.svg)

<details>
<summary>Graphviz code</summary>

<!-- :Tangle(dot) second-diagram.dot -->
```dot
digraph g {
a -> b
b -> a
}
```

</details>

Now in the markdown document, I just call `:Tangle` in Vim.
I close the markdown document window, and run `:windo make`.
My ftplugin for Dot files sets makeprg to `dot -Tsvg -O %`, which means the graphs will be simple to generate, and will be made with easily predictable filenames.
