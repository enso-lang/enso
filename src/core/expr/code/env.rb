=begin
This file stores various types of environments

@parent is the parent env used when the local lookup fails
@parent is never written to, even when a variable is already defined there
=end

module Env
  def set!(key)
    self[key] = yield self[key]
  end
  def set(key, &block)
    res = self.clone
    res.set!(key, block)
    res
  end
  def has_key?(key)
    self.each do |k,v|
      return true if k==key
    end
    false
  end
  def set_parent(env)
    @parent = env
    self
  end
  def set_grandparent(env)
    if @parent.nil? || @parent=={}
      set_parent(env)
    else
      @parent.set_grandparent(env)
    end
  end
  def +(env)
    set_parent(env)
    self
  end
  def to_s
    r = []
    each {|k,v| r << "#{k}=>#{v}"}
    "{ #{r.join(", ")} }"
  end
  def clone
    self
  end
end

class HashEnv
  include Env
  def initialize(hash={})
    @hash=hash
  end
  def [](key)
    if @hash.has_key? key
      @hash[key]
    else
      @parent.nil? ? nil : @parent[key]
    end
  end
  def []=(key, value)
    @hash[key] = value
  end
  def each(&block)
    @hash.each &block
    @parent.each &block unless @parent.nil?
  end
  def to_s
    @hash.to_s
  end
  def clone
    r = HashEnv.new(@hash.clone)
    r.set_parent(@parent)
    r
  end
end

#Env that simulates an MObject
class ObjEnv
  include Env
  def initialize(obj)
    @obj = obj
  end
  def [](key)
    if @obj.schema_class.all_fields.map{|f|f.name}.include? key
      @obj[key]
    else
      @parent.nil? ? nil : @parent[key]
    end
  end
  def []=(key, value)
    @obj[key] = value
  end
  def each(&block)
    @obj.schema_class.all_fields.each do |f|
      yield f.name, @obj[f.name]
    end
    @parent.each &block unless @parent.nil?
  end
  def to_s
    @obj.to_s
  end
  def type(fname)
    @obj.schema_class.all_fields[fname].type
  end
  def clone
    self #there can only be one env for the object
  end
end

#Env that simulates the result of a lambda
# can be used to store pointers
class LambdaEnv
  include Env
  def initialize(label, &block)
    @label = label
    @block = block
  end
  def [](key)
    if @label==key
      res = @block.call
      res
    else
      @parent.nil? ? nil : @parent[key]
    end
  end
  def []=(key, value)
    if @label==key
      raise "Trying to modify read-only variable #{key}"
    else
      @parent[key]=value
    end
  end
  def each(&block)
    yield @label, @block.call
    @parent.each &block unless @parent.nil?
  end
  def to_s
    @block.to_s
  end
  def clone
    self #there can only be one env for the object
  end
end
