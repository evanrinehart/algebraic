# Algebraic Data Types

Includes a rogues gallery of basic (very basic) data structures and some
utility methods for them.

- Unit has only one value which carries no information.
- Wrap carries one dynamic value that you can unwrap. This lets you distinguish between nil and Wrap.new(nil).
- Option has two constructors, Option.some(x) is like Wrap and Option.none represents no value.
- Result has two Wrap-like constructors Result.ok(v) and Result.error(e).
- Nat has the nullary constructor Nat.z and the unary constructor Nat.s intended only to be used on other Nats.
- List is either List.empty or List.cons(x, list), which is like a payloads-carrying Nat.
- Boolean has two Unit-like values Boolean.t and Boolean.f and that's it.

## API

```
Unit.new : Unit

Wrap.new : a -> Wrap a
.unwrap  : Wrap a -> a

Boolean.t : Boolean
Boolean.f : Boolean
.not : Boolean -> Boolean
.to_b : Boolean -> Bool

Option.some : a -> Option a
Option.none : Option a
.default : Option a -> a -> a
.map : Option a -> Block a b -> Option b
.and_then : Option a -> Block a (Option b) -> Option b
.to_a : Option a -> [a]
.none? : Option a -> Bool
.first_option : [Option a] -> Option a
.cat_options : [Option a] -> [a]
(partial) .get_some : Option a -> a

Result.ok : a -> Result a b
Result.error : b -> Result a b
.error? : Result a b -> Bool
(partial) .get_ok : Result a b -> a
(partial) .get_error : Result a b -> b

Nat.z : Nat
Nat.s or .s : Nat -> Nat
.times : Nat -> Block a -> (Execute block n times and return nil)
.to_i : Nat -> Fixnum
.zero? : Nat -> Bool
.to_nat : Fixnum -> Nat
(partial) .pred : Nat -> Nat

List.empty : List a
List.cons : a -> List a -> List a
.empty? : List a -> Bool
.each : List a -> Block a b -> (Execute block for each element and return nil)
.map : List a -> Block a b -> List b
.to_a : List a -> [a]
.to_list : [a] -> List a
(partial) .uncons : List a -> (a, List a)
```

## Cases

Each ADT has a case method which is the basic way to safely destructure a value.

```
Option.some(3).case({
  some: ->(n){ n + 1 },
  none: ->{ 9999 }
})
=> 4
```

## Examples

```ruby
> Unit.new
=> Unit[]

> Wrap.new(3)
=> Wrap[3]

> Wrap.new(3).unwrap
=> 3

> Option.some(3)
=> Some[3]

> Option.some(3).default(9)
=> 3

> Option.none.default(9)
=> 9

> Option.some(3).map{|x| x+1 }
=> Some[4]

> Option.none.map{|x| x+1 }
=> None[]

> [Option.some("shoes"), Option.none, Option.some("apples")].cat_options
=> ["shoes", "apples"]

> [Option.none, Option.some("shoes"), Option.some("apples")].first_option
=> "shoes"

> [1,2,3].to_list
=> Cons[1, Cons[2, Cons[3, Empty[]]]]

> 5.to_nat
=> S[S[S[S[S[Z[]]]]]]

> 5.to_nat.s.s.s.to_i
=> 8

> 3.to_nat.times{ puts "shoes" }
shoes
shoes
shoes

> Result.ok(6).case({
  ok: ->(x){ "number x 10: #{x*10}" },
  error: ->(e){ "***ERROR: #{e}***" }
})
=> "number x 10: 60"

> Result.error("CRUD").case({
  ok: ->(x){ "number x 10: #{x*10}" },
  error: ->(e){ "***ERROR: #{e}***" }
})
=> "***ERROR: CRUD***"

> Result.error("CRUD").get_ok
Runtime Error: Error["CRUD"].get_ok

> Boolean.t.not.not.not
=> F[]
```

## User-defined ADTs

The core implementation of these data structures is so similar that I moved it
all into a super class and added a dynamic "DSL" so you can make new ones.
Create a new ADT by making a subclass of Algebraic and defining the alternatives
using an *is ... or ...* pattern as shown below. 

```ruby
class Suit < Algebraic
  est :club
  ou :diamond
  ou :spade
  ou :heart
end

> Suit.diamond
=> Diamond[]
```

Each alternative creates a new constructor as a class method. Also please
excuse the French because *or* is reserved. When you need more than one alternative
you can use French, German, or Spanish. Russian как / или also works.

The example below shows a binary search tree being defined with nodes that have
three payload elements.

```ruby
class Tree < Algebraic
  est :leaf
  ou :node, :tree, :x, :tree
end

> Tree.node Tree.leaf, 9, Tree.leaf
=> Node[Leaf[], 9, Leaf[]]
```

## FAQ

### What's the point of these classes?

- None
