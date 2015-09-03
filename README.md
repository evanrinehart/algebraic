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
    self.case(
      some: ->(x){ x },
      none: ->{ d }
    )
  end

  def to_a
    self.case(
      some: ->(x){ [x] },
      none: ->{ [] }
    )
  end

  def map &block
    self.case(
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
  diamond: ->{ 5 },
  spade:   ->{ 1 },
  _:       ->{ 0 }
)
=> 5
```

The linked list is a classic structure for sequential data and can be used
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
      cons:  ->(x, xs){ x },
      empty: ->{ raise "Empty[].pop" }
    )
  end
end

> stack = List.empty.push(1).push(2).push(3)
=> Cons[3, Cons[2, Cons[1, Empty[]]]]

> stack.pop
=> 3
```

## Recursion Trouble

Many utility functions for recursive structures like the list are easily
implemented behind the scenes using recursion. However this won't be efficient
in Ruby because each recursive call that doesn't return causes a frame to be
pushed on the runtime's call stack. To traverse structures you will have to
implement a traversal method like shown on a case by case basis.

```ruby
class List < Algebraic
  est :empty
  ou :cons, :x, :list

  def each &block
    node = self
    loop do
      x,nextNode = node.case(  
        empty: ->{ nil },
        cons: ->(x,xs){ [x,xs] }
      )
      if x
        block.call x
        node = nextNode
      else
        return nil
      end
    end
  end

  def length
    n = 0
    self.each do |x|
      n = n + 1
    end
    n
  end

  def to_a
    a = []
    self.each do |x|
      a.push x
    end
    a
  end

  def map &block
    l = List.empty
    self.to_a.reverse.each do |x|
      l = List.cons block.call(x), l
    end
    l
  end

  def bad_map &block
    self.case(
      empty: ->{ List.empty },
      cons: ->(x,xs){ List.cons block.call(x), xs.bad_map(&block) }
    )
  end
end

> l = List.empty
> 100000.times{ l = List.cons 1, l }
> l.bad_map{|x| x+1}.length
SystemStackError: stack level too deep

> l.map{|x| x+1}.length
100000
```

