require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/code/layout'
require 'core/diff/code/delta'
require 'core/diff/code/diff'
require 'core/diff/code/patch'
require 'core/diff/code/conflicts'
require 'core/diff/code/intersect'
require 'core/system/library/schema'
require 'applications/EnsoSync/code/io'
require 'applications/EnsoSync/code/sync'

#sync("/home/alexloh/temp/t1/f", "/home/alexloh/temp/t2/f", "/home/alexloh/temp/t0/f")


schema = Loader.load('esync.schema')
grammar = Loader.load('esync.grammar')




# search the tree to fill in the nodes
f = Factory.new(schema)


def recurse(path, factory)
  delim = "/"
  #strip ending "/"
  path = path[0..path.length-2] if path.end_with?(delim)
  fname = path[path.rindex(delim)+1..path.length-1]
  if File::directory?(path)
    d = factory["Dir"]
    d.name = fname
    Dir.foreach(path) do |entry|
      next if entry == "." || entry == ".."
      d.nodes << recurse(path+delim+entry, factory)
    end
    return d
  else
    f = factory["File"]
    f.name = fname
    return f
  end
end

factory = Factory.new(schema)
d = factory.Domain
s0 = factory.Source("s0")
s0.path = "/home/alexloh/temp/t0/f"
s0.basedir = recurse("/home/alexloh/temp/t0/f", factory)
d.sources << s0
DisplayFormat.print(grammar, d)


blahblah
# takes a set of pairs and output a map from every element 
#found in either side of the pair to a resolved version
def resolve(confs)
  return resolve_by_ordering(confs)
end

# conflict resolution: always take left
# does not handle multi-insert
def resolve_by_ordering(confs)
  return confs.map{|p| p[0]}
end

# conflict resolution: ask the user
def resolve_by_user(confs)
end

# conflict resolution: check date
def resolve_by_user(confs)
end

# takes an original delta and a new delta at the same place
#and decide how to update an object that has applied orig
# ie. find d' such that d'(orig(x))=new(x)
# The rules for doing this are:
# BASE NEW
#          - for single-valued fields:
# ins  ins  DEL(orig); new
# mod  ins  DEL(orig); new (nc)
# del  ins  new (nc)
# ins  mod  DEL(orig); new (nc) (???)
# mod  mod  ignore (handled by descendent nodes)
# del  mod  **** (no way to handle this inspecting base version)
# ins  del  new (nc)
# mod  del  new
# del  del  nil/new
#          - for many-valued fields (keyed):
# ins  ins  DEL(orig); new (note: these are marked as conflicts)
# mod  ins  new (non-conflict or nc)
# del  ins  new (non-conflict or nc)
# ins  mod  new (non-conflict or nc)
# mod  mod  ignore (handled by descendent nodes)
# del  mod  **** (no way to handle this inspecting base version)
# ins  del  new
# mod  del  new
# del  del  nil/new
# nc=not compatible, ie not possible with same base
# A more compact equivalent is implemented below
# TODO: I don't know how to handle multi-inserts to arrays 
#       will involve calculating new indices from non conflicting deltas
# TODO: No way to de-conflict a del and modify without inspecting the base version
#       as some deleted changes need to be restored
def makeUpdate(base, new)
  return nil if new[0] == base[0]
  return nil if DeltaTransform.isModifyChange?(base[0]) and DeltaTransform.isModifyChange?(new[0])
  #TODO: currently we finesse this problem in EnsoSync by cheating apply()
  #      apply knows how to handle illegal operations like modifying an object that does
  #      not exist or inserting to an object that already exists
  return new[0]
end

d = factory.Domain
s0 = factory.Source("s0")
s0.rootpath = "/home/alexloh/temp/t0/f"
s0.rootdir = recurse(s0.rootpath, factory)
d.sources << s0
s1 = factory.Source("s1")
s1.rootpath = "/home/alexloh/temp/t1/f"
s1.rootdir = recurse(s1.rootpath, factory)
d.sources << s1
s2 = factory.Source("s2")
s2.rootpath = "/home/alexloh/temp/t2/f"
s2.rootdir = recurse(s2.rootpath, factory)
d.sources << s2

puts "asdf1"
d1 = diff(s0.rootdir, s1.rootdir)
d2 = diff(s0.rootdir, s2.rootdir)

puts "asdf2"

#puts "ASDF"
puts "d1 = "
Print.print(d1)
puts "d2 = "
Print.print(d2)
puts "#####"

intersect = Intersect.intersect(d1, d2)
# get all repeated edits in d1 and d2
nonconfs = Conflicts.nonconflicts(d1, d2)
# get all conflicts find resolutions for them 
conflicts = Conflicts.conflicts(d1, d2)
resolution = resolve(conflicts)
resolvemap = {}
for i in 0..resolution.length-1
  if resolution[i] == conflicts[i][0]
    conflicts[i][1].each {|d| resolvemap[d] = nil}
  elsif resolution[i] == conflicts[i][1]
    conflicts[i][0].each {|d| resolvemap[d] = nil}
  else
  end 
end
#resolvemap = Hash[.map {|p| [p[0][0], p[1][0]]}]

  puts resolvemap.to_s
# to get from d2'(d1(x))=d1d2(x), where 
#d2' = d2 - nonconfs(d1,d2) + 
#        forall x1=>r in conf, DEL(x1) + r where x1!=r
#return confs.inject({}) {|res, p| res.merge!({p[0]=>p[0], p[1]=>p[0]}) }
#puts resolvemap.map {|p| [p[0], makeUpdate(p[0], p[1])]}.to_s
#resolvemap.map {|p| p[0]

#puts Intersect.getFrom(nonconfs, 0).to_s
#puts nonconfs.flat_map{|i|i}.to_s

# update source 1
Print.print Intersect.remove_deltas(d2,Intersect.getFrom(nonconfs, 1))
d1to2 = Intersect.replace_deltas(Intersect.remove_deltas(d2,Intersect.getFrom(nonconfs, 1)), resolvemap)
#Print.print d1to2 
puts "To update s1 to s2"
apply(s1.rootpath, s2.rootpath, d1to2)
# update source 2
d2to1 = Intersect.replace_deltas(Intersect.remove_deltas(d1,Intersect.getFrom(nonconfs, 0)), resolvemap)
#Print.print d2to1 
puts "To update s2 to s1"
apply(s2.rootpath, s1.rootpath, d2to1)


#confs = Conflicts.conflicts(d1, d2)
#Print.print(confs[0][0][0])
#Print.print(confs[0][1][0])

#Print.print(Intersect.subtract(d2,d1))


#apply(s0.rootpath, s1.rootpath, d1)

