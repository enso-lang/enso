=begin
This file stores various types of environments

@parent is the parent env used when the local lookup fails
@parent is never written to, even when a variable is already defined there
=end

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
      if hash.is_a? BaseEnv
        parent = hash; hash = {}
      end
      @hash=hash
      @parent=parent
    end
    
    def [](key)
      if @hash.has_key? key
        @hash[key]
      else
        @parent && @parent[key]
      end
    end

    def []=(key, value)
      if @parent and @parent.has_key? key
        @parent[key] = value
      else
        @hash[key] = value
      end
    end
    
    def has_key?(key)
      @hash.has_key?(key) || (@parent && @parent.has_key?(key))
    end
    
    def keys
      (@hash.keys + (@parent.nil? ? [] : @parent.keys)).uniq
    end
      
    def to_s
      @hash.to_s
    end
  end

  #Env that simulates an MObject
  class ObjEnv
    include BaseEnv
  
    attr_reader :obj
  
    def initialize(obj, parent=nil)
      @obj = obj
      @parent=parent
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
      @obj[key] = value
    end
    
    def has_key?(key)
      key == "self" ||
        @obj.schema_class.all_fields[key] ||
        (@parent && @parent.has_key?(key))
    end
        
    def keys
      (@obj.schema_class.all_fields.keys + (@parent.nil? ? [] : @parent.keys)).uniq
    end
      
    def to_s
      @obj.to_s
    end
    
    def type(fname)
      @obj.schema_class.all_fields[fname].type
    end
  end
  
  #Env that simulates the result of a lambda
  # can be used to store pointers
  class LambdaEnv
    include BaseEnv
    
    def initialize(label, parent=nil &block)
      @label = label
      @block = block
      @parent=parent
    end
    
    def [](key)
      if @label==key
        res = @block.call
        res
      else
        @parent && @parent[key]
      end
    end
    
    def []=(key, value)
      if @label==key
        raise "Trying to modify read-only variable #{key}"
      else
        @parent[key]=value
      end
    end
    
    def has_key?(key)
      @label == key || (@parent && @parent.has_key?(key))
    end

    def keys
      ([@label] + (@parent.nil? ? [] : @parent.keys)).uniq
    end
     
    def to_s
      @block.to_s
    end
  end

end
