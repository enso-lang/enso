require 'core/diff/code/match'
require 'core/system/utils/paths'

module Diff

  include Paths

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

  def self.map_paths(root, currpath = Path.new)
    res = {root => currpath}
    root.schema_class.fields.each do |f|
      next unless !f.Primitive? and f.traversal
      if !f.many
        res.update map_paths(root[f.name], currpath.field(f.name))
      else
        i = 0
        root[f.name].each do |v|
          res.update map_paths(v, IsKeyed?(f.type) ? currpath.field(f.name).key(ObjectKey(v)) : currpath.field(f.name).index(i))
          i+=1
        end
      end
    end
    res
  end

  #given two objects, return a list of operations that
  def self.diff(o1, o2)
    @path_map = map_paths(o2)
    matches = Match.new.match(o1, o2)
    diff_all(o1, o2, Path.new, matches)
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
    if type.is_a? ManagedData::MObject
      if !ref
        diff_obj(o1, o2, path, matches, ref)
      else
        diff_ref(o1, o2, path, matches, ref)
      end
    elsif type.is_a? ManagedData::List
      diff_array(o1, o2, path, matches, ref)
    elsif type.is_a? ManagedData::Set
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
      difflist = [Op.new(add, path, o2.schema_class)]
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
    [Op.new(mod, path, o2.nil? ? nil : get_path(o2))]
  end

  def self.diff_hash(o1, o2, path, matches, ref)
    difflist = []
    found = []
    o1.each do |i1|
      fpath = path.key(ObjectKey(i1))
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
      fpath = path.key(ObjectKey(i2))
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

    difflist = []
    i=j=0
    while i<o1.length and j<o2.length
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
    for n in j..o2.length-1
      difflist.unshift *diff_all(nil, o2[n], path.index(i), matches, ref)
    end
    difflist
  end

  def self.get_path(obj)
    @path_map[obj]
  end
end
