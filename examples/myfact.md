# myfact: a C implementation of a factorial function
This file describes a C implementation of a factorial function.
It generates three files:

* `myfact.c`: the implementation of factorial
* `myfact.h`: the header file for factorial
* `main.c`: the main file, which includes and runs the factorial function

This is clearly over-engineered; it aims to only be an example of the power of literate programming.

If you want to generate the code, make sure you have the `vim-literate-markdown` plugin loaded in Vim.
Then, open this document in Vim, and run the command `:Tangle`.
The three files described above will be in the same directory as this file.

## The main file
The main file is pretty simple:

<!-- :Tangle <^> main.c -->
```c
<<main imports>>
int main() {
    <<call the function from the header file>>
    return 0;
}
```

As you can see, it just calls whatever we define in the header.

Now for the header -- let's do a factorial calculation.

## Factorial calculation
The factorial function is recursive.
We'll make use of the following mathematical definitions:

```
0! = 1
n! = n × (n-1)!
```

Let's have a basic definition of the function like this:

<!-- :Tangle <> <factorial function> myfact.c -->
```c
int myfact(int n) {
    <<base case>>
    <<recursive case>>
}
```

The base case is when n == 0: the result is 1.
Putting that into code:

<!-- :Tangle <base case> myfact.c -->
```c
if (n == 0) return 1;
```

Going from the mathematical definition, the recursive case calls the factorial function.
Like this:

<!-- :Tangle <recursive case> myfact.c -->
```c
return n*myfact(n-1);
```

The implementation file as a whole has this structure:

<!-- :Tangle <^> myfact.c -->
```c
// No imports necessary
<<factorial function>>
```

And its corresponding header file just has the prototype:

<!-- :Tangle myfact.h -->
```c
int myfact(int);
```

## Calling it from the main file
Back to the main file now.
We've written our factorial function in `myfact.h`.
So, first, we need to `#include` our header file:

<!-- :Tangle <main imports> main.c -->
```c
#include "myfact.h"
```

Then we need to call the factorial in the body of the main function:

<!-- :Tangle <call the function from the header file> main.c -->
```c
printf("The factorial of %d is %d\n", 5, myfact(5));
```

Of course, to be able to print, we need to include the IO header:

<!-- :Tangle <main imports>+ main.c -->
```c
#include <stdio.h>
```
