require 'core/system/utils/paths'

module Diff

  #Values can be: classes, primitives, paths, or nil
  def self.add; :add; end #add a new object
  def self.del; :del; end #del an object
  def self.mod; :mod; end #modify a primitive or reference value
  class Op
    attr_reader :path, :value, :type
    def initialize(type, path, value)
      @type = type
      @path = path
      @value = value
    end
    def to_s
      case @type
        when :add
          "ADD #{path} : #{value}"
        when :del
          "DEL #{path}"
        when :mod
          "MOD #{path} : #{value}"
      end
    end
  end

  #given two objects, return a list of operations that
  #DO NOT use custom schema to do delta-ing
  # problem with subtyping, eg computed : Expr
  # will be compared based the schema for Expr
  # rather than the schema class the objects actually are 
  def self.diff(o1, o2)
    matches = Match.new.match(o1, o2)
    diff_all(o1, o2, Paths::Path.new, matches)
  end

=begin
Topological sort of the diff list
*Dependencies
- New must precede any op whose path contains it or its desc
- any op on a path unless broken by another op on the closer path
*Interferences
-
=end

  #return 1 or 2 depending on which is the subpath. 0 if neither
  def subpath(p1, p2)
    if p1.elts.empty? and p2.elts.empty?
      0
    elsif p1.elts.empty?
      1
    elsif p2.elts.empty?
      2
    else
      p1.elts != p2.elts ? false : subpath(Path.new(p1.elts[1..-1]), Path.new(p2.elts[1..-1]))
    end
  end

  def calc_dep_map(deltas)
    heads = []
    tails = []
    deltas.each do |d|

    end
  end

  #############################################################################
  #start of private section
  private
  #############################################################################

  def self.diff_all(o1, o2, path, matches, ref=false)
    return [] if o1==o2
    type = o1 || o2
    if type.is_a? Factory::MObject
      if !ref
        diff_obj(o1, o2, path, matches, ref)
      else
        puts "diffing ref: o1=#{o1} o2=#{o2}"
        diff_ref(o1, o2, path, matches, ref)
      end
    elsif type.is_a? Factory::List
      diff_array(o1, o2, path, matches, ref)
    elsif type.is_a? Factory::Set
      diff_hash(o1, o2, path, matches, ref)
    else #primitive value
      diff_primitive(o1, o2, path, matches, ref)
    end
  end

  def self.diff_primitive(o1, o2, path, matches, ref)
    o2.nil? ? [] : [Op.new(mod, path, o2)]
  end

  def self.diff_obj(o1, o2, path, matches, ref)
    if o1.nil?
      difflist = [Op.new(add, path, o2.schema_class.name)]
      o2.schema_class.fields.each do |f|
        fn = f.name
        fpath = path.field(fn)
        val2 = o2[fn]
        difflist.concat diff_all(nil, val2, fpath, matches, !f.traversal)
      end
      difflist
    elsif o2.nil?
      difflist = [Op.new(del, path, nil)]
      o1.schema_class.fields.each do |f|
        fn = f.name
        fpath = path.field(fn)
        val1 = o1[fn]
        difflist.concat diff_all(val1, nil, fpath, matches, !f.traversal)
      end
      difflist
    else # assume matches[o1]==o2 and neither o1 nor o2 is nil
      difflist = []
      o1.schema_class.fields.each do |f|
        fn = f.name
        fpath = path.field(fn)
        val1 = o1[fn]; val2 = o2[fn]
        difflist.concat diff_all(val1, val2, fpath, matches, !f.traversal)
      end
      difflist
    end
  end

  def self.diff_ref(o1, o2, path, matches, ref)
    if o1==o2
      []
    elsif !o1.nil? and !o2.nil? and o1._path==o2._path
      []
    else
      [Op.new(mod, path, o2.nil? ? nil : o2._path)]
    end
  end

  def self.diff_hash(o1, o2, path, matches, ref)
    o1 = {} if o1.nil?
    o2 = {} if o2.nil?
    difflist = []
    found = []
    o1.each do |i1|
      fpath = path.key(Schema::object_key(i1))
      i2 = matches[i1]
      if i2.nil? #match not found, i1 was deleted
        difflist.concat diff_all(i1, nil, fpath, matches, ref)
      else #match not found, i1 was deleted
        found << i2
        difflist.concat diff_all(i1, i2, fpath, matches, ref)
      end
    end
    o2.each do |i2|
      next if found.include? i2
      fpath = path.key(Schema::object_key(i2))
      difflist.concat diff_all(nil, i2, fpath, matches, ref)
    end
    difflist
  end

  def self.diff_array(o1, o2, path, matches, ref)
    #The ordering is critical to ensure the indices are not messed up when patching.
    #Patch should be able to apply all operations in one pass 
    #Rules as follows:
    # - Indices are always backwards. Larger indices occur before smaller ones
    # - Except when appending to the end -- all indices past the end of array are forward
    # - Operations to the same index, eg ADD[1], ADD[1], should maintain original order

    o1 = [] if o1.nil?
    o2 = [] if o2.nil?
    difflist = []
    i=j=0
    while i<o1.size and j<o2.size
      if matches[o1[i]]==nil
        difflist.unshift *diff_all(o1[i], nil, path.index(i), matches, ref)
        i+=1
      elsif matches[o1[i]]==o2[j]
        difflist.unshift *diff_all(o1[i], o2[j], path.index(i), matches, ref)
        i+=1; j+=1
    elsif matches[o1[i]]!=o2[j]
        difflist.unshift *diff_all(nil, o2[j], path.index(i), matches, ref)
        j+=1
      end
    end
    for n in j..o2.size-1
      difflist.unshift *diff_all(nil, o2[n], path.index(i), matches, ref)
    end
    difflist
  end


