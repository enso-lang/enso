=begin
Takes two schemas and figure out if one is a subtype of the other

Subtyping relationships on schema is similar to subtyping relationships between sums and products types
Field names are taken in consideration (since classes are tagged records) but not class names

Subtyping rules:
subtype(p1:primitive, p2:primitive) = p1==p2
subtype(c1:leaf class, c2:leaf class) =
        Forall f1 in c1.fields, Exists f2 in c2.fields, f1.name==f2.name and subtype(f1.type, f2.type)
subtype(s1:super class, s2:super class) =
        Forall c2 in s2.subs, Exists c1 in s1.subs, subtype(c1, c2)
subtype(s1:super class, c2:leaf class) =
        Exists c1 in s1.subs, subtype(c1, c2)
subtype(c1:leaf class, s2:super class) =
        Forall c2 in s2.subs, subtype(c1, c2)

Note that types are assumed to be equal until proven otherwise, so two meaninglessly circular types

  class F1 s:str val:F1 end
  class F2 s:str val:F2 end

will be considered subtypes of each other. Pierce's TPL calls this "in the limit"
=end

# Takes two schemas and return a boolean indicating whether subt <: supert

class Subtype

  def self.subtype(supert, subt)
    Subtype.new.subtype(supert, subt)
  end

  def initialize()
    @memo = {}
  end

  def subtype(supert, subt)
    return false if supert.Primitive? != subt.Primitive?
    return supert.name == subt.name if supert.Primitive?

    return @memo[[a, b]] unless @memo[[a, b]].nil?
    @memo[[a, b]] = true  #this is required to ensure termination
    res = true

    if supert.subtypes.nil? and subt.subtypes.nil?
      #every field in supert must have a field in f with the same name and of a subtype
      res = supert.name==subt.name and supert.fields.none? do |f1|
        f2 = subt.fields[f1.name]
        f2.nil? or f1.many!=f2.many or !subtype(f1.type, f2.type)
      end
    elsif !supert.subtypes.nil? and subt.subtypes.nil?
      res = subtype(supert, subt) or supert.subtypes.any? do |c1|
          subtype(c1, subt)
      end
    elsif supert.subtypes.nil? and !subt.subtypes.nil?
      res = subt.subtypes.all? do |c2|
          subtype(supert, c2)
      end
    elsif !supert.subtypes.nil? and !subt.subtypes.nil?
      res = subt.subtypes.all? do |c2|
        subtype(supert, c2) or supert.subtypes.any? do |c1|
          subtype(c1, c2)
        end
      end
    end

    @memo[[a, b]] = res
    res
  end

end
