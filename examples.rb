require 'algebraic'

class Pair < Algebraic

  is :pair, :x, :y

  def l
    @pair[0]
  end

  def r
    @pair[1]
  end

end

class Unit < Algebraic

  is :unit

end

class Bool < Algebraic

  is :t
  au :f

  def to_b
    !@false
  end

  def not
    self.case({
      :f => lambda{ Boolean.t },
      :t => lambda{ Boolean.f }
    })
  end

end

class Wrap < Algebraic

  is :wrap, :x

  def unwrap
    @wrap
  end

end

class Option < Algebraic

  is :some, :x
  au :none

  def default d
    self.case({
      :some => lambda{|x| x},
      :none => lambda{ d }
    })
  end

  def map &block
    self.case({
      :some => lambda{|x| Option.some(block.call(x)) },
      :none => lambda{ Option.none }
    })
  end

  def and_then &block
    self.case({
      :some => lambda{|x| block.call(x)},
      :none => lambda{ Option.none }
    })
  end

  def to_a
    self.case({
      :some => lambda{|x| [x]},
      :none => lambda{ [] }
    })
  end

  def compare opt
    self.case({
      :some => lambda{|x|
        opt.case({
          :some => lambda{|y| x <=> y},
          :none => lambda{ 1 }
        })
      },
      :none => lambda{
        opt.case({
          :some => lambda{|y| -1 },
          :none => lambda{ 0 }
        })
      }
    })
  end

  def == opt
    compare(opt) == 0
  end

  def none?
    !@some
  end

  def to_json
    self.case({
      :some => lambda{|x| JSON.generate({:some => x}) },
      :none => lambda{ JSON.generate({:none => true}) }
    })
  end

  def get_some
    (@some || raise("#{to_s}.get_some")).unwrap
  end

  class ::Array
    def first_option
      found = false
      self.each do |opt|
        opt.case({
          :some => lambda{|x| found = true},
          :none => lambda{}
        })
        return opt if found
      end
      return Option.none
    end

    def cat_options
      result = []
      self.each do |opt|
        opt.case({
          :some => lambda{|x| result.push x},
          :none => lambda{}
        })
      end
      result
    end
  end

end

class Result < Algebraic

  is :ok, :x
  au :error, :y

  def error?
    !@ok
  end

  def get_ok
    (@ok || raise("#{to_s}.get_ok")).unwrap
  end

  def get_error
    (@error || raise("#{to_s}.get_error")).unwrap
  end

end

class Nat < Algebraic

  is :z
  au :s, :n

  def times &block
    y = self
    while true
      next_n = y.case({
        :s => lambda{|n| n},
        :z => lambda{ nil }
      })
      break if next_n.nil?
      block.call
      y = next_n
    end
  end

  def to_i
    i = 0
    self.times { i = i + 1 }
    i
  end

  def zero?
    !@s
  end

  def s
    Nat.s self
  end

  def pred
    (@s || raise("#{to_s}.pred")).unwrap
  end

  class ::Fixnum
    def to_nat
      n = Nat.z
      self.times { n = Nat.s n }
      n
    end
  end

end

class List < Algebraic

  is :empty
  au :cons, :x, :list

  def empty?
    !@cons
  end

  def each &block
    node = self
    while !node.empty?
      x, rest = node.uncons
      block.call x
      node = rest
    end
    nil
  end

  def map &block
    result = List.empty
    self.to_a.reverse.each do |x|
      result = List.cons block.call(x), result
    end
    result
  end

  def to_a
    a = []
    self.each do |x|
      a.push x
    end
    a
  end

  def uncons
    @cons || raise("#{to_s}.uncons")
  end

  class ::Array
    def to_list
      result = List.empty
      self.reverse.each do |x|
        result = List.cons x, result
      end
      result
    end
  end

end
