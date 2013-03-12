

class DerefSchema

  def initialize(schema, root)
    @schema = schema
    @root = root
    #puts "ROOT = #{root}"
  end

  def deref(this, klass)
    #puts "DEREF: #{this} in #{klass}"
    if respond_to?(this.schema_class.name)
      send(this.schema_class.name, this, klass)
    else
      nil
    end
  end

  def EVar(this, klass)
    if this.name == 'root' then
      @root
    elsif this.name == 'this' then
      #puts "RETURNING #{klass} for 'this'"
      klass
    else
      raise "Only 'this' and 'root' are supported (got #{this.name})"
    end
  end

  def EField(this, klass)
    kls = deref(this.e, klass)
    f = kls.all_fields[this.fname]
    if f.nil? then
      f = first_in_subclasses(kls, this.fname)
    end
    #puts "FINDING: #{f && f.name} with #{f && f.type}" 
    return f && f.type
  end

  def ESubscript(this, klass)
    deref(this.e, klass)
  end

  private

  def first_in_subclasses(kls, fname)
    # NB: we search for a field in the subclasses
    # of kls because references in the grammar
    # may assume more specific types than
    # the ones "declared"
    # e.g. for a path this.b.c, it may be that
    # b refers to a type B but that the field
    # c is only in one or more of the subclasses
    # of B.
    #puts "FINDING #{fname} in #{kls}"
    kls.subclasses.each do |sub|
      f = sub.all_fields[fname]
      #puts "->>FOUND #{f}" if f
      return f if f
      first_in_subclasses(sub, fname)
    end
    nil
  end
end
    
      
