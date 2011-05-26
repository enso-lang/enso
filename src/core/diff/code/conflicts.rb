=begin

Check if two delta objects conflict. 
Conflict is defined operationally as "for some x, d1(d2(x)) != d2(d1(x))" (commutativity)

This definition does not guarantee or require that the result of one or both 
transformations are logically correct
This also does not protect against 'semantic interference', eg adding the same 
item to a list twice (and hence causing a bug)

Conflicts occur if:
- Same single field in an object is assigned two changes d1, d2 where
  - d1.changetype != d2.changetype
  - (changetype = ins) and (not eq(d1, d2))
  - (changetype = mod) and field is primitive and d1 != d2
  - (changetype = mod) and field is non-primitive, and conflict(f) for some f in d.field
- Same list field in an object with the same pos 
  - d1=del and d2=mod, and vice versa
  - changetype = mod and conflict(f) for some f in d.field
  - (all d1=ins) != (all d2=ins)
    - in this case the conflict returned will be the two whole lists conflict

Assumptions:
- Deltas are on the same base
- Objects must conform to the same delta schema

=end

require 'core/diff/code/intersect'
require 'core/diff/code/equals'

class Conflicts

  # identify conflicts between two delta objects
  # return [] if no conflicts found
  def self.conflicts(d1, d2)
    return Intersect.intersect(d1, d2).select {|p| check_conflict?(p[0], p[1])}
  end
  
  # identify non-conflicts (ie repetitions) between two delta objects
  def self.nonconflicts(d1, d2)
    return Intersect.intersect(d1, d2).select {|p| not check_conflict?(p[0], p[1])}
  end

  # given two lists of matching deltas (usually from intersect), 
  #determine if they conflict with each other
  #must either be a single element or a list of inserts all to the same pos in a many-valued field
  def self.check_conflict?(l1, l2)
    return ! Equals.equals_list(l1, l2)
  end

  # takes a list of pairs and output a list of resolutions
  # resolutions are delta objects and are usually one of the input pairs or 
  #constructed based on them
  def self.resolve(confs)
    return resolve_by_ordering(confs)
  end
  
  # conflict resolution: always take left
  # does not handle multi-insert
  def self.resolve_by_ordering(confs)
    return confs.map{|p| p[0]}
  end
  
  # conflict resolution: ask the user
  def self.resolve_by_user(confs)
  end
  
  # conflict resolution: check date
  def resolve_by_user(confs)
  end

end
