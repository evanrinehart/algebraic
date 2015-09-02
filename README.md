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

The core implementation of these data structures is so similar that it would be
interesting to make a dynamic generator for them so you can make new ones.

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

> 5.s.s.s.to_i
=> 8

> 3.to_nat.times{ puts "shoes" }
shoes
shoes
shoes

> Result.ok(6).case({
  :ok => ->(x){ "number x 10: #{x*10}" },
  :error => ->(e){ "***ERROR: #{e}***" }
})
=> "number x 10: 60"

> Result.error("CRUD").case({
  :ok => ->(x){ "number x 10: #{x*10}" },
  :error => ->(e){ "***ERROR: #{e}***" }
})
=> "***ERROR: CRUD***"

> Result.error("CRUD").get_ok
Runtime Error: Error["CRUD"].get_ok

> Boolean.t.not.not.not
=> F[]
```

## FAQ

### What's the point of these classes?

- None
