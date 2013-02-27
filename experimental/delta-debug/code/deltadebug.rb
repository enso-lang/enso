=begin
Implements delta debugging for enso structures.

This is a fairly naive dd algorithm that only returns the one smallest subdelta containing the
failure-inducing change. Multiple deltas collaborating to cause a failure or likewise multiple
independent failure-causing bugs are not handled ideally.
=end

require 'core/diff/code/diff.rb'
require 'core/diff/code/patch.rb'

class DeltaDebug
  def initialize(test)
    @test = test
  end

  def dd(o1,o2)
    try(o1, o2)
  end


  #############################################################################
  #start of private section
  private
  #############################################################################

  #currently uses a really dumb algorithm that can only localize bug to one subtree
  #works well if the bug is really small

  #split a delta into two (roughly) equal halves for trying
  def split(d)
    schema_class = d.schema_class
    factory = d.factory

    res1 = factory[schema_class.name]
    res2 = factory[schema_class.name]

    #first try to split the fields
    #start by collecting all changed fields (ie all fields in the delta)
    fields = []
    schema_class.fields.each do |f|
      if f.name=="pos"
        res1[f.name] = d[f.name]
        res2[f.name] = d[f.name]
      elsif !d[f.name].nil? and
        fields << f
      end
    end

    #if this is a leaf we are done
    if fields.length == 0
      return d, d
    end

    #if there are 2+ fields, split them field-wise
    if fields.length > 1
      for i in 0..fields.length/2-1
        if !fields[i].many
          res1[fields[i].name] = d[fields[i].name]
        else
          d[fields[i].name].each do |x|
            res1[fields[i].name] << x
          end
        end
      end
      for i in fields.length/2..fields.length-1
        if !fields[i].many
          res2[fields[i].name] = d[fields[i].name]
        else
          d[fields[i].name].each do |x|
            res2[fields[i].name] << x
          end
        end
      end
      return res1, res2
    end

    #if exactly one field and it is a many field (with many objects), split it
    f = fields[0]
    return d if f.many and d[f.name].length == 0
    if f.many and d[f.name].length > 1
      vals = d[f.name].values
      for i in 0..vals.length/2-1
        res1[f.name] << vals[i]
      end
      for i in vals.length/2..vals.length-1
        res2[f.name] << vals[i]
      end
      #puts "results from CCC:"
      #Print::Print.print(res1)
      #Print::Print.print(res2)
      return res1, res2
    end

    #all else fails, try to split children
    if !f.many
      c1, c2 = split(d[f.name])
      res1[f.name] = c1
      res2[f.name] = c2
    else
      c1, c2 = split(d[f.name].values[0])
      res1[f.name] << c1
      res2[f.name] << c2
    end
    return res1, res2
  end

  def try(min, max)
    #min is the largest successful program
    #max is the smallest failing program

    d = Diff.diff(min, max)
    d1, d2 = split(d)
    return d if d1==d2 #d is too small to split any further

    #create two candidates by splitting the difference between min and max
    o1 = Patch.patch(Clone(min), d1)
    o2 = Patch.patch(Clone(min), d2)
    c1 = check(o1)
    c2 = check(o2)

    #four possible scenarios
    if c1 && !c2
      #c2 is clearly the cause, increase min to min+c1
      try(o1, max)
    elsif !c1 && c2
      #c1 is clearly the cause, increase min to min+c2
      try(o2, max)
    elsif !c1 && !c2
      #possible bugs in both c1 and c2,
      # so simply return d as the smallest subtree
      #TODO: some way of trying c1 and c2 independently
      d
    elsif c1 && c2
      #possibly bugs only manifest as a combination of c1 and c2,
      # so simply return d as the smallest subtree
      #TODO: need to further trim the tree
      d
    end
  end

  def check(o)
    begin
      @test.call(o)
      return true
    rescue
      return false
    end
  end
end
