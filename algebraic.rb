class Unit
  def inspect
    'Unit[]'
  end

  def to_s
    inspect
  end
end

class Wrap
  attr_reader :unwrap
  def initialize x
    @unwrap = x
  end

  def inspect
    "Wrap[#{@unwrap.inspect}]"
  end

  def to_s
    inspect
  end
end

class Option

  def initialize a, b
    @some = a
    @none = b
  end

  def self.some a
    Option.new Wrap.new(a), nil
  end

  def self.none
    Option.new nil, Unit.new
  end

  def case cases
    case
      when @some then cases[:some].call(@some.unwrap)
      when @none then cases[:none].call 
    end
  end

  def to_s
    case
      when @some then "Some[#{@some.unwrap.inspect}]"
      when @none then "None[]"
      else raise "bug"
    end
  end

  alias_method :inspect, :to_s

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

class Result

  def initialize a, b
    @ok = a
    @error = b
  end

  def self.ok a
    Result.new Wrap.new(a), nil
  end

  def self.error b
    Result.new nil, Wrap.new(b)
  end

  def case cases
    case
      when @ok then cases[:ok].call @ok.unwrap
      when @error then cases[:error].call @error.unwrap
    end
  end

  def to_s
    case
      when @ok then "Ok[#{@ok.unwrap.inspect}]"
      when @error then "Error[#{@error.unwrap.inspect}]"
      else raise "bug"
    end
  end

  alias_method :inspect, :to_s

  def get_ok
    (@ok || raise("#{to_s}.get_ok")).unwrap
  end

  def get_error
    (@error || raise("#{to_s}.get_error")).unwrap
  end

end

class Nat
  attr_reader :z, :s

  def initialize z, s
    @z = z
    @s = s
  end

  def self.z
    Nat.new Unit.new, nil
  end

  def self.s n
    Nat.new nil, Wrap.new(n)
  end

  def case cases
    case
      when @s then cases[:s].call(@s.unwrap)
      when @z then cases[:z].call 
    end
  end

  def to_s
    case
      when @z then "Z[]"
      when @s then "S[#{@s.unwrap.inspect}]"
      else raise 'bug'
    end
  end

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
    !@succ
  end

  def s
    Nat.s self
  end

  alias_method :inspect, :to_s

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

class List

  def initialize empty, cons
    @empty = empty
    @cons = cons
  end

  def self.cons x, xs
    List.new nil, [x, xs]
  end

  def self.empty
    List.new [], nil
  end

  def case cases
    case
      when @cons then cases[:cons].call(@cons)
      when @empty then cases[:empty].call
    end
  end

  def to_s
    case
      when @cons then "Cons#{@cons.inspect}"
      when @empty then "Empty[]"
      else raise "bug"
    end
  end

  alias_method :inspect, :to_s

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
