require 'core/system/load/load'
require 'core/diff/code/diff'
require 'core/diff/code/conflicts'
require 'core/diff/code/intersect'
require 'core/diff/code/union'
require 'core/diff/code/patch'

def sync(s1, s2, base, factory)

  # perform differencing on both paths
  d1 = diff(base, s1)
  d2 = diff(base, s2)

  # merge all deltas to form a combined delta
  d = Union.union(d1, d2, factory)

  # new base is the end state everyone should be in
  newbase = Patch.patch(base, d)

  # generate updates by differencing
  d1u = diff(s1, newbase)
  d2u = diff(s2, newbase)

  return d1u, d2u, newbase
end

def collate_diffs(d, root, path)
  return {} if d.nil?
  if DeltaTransform.isInsertChange?(d) or (!d.D_Dir? and DeltaTransform.isModifyChange?(d))
    root.empty? ? "" : contents = d.D_Dir? ? "" : File.open("#{root}/#{path}", "rb").read
    res = {path=>['+', d.D_Dir? ? 'D' : 'F', contents]}
  elsif DeltaTransform.isDeleteChange?(d)
    res = {path=>['-', d.D_Dir? ? 'D' : 'F', ""]}
  else
    res = {}
  end
  if d.D_Dir?
    d.nodes.each do |n|
      res.merge!(collate_diffs(n, root, path+'/'+n.pos))
    end
  end
  res
end
