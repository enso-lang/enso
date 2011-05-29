require 'core/system/load/load'
require 'core/diff/code/diff'
require 'core/diff/code/conflicts'
require 'core/diff/code/intersect'
require 'core/diff/code/patch'
require 'applications/EnsoSync/code/io'

def sync(s1, s2)
  #check that s1 and s2 have the same base
  raise "Unable to synchronize "+s1.name+" and "+s2.name+" due to different base" if not Equals.equals(s1.basedir, s2.basedir)
  raise "Unable to synchronize "+s1.name+" and "+s2.name+" due to different factory" if s1.factory != s2.factory

  # search the file system to fill in the nodes
  factory = s1.factory
  basedir = s1.basedir
  s1.basedir = read_from_fs(s1.path, factory)
  s2.basedir = read_from_fs(s2.path, factory)

  # perform differencing on both paths  
  d1 = diff(basedir, s1.basedir)
  d2 = diff(basedir, s2.basedir)

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
  apply_to_fs(s1.path, s2.path, d1to2)
  puts "To update s2 to s1"
  apply_to_fs(s2.path, s1.path, d2to1)

  # save new base of s1 and s2 
  Patch.patch!(s1.basedir, d1)
  Patch.patch!(s1.basedir, d1to2)
  Patch.patch!(s2.basedir, d2)
  Patch.patch!(s2.basedir, d2to1)

  return s1.basedir
end
