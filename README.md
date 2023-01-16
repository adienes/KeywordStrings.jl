
# KeywordStrings

 
[![Build Status](https://github.com/adienes/KeywordStrings.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/adienes/KeywordStrings.jl/actions/workflows/CI.yml?query=branch%3Amain)

The goal is to provide a maximally-convenient API for string interpolation. This package exports essentially only one piece of machinery which is the macro `@kw_str` accessed either via a non-standard string literal (preferred) or a direct macro call.
```
julia> kw"Hello, $User!"
...
julia> @kw_str(raw"Hello, $User!")
```
Once a `KeywordString` has been created, it can be formatted with the `%` operator using any Julia object that has either keys or properties with the same names as the interpolated symbols in the input. Crucially, the symbols to interpolate do **not** have to be defined anywhere at the time of creating the string. Formatters can be called incrementally and composed arbitrarily; once all values have been concretely interpolated the `KeywordString` will become just a regular Julia `String`

### Basic Usage
Basic usage with a `NamedTuple`, also showcasing the incremental formatting.
```
julia> s = kw"Hello, $(name)! Your value is $value";
# a KeywordStrings object

julia> s %= (; name="Andy");
# still a KeywordStrings object

julia> s %= (; value=14)
"Hello, Andy! Your value is 14"
```
It will also work with `structs` 
```
julia> struct User
           name
           value
       end

julia> me = User("Andy", 14)
User("Andy", 14)

julia> s = kw"Hello, $(name)! Your value is $value" % me
"Hello, Andy! Your value is 14"
```

We can join a `KeywordString` with another using `*`, so just as for `String` composition works 
```
julia> kw"x=$x;" * kw"y=$y" % (; x=5, y=6)
"x=5;y=6"
```
And so does broadcasting
```
julia> users = [User(name, rand()) for name in ("Alice", "Bob", "Eve")];

julia> kw"$name is present" .% users
3-element Vector{String}:
 "Alice is present"
 "Bob is present"
 "Eve is present"
```
### Notes
Since any object with a `getproperty` or `getkey` method is supported, we can even do things like
```
julia> s % Base.@locals();
#or
julia> s % @__MODULE__;
```

And these get special syntax for creation, namely if the string literal ends in `$!`, `$¡`, or `$:`
```
julia> kw"...$!" #alias for kw"..." % Base.@locals()
julia> kw"...$¡" #alias for kw"..." % @__MODULE__
julia> kw"...$:" #alias for kw"..." % Base.@locals() % @__MODULE__
```
Where in particular appending `$:` should recover standard interpolation behavior
```
julia> name = "Andy"
"Andy"

julia> let value = 14
           kw"Hello, $(name)! Your value is $value$:"
       end
"Hello, Andy! Your value is 14"
```
### Limitations
 * This package was not written with speed as a priority. If you use these as a drop-in replacement for `Strings`, and your `String` operations are the bottleneck for performance, you will likely see reduced performance and larger allocations with `KeywordStrings`. That being said, the majority of the time `String` operations are not the bottleneck.
 * Syntax highlighting does not seem to work for non-standard string literals. This often is probably a good thing, like for the `Regex` strings, but when interpolation is the goal the absence of highlighting can make the strings (as written in code) harder to read.
