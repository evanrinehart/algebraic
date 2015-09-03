class Algebraic

  class << self
    attr_accessor :_ctors, :_arities
    def is ctor, *args
      @_ctors = [ctor]
      @_arities = {}
      @_arities[ctor] = args.length

      self.class.send(:define_method, ctor, proc{|*args| self.new ctor, *args})
    end

    def or ctor, *args
      @_ctors.push ctor
      @_arities[ctor] = args.length

      self.class.send(:define_method, ctor, proc{|*args| self.new ctor, *args})
    end

    alias_method :est, :is
    alias_method :ou, :or
    alias_method :ist, :is
    alias_method :oder, :or
    alias_method :es, :is
    alias_method :o, :or
    alias_method :как, :is
    alias_method :или, :or
  end

  class Wrap
    attr_reader :unwrap
    def initialize x
      @unwrap = x
    end
  end

  def initialize ctor, *values
    arity = _arity_of ctor
    if arity == 0
      self.instance_variable_set("@#{ctor}", true)
    elsif arity == 1
      self.instance_variable_set("@#{ctor}", Wrap.new(values.first))
    else
      self.instance_variable_set("@#{ctor}", values)
    end
  end

  def _ctors
    self.class._ctors
  end

  def _arity_of ctor
    self.class._arities[ctor]
  end

  def case cases
    self.class._ctors.each do |ctor|
      v = self.instance_variable_get "@#{ctor}"
      if v
        arity = _arity_of ctor
        if arity == 0
          return cases[ctor].call
        elsif arity == 1
          return cases[ctor].call v.unwrap
        else
          return cases[ctor].call *v
        end
      end
    end
    raise "missing a case"
  end

  def to_s
    _ctors.each do |ctor|
      v = self.instance_variable_get "@#{ctor}"
      if v
        arity = _arity_of ctor
        if arity == 0
          return "#{ctor.capitalize}[]"
        elsif arity == 1
          return "#{ctor.capitalize}[#{v.unwrap.inspect}]"
        else
          return "#{ctor.capitalize}#{v.inspect}"
        end
      end
    end
    raise "bug"
  end

  alias_method :inspect, :to_s

end

class Pair < Algebraic

  is :pair, :x, :y

  def initialize x, y
    super :pair, x, y
  end

  def l
    @pair[0]
  end

  def r
    @pair[1]
  end

end

class Unit < Algebraic

  is :unit

  def initialize
    super :unit
  end

end

class Boolean < Algebraic

  est :t
  ou :f

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
    @wrap.unwrap
  end

end

class Option < Algebraic

  est :some, :x
  ou :none

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

  est :ok, :x
  ou :error, :y

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

  est :z
  ou :s, :n

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

  est :empty
  ou :cons, :x, :list

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
