
module ManagedData
  module SetUtils
    def to_ary; @values.values end

    def +(other)
      # left-biased: field is from self
      r = self.inject(Set.new(nil, @field, __key || other.__key), &:<<)
      other.inject(r, &:<<)
    end

    def select(&block)
      result = Set.new(nil, @field, __key)
      each do |elt|
        result << elt if block.call(elt)
      end
      result
    end

    def flat_map(&block)
      new = nil
      each do |x|
        set = block.call(x)
        if new.nil? then
          key = set.__key
          new = Set.new(nil, @field, key)
        else
         # if set.__key != key then
         #   raise "Incompatible key fields: #{set.__key} vs #{key}"   
         # end
        end
        set.each do |y|
          new << y
        end
      end
      new || Set.new(nil, @field, __key)
    end
      
    def each_with_match(other, &block)
      empty = Set.new(nil, @field, __key)
      __outer_join(other || empty) do |sa, sb|
        if sa && sb && sa[__key.name] == sb[__key.name] 
          block.call(sa, sb)
        elsif sa
          block.call(sa, nil)
        elsif sb
          block.call(nil, sb)
        end
      end
    end

    def __key; @key end

    def __keys; @value.keys end

    def __outer_join(other, &block)
      keys = __keys | other.__keys
      keys.each do |key|
        block.call( self[key], other[key], key )
        # block.call( self.get_maybe(key), other.get_maybe(key), key )   # allow non-defined fields to merge
      end
    end
  end

  module ListUtils
    def each_with_match(other, &block)
      if !empty? then
        each do |item|
          block.call( item, nil )
        end
      end
    end
  end
end
