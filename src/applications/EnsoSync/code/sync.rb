require 'core/system/load/load'
require 'core/diff/code/diff'
require 'core/diff/code/conflicts'
require 'core/diff/code/intersect'
require 'applications/EnsoSync/code/execrule'

def sync(path1, path2, basepath)
  schema = Loader.load('esync.schema')
  grammar = Loader.load('esync.grammar')

  # search the tree to fill in the nodes
  factory = Factory.new(schema)
  d = factory.Domain
  s0 = factory.Source("s0")
  s0.rootpath = basepath
  s0.rootdir = recurse(s0.rootpath, factory)
  d.sources << s0
  s1 = factory.Source("s1")
  s1.rootpath = path1
  s1.rootdir = recurse(s1.rootpath, factory)
  d.sources << s1
  s2 = factory.Source("s2")
  s2.rootpath = path2
  s2.rootdir = recurse(s2.rootpath, factory)
  d.sources << s2

  # perform differencing on both paths  
  d1 = diff(s0.rootdir, s1.rootdir)
  d2 = diff(s0.rootdir, s2.rootdir)

  # generate actions by merging differences  

  # get all repeated edits in d1 and d2
  nonconfs = Conflicts.nonconflicts(d1, d2)

  # get all conflicts find resolutions for them 
  conflicts = Conflicts.conflicts(d1, d2)
  resolution = Conflicts.resolve(conflicts)

  # d1to2 is a delta object where d1to2(d1(x)) = merged-d1d2(x)
  # To compute d1to2, remove from d2:
  #   - all non-conflicting deltas in the intersection (to avoid repetition)
  #   - all conflicting deltas from d2 that were not chosen by conflict resolution
  # ie. d1to2 = d2 - nonconfs(d1, d2) - forall (d1', d2', r) in resolution, d2' where r=d1' 
  resolvemap = {}
  for i in 0..resolution.length-1
    if resolution[i] == conflicts[i][0]
      conflicts[i][1].each {|d| resolvemap[d] = nil}
    elsif resolution[i] == conflicts[i][1]
      conflicts[i][0].each {|d| resolvemap[d] = nil}
    else
    end 
  end
  d1to2 = Intersect.replace_deltas(Intersect.remove_deltas(d2,Intersect.getFrom(nonconfs, 1)), resolvemap)
  d2to1 = Intersect.replace_deltas(Intersect.remove_deltas(d1,Intersect.getFrom(nonconfs, 0)), resolvemap)
  
  # update sources based on actions (currently pretty prints what to do)
  puts "To update s1 to s2"
  apply(s1.rootpath, s2.rootpath, d1to2)
  puts "To update s2 to s1"
  apply(s2.rootpath, s1.rootpath, d2to1)

end