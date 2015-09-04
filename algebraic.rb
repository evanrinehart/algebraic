class Algebraic

  class << self
    attr_accessor :_ctors, :_arities, :_schemas
    def alt ctor, *args
      @_ctors ||= []
      @_arities ||= {}
      @_schemas ||= {}
      if @_ctors.include? ctor
        raise "ctor #{ctor} aleady defined"
      end
      @_ctors.push ctor
      @_arities[ctor] = args.length
      @_schemas[ctor] = args
      self.class.send(:define_method, ctor, proc{|*args| self.new(:_shibboleth, ctor, *args)})
      self
    end

    alias_method :is, :alt
    alias_method :or, :alt
    alias_method :orr, :alt
    alias_method :est, :alt
    alias_method :ou, :alt
    alias_method :ist, :alt
    alias_method :oder, :alt
    alias_method :es, :alt
    alias_method :o, :alt
    alias_method :как, :alt
    alias_method :или, :alt
    alias_method :orr, :alt
    alias_method :|, :alt
    alias_method :estas, :alt
    alias_method :au, :alt
    alias_method :aux, :alt
    alias_method :aŭ, :alt
  end

  class Wrap
    attr_reader :unwrap
    def initialize x
      @unwrap = x
    end
  end

  def initialize *args
    if args.first == :_shibboleth
      _init args[1], *args[2..-1]
    elsif _ctors.length == 1
      _init _ctors.first, *args
    else
      raise "Constructor ambiguous. Use one of #{_ctors.map{|x| "#{self.class}.#{x}"}.join(', ')}"
    end
  end

  def _init ctor, *values
    arity = _arity_of ctor
    if values.length != arity
      raise "#{arity} arguments required, was provided #{values.length}"
    end
    schema = _schema_of ctor
    values.each_with_index do |v, i|
      c = schema[i]
      if c.is_a?(Class) && !v.is_a?(c)
        next if c == Boolean && (v.is_a?(TrueClass) || v.is_a?(FalseClass))
        raise ArgumentError, "argument #{i+1} must be a #{c}, was provided a #{v.class}"
      end
    end
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

  def _schema_of ctor
    self.class._schemas[ctor]
  end

  def case cases
    self.class._ctors.each do |ctor|
      v = self.instance_variable_get "@#{ctor}"
      if v
        arity = _arity_of ctor
        if !cases.has_key?(ctor) && cases.has_key?(:_)
          k = :_
        elsif cases.has_key?(ctor)
          k = ctor
        else
          raise "missing case"
        end
        if arity == 0
          return cases[k].call
        elsif arity == 1
          return cases[k].call v.unwrap
        else
          return cases[k].call *v
        end
      end
    end
    raise "bug"
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

class Boolean
end

class Pair < Algebraic
  is :pair, :x, Boolean
end

class Opt < Algebraic
  is :some, :x
  au :none
end

class Tree < Algebraic
  is :leaf
  au :node, Tree, :x, Tree
end
