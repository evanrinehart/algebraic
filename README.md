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

  def to_a
    @pair
  end

  def unpack &block
    block.call *@pair
  end

end

> Pair.pair 37, "shoes"
=> Pair[37, "shoes"]

> Pair.pair(37,"lo").unpack{|a,b| b * a }
=> "lololololololololololololololololololololololololololololololololololololo"

> Pair.new true, nil # when there is only one ctor new works
=> Pair[true, nil]
```

Unfortunately you can't use *or* without dynamically rewriting the syntax of
your classes. But the following words can all be used for either *is* or *or*.
They all do the same thing. For example you can avoid the language issue
entirely by writing alt for all the cases.

- `is est ist es как estas`
- `orr ou oder o или au aŭ aux`
- `alt`

This is a basic enum class with four possibilities. Each Algebraic subclass
has the case method which is the go-to technique for safely destructing or
making decisions based on an alternative. The _ case will trigger for any
instance.

```ruby
class Suit < Algebraic
  alt :club
  alt :diamond
  alt :spade
  alt :heart
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

In the next example I create a safe wrapper for a result which may be missing.
Something like this has the benefit of allowing the value nil to be
distinguished from "no value" if necessary.

```ruby
class Option < Algebraic

  is :some, :x
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


The linked list is a classic structure for sequential data and can be used
as a stack. Here I also demonstrate that providing a class as one of the
arguments will provide a rudimentary runtime check for that argument.
Boolean is an ad-hoc dummy class which will match TrueClass or FalseClass.

```ruby
class List < Algebraic
  est :empty
  ou :cons, :x, List

  def push x
    List.cons x, self
  end

  def pop
    self.case(
      cons:  ->(x, xs){ x },
      empty: ->{ raise "Empty[].pop" }
    )
  end
end

> stack = List.empty.push(1).push(2).push(3)
=> Cons[3, Cons[2, Cons[1, Empty[]]]]

> stack.pop
=> 3

> List.cons 99, nil
ArgumentError: argument 2 must be a List, was provided a NilClass
```

The rogues gallery of simple algebraic types:

```ruby
class Unit < Algebraic
  is :unit
end

class Bool < Algebraic
  alt :t
  alt :f
end

class Pair < Algebraic
  is :pair, :x, :y
end

class Option < Algebraic
  is :some, :x
  ou :none
end

class Result < Algebraic
  is :ok, :a
  ou :error, :b
end

class Nat < Algebraic
  is :z
  ou :s, Nat
end

class List < Algebraic
  is :empty
  ou :cons, :x, List
end

class Wrap < Algebraic
  is :wrap, :x

  def unwrap
    @wrap
  end
end

class Void < Algebraic
  def initialize *args
    raise "Void.new"
  end
end
```

## AST Example

```ruby
class Expr < Algebraic
  alt :var, String
  alt :number, Integer
  alt :string, String
  alt :concat, Expr, Expr
  alt :plus, Expr, Expr
  alt :times, Expr, Expr
  alt :let, String, Expr, Expr
  alt :lambda, String, Expr
  alt :apply, Expr, Expr

  def self.parse
    ...
  end
end

> Expr.parse "let f = \x -> (x+1)*x in f 9"
=> Let["f",Lambda["x",Times[Plus[Var["x"],Number[1]],Var["x"]],Apply[Var["f"],Number[9]]]]
```

## Binary Tree Example

```ruby
class TwoTree < Algebraic
  is :leaf
  au :node, TwoTree, :x, TwoTree

  def contains? y
    self.case(
      leaf: ->{ false },
      node: ->(left, x, right){
        case
          when y==x then true
          when y<x then left.contains? y
          when y>x then right.contains? y
        end
      }
    )
  end

  def insert y
    leaf = TwoTree.leaf
    self.case(
      leaf: ->{ TwoTree.node leaf, y, leaf },
      node: ->(left, x, right){
        case
          when y==x then self
          when y<x then TwoTree.node left.insert(y), x, right
          when y>x then TwoTree.node left, x, right.insert(y)
        end
      }
    )
  end
end

> TwoTree.leaf.insert(2).insert(3).insert(1)
=> Node[Node[Leaf[], 1, Leaf[]], 2, Node[Leaf[], 3, Leaf[]]] 
```

