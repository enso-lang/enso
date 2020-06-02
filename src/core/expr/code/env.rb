#=begin
#This file stores various types of environments

#@parent is the parent env used when the local lookup fails
#@parent is never written to, even when a variable is already defined there
#=end

require 'enso'

module Env
  module BaseEnv
    def set!(key, &block)
      self[key] = block.call(self[key])
    end
    
    def set(key, &block)
      res = self.clone
      res.set!(key, block)
      res
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
    
    def to_s
      r = []
      each {|k,v| r << "#{k}=>#{v}"}
      "{ #{r.join(", ")} }"
    end
  end

  class HashEnv
    include BaseEnv
    def initialize(hash={}, parent=nil)
      super()
      @hash=hash
      @parent=parent
    end
    
    def [](key)
      key = key.to_s
      if @hash.has_key?(key)
        @hash[key]
      else
        @parent && @parent[key]
      end
    end

    def []=(key, value)
      key = key.to_s
      if @hash.has_key?(key) #if defined in current env
        @hash[key] = value
      elsif @parent && @parent.has_key?(key) #if defined in parent env
        @parent[key] = value
      else #new variable goes into current env
        @hash[key] = value
      end
    end
    
    def has_key?(key)
      key = key.to_s
      @hash.has_key?(key) || (@parent && @parent.has_key?(key))
    end
    
    def keys
      (@hash.keys + (@parent.nil? ? [] : @parent.keys)).uniq
    end
      
    def to_s
      "#{@hash.to_s}-#{@parent}"
    end
  end

  #Env that simulates an MObject
  class ObjEnv
    include BaseEnv
  
    attr_reader :obj

    def initialize(obj, parent = nil)
      super()
      @obj = obj
      @parent = parent
    end
    
    def [](key)
      if key == "self"
        #puts "SELF = #{obj}"
        @obj
      elsif @obj.schema_class.all_fields.any?{|f|f.name == key}
        @obj[key]
      else
        @parent && @parent[key]
      end
    end
    
    def []=(key, value)
      begin
        @obj[key] = value
      rescue
        @parent && @parent[key] = value
      end
    end
    
    def has_key?(key)
      key == "self" || @obj.schema_class.all_fields[key] || (@parent && @parent.has_key?(key))
    end
        
    def keys
      (@obj.schema_class.all_fields.keys + (@parent.nil? ? [] : @parent.keys)).uniq
    end
      
    def to_s
      "#{@obj.to_s}-#{@parent}"
    end
    
    def type(fname)
      x = @obj.schema_class.all_fields[fname]
      if x == nil then
        raise "Unkown field #{fname} @{@obj.schema_class}"
      else
        x.type
      end
    end
  end
  
  #Env that simulates the result of a lambda
  # can be used to store pointers
  class LambdaEnv
    include BaseEnv
    
    def initialize(label, parent = nil, &block)
      super()
      @label = label
      @block = block
      @parent = parent
    end
    
    def [](key)
      if @label == key
        @block.call
      else
        @parent && @parent[key]
      end
    end
    
    def []=(key, value)
      if @label == key
        raise "Trying to modify read-only variable #{key}"
      else
        @parent[key] = value
      end
    end
    
    def has_key?(key)
      @label == key || (@parent && @parent.has_key?(key))
    end

    def keys
      ([@label] + (@parent.nil? ? [] : @parent.keys)).uniq
    end
     
    def to_s
      "#{@block.to_s}-#{@parent}"
    end
  end
end
