require 'core/system/load/load'
require 'core/diff/code/diff'
require 'core/diff/code/conflicts'
require 'core/diff/code/intersect'
require 'core/diff/code/union'
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

  # merge all deltas to form a combined delta
  d = Union.union(d1, d2, d1.factory)
  # new base is the end state everyone should be in
  newbase = Patch.patch!(basedir, d)

  # generate updates by differencing
  d1u = diff(s1.basedir, newbase)
  d2u = diff(s2.basedir, newbase)

  # update sources based on actions (currently pretty prints what to do)
  #puts "To update s1 to s2"
  apply_to_fs(s1.path, s2.path, d1u)
  #puts "To update s2 to s1"
  apply_to_fs(s2.path, s1.path, d2u)

  # save new base of s1 and s2 
  Patch.patch!(s1.basedir, d1)
  Patch.patch!(s1.basedir, d1u)
  Patch.patch!(s2.basedir, d2)
  Patch.patch!(s2.basedir, d2u)

  return s1.basedir
end
