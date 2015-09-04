class Algebraic

  class << self
    attr_accessor :_ctors, :_arities
    def alt ctor, *args
      @_ctors ||= []
      @_arities ||= {}
      if @_ctors.include? ctor
        raise "ctor #{ctor} aleady defined"
      end
      @_ctors.push ctor
      @_arities[ctor] = args.length
      self.class.send(:define_method, ctor, proc{|*args| self.new ctor, *args})
      self
    end

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
