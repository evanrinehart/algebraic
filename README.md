# Algebraic Data Types

Includes a inheritable superclass to create user-defined algebraic data types
using ruby dynamic programming.

## Example

The pair is the simplest non-trivial data structure. This example shows that
*is* creates a constructor and an instance variable containing the packed
payload. The argument names `:x` and `:y` are just for your information and don't
have any effect.

```ruby
class Pair < Algebraic
  is :pair, :x, :y

  def left
    @pair[0]
  end

  def right
    @pair[1]
  end
end

> Pair.pair 37, "shoes"
=> Pair[37, "shoes"]
```

In this example I create a safe wrapper for a result which may be missing.
Something like this has the benefit of allowing the value nil to be
distinguished from "no value" if necessary. *or* is a reserved word so I have
to use French. (Or you can use German or Spanish. Russian как / или also works.)

```ruby
class Option < Algebraic
  est :some, :x
  ou :none

  def default d
    case(
      some: ->(x){ x },
      none: ->{ d }
    )
  end

  def to_a
    case(
      some: ->(x){ [x] },
      none: ->{ [] }
    )
  end

  def map &block
    case(
      some: ->(x){ Option.some block.call(x) },
      none: Option.none
    )
  end

  class ::Array
    def head
      self.empty? ? Option.none : Option.some(self.first)
    end
  end
end

> Option.some 9
=> Some[9]

> Option.some(9).default(40)
=> 9

> Option.none.default(40)
=> 40

> [].head
=> None[]

> [nil].head
=> Some[nil]
```


This is a basic enum class with four possibilities. Each Algebraic subclass
has the case method which is the go-to technique for safely destructing or
making decisions based on an alternative. The _ case will trigger for any
instance.

```ruby
class Suit < Algebraic
  est :club
  ou :diamond
  ou :spade
  ou :heart
end

> suit = Suit.diamond
=> Diamond[]

> pointValue = suit.case(
  diamond: ->{ 5 }
  spade:   ->{ 1 }
  _:       ->{ 0 }
)
=> 5
```

The linked list is a classic structure for seqential data and can be used
as a stack.

```ruby
class List < Algebraic
  est :empty
  ou :cons, :x, :list

  def push x
    List.cons x, self
  end

  def pop
    case(
      cons:  ->(x, xs){ x }
      empty: ->{ raise "Empty[].pop" }
    )
  end
end

> stack = List.empty.push(1).push(2).push(3)
=> Cons[3, Cons[2, Cons[1, Empty[]]]]

> stack.pop
=> 3
```
