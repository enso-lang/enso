require 'core/system/load/load'
require 'core/schema/tools/diff'
require 'core/diff/code/conflicts'
require 'core/diff/code/intersect'
require 'core/diff/code/union'
require 'core/diff/code/patch'

def sync(s1, s2, base)

  # perform differencing on main updater
  d = Diff.diff(base, s1)

  # new base is the end state everyone should be in
  newbase = s2.factory.trusted_mode {
    Clone(s2)
  }
  newbase = Patch.patch(newbase, d)

  # generate updates by differencing
  d1u = Diff.diff(s1, newbase)
  d2u = Diff.diff(s2, newbase)

  return d1u, d2u, newbase
end

def path2path(path)
  if path =~ /\/nodes\[(\w*)\](.*)/
    "/#{$1}#{path2path($2)}"
  end
end

def collate_diffs(ds, root, thispath)
  res = {}
  for i in 0..ds.size-1
    d = ds[i]
    path = "/#{thispath}#{path2path(d.path.to_s)}"
    if d.type == Diff.add or (d.type == Diff.mod && d.path.lvalue? && d.value == "File")
      if d.value == "File"
        res[path] = ['+', 'F', root=="" ? "" : File.open(root+path, "rb").read]
      elsif d.value == "Dir"
        res[path] = ['+', 'D', ""]
      end
    elsif d.type == Diff.del
      res[path] = ['-', d.value=="Dir" ? 'D' : 'F', ""]
    end
  end
  res
end

def multi_sync(s1, s2, base, factory)

  # perform differencing on both paths
  d1 = Diff.diff(base, s1)
  d2 = Diff.diff(base, s2)

  # merge all deltas to form a combined delta
  d = Union.union(d1, d2, d1.factory)

  # new base is the end state everyone should be in
  newbase = Patch.patch(base, d)

  # generate updates by differencing
  d1u = Diff.diff(s1, newbase)
  d2u = Diff.diff(s2, newbase)

  return d1u, d2u, newbase
end