class Match
  
  def match(o1, o2)
    return {} if o1==o2

    if eq(o1, o2)
      # add current match to results
      res = { o1 => o2 }
      # add results of matching non-primitive fields
        
      o1.schema_class.fields.each do |f|
        next unless f.traversal
        if not f.type.Primitive?  #FIXME: list of primitives require matching of some kind as well
          if f.many
            if Schema::is_keyed?(f.type)
              list_matches = match_keyed_list(o1[f.name], o2[f.name])
            elsif o1[f.name].is_a? Factory::List
              list_matches = match_ordered_list(o1[f.name], o2[f.name])
            else
              raise "Trying to match a field that is neither keyed nor ordered"
            end
            res.merge!(list_matches)
            list_matches.keys.each do |i1|
              res.merge!(match(i1, list_matches[i1]))
            end
          else
            res.merge!(match(o1[f.name], o2[f.name]))
          end
        end
      end
    else
      #o1 and o2 are not matched, so by this tree algo no further matching is possible
      res = {}
    end

    return res
  end

  def match_keyed_list (l1, l2)
    # match purely based on keys
    res = {}
    l1.keys.each do |k|
      res[l1[k]] = l2[k] unless l2[k].nil?  
    end
    return res
  end

  def match_unordered_list (l1, l2)
    res = {}
    l1.each do |i1|
      i2s = l2.collect {|i2| eq(i1,i2)}
      res[i1] = i2s[0] unless i2s.empty?
    end
    return res
  end
  
  def match_ordered_list (l1, l2)
    # simple lcm on l1 and l2
    # only match two points if they are shallow-equivalent
    
    #    if o1 and o2 are not both lists of the same type
    #       return {}
    #    end

    #figure out lcm matches by index
    lcm_matches = lcm(l1, l2, 0, 0, {}, lambda{|x,y| eq(x, y)})

    #assign object matches based on index matches
    res = {}
    lcm_matches.keys.each do |i1|
      i2 = lcm_matches[i1]
      res[l1[i1]] = l2[i2]
    end

    return res
  end

  def lcm (l1, l2, i1, i2, memo, eq)
    key = i1*l2.size()+i2
    if not memo[key].nil?
      return memo[key]
    end
    if i1<l1.size and i2<l2.size
      if eq.call(l1[i1], l2[i2])
        res = lcm(l1, l2, i1+1, i2+1, memo, eq)
        res[i1] = i2
      else
        r1 = lcm(l1, l2, i1+1, i2, memo, eq) 
        r2 = lcm(l1, l2, i1, i2+1, memo, eq)
        if (r2.size > r1.size)  
          return r2
        else 
          return r1 
        end
      end
    else 
      res = {}  # one side is already empty
    end
    memo[key] = res
    return res
  end

  def eq (o1, o2)
    return true if o1==o2
    return false if o1.nil? or o2.nil?
    #select appropriate schema based on schema_class of o1
    #assumption is that o1 and o2 are the same
    meta_schema_class = o1.schema_class.schema_class
    send("eq_"+meta_schema_class.name, o1, o2)
  end
  
  def eq_deep (o1, o2, matches)
    # "deep" equality by checking that all non primitive fields 
    #point to matching objects
  
    schema_class = o1.schema_class
  
    # check if these two are of the same type
    #in most places this check would have taken place before this call is made
    if o2.schema_class != schema_class
      return false
    end
  
    # iterate over all fields to verify equivalence
    schema_class.fields.each do |f|
      if f.type.Primitive?
        if o1.method(f.name).call != o2.method(f.name).call 
          return false
        end
      else
        if f.type.many?
          l1 = o1.method_added(f.name).call
          l2 = o2.method_added(f.name).call
          if l1.map{|x| matches[x]} != l2
            return false
          end
        else
          if matches[o1.method_added(f.name).call] != o2.method_added(f.name).call
            return false
          end 
        end
      end
    end
  
    # passed every test
    return true
  end
  
  def eq_Class (o1, o2)
    return true if o1==o2
    return false if o1.nil? || o2.nil?

    # define class equality as all their keys being equal
    # if this class has no keys then check that all their primitive fields are equal

    schema_class = o1.schema_class

    # check if these two are of the same type
    #in most places this check would have taken place before this call is made
    if o2.schema_class.name != schema_class.name
      return false
    end
    
    # iterate over key fields of the type to verify equivalence
    num_keys = 0
    schema_class.defined_fields.each do |f|
      if f.key and f.type.Primitive?
        if o1[f.name] != o2[f.name]
          return false
        end
        num_keys = num_keys+1
      end
    end
    
    # if no key fields found then check all primitive types
    if num_keys == 0
      schema_class.fields.each do |f|
        next if f.computed
        if f.type.Primitive?
          if o1[f.name] != o2[f.name] 
            return false
          end
        end
      end
    end 

    # passed every test
    return true
  end

  def eq_Class_allfields (o1, o2)
    # check if two objects that are klasses are shallow-equivalent
    #ie. all fields of primitive types must contain the same result
    #and of course the primitive types match
  
    schema_class = o1.schema_class
  
    # check if these two are of the same type
    #in most places this check would have taken place before this call is made
    if o2.schema_class.name != schema_class.name
      return false
    end
  
    # iterate over primitive fields of the type to verify equivalence
    schema_class.fields.each do |f|
      if f.type.Primitive?
        if o1[f.name] != o2[f.name]
          return false
        end
      end
    end
  
    # passed every test
    return true
  end
  
  def eq_Primitive (o1, o2)
    o1 == o2
  end

end

end
