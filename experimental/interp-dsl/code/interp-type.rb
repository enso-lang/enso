=begin
Takes an interp and returns its schema type as a schema. Only schemas that are subtypes of
this most general type can be evaluated correctly by this interp.
=end

class InterpType

  def self.type(interp)
    InterpType.new.type(interp)
  end

  def self.subtype(supert, subt)
    #subt must have all classes in supert
    #each class in subt is individually a subtype
    supert.classes.all? do |sup|
      subt.classes.any? do |sub|
        #every field in supert must have a field in f with the same name and of a subtype
        sup.name==sub.name and sup.fields.all? do |f1|
          f2 = sub.fields[f1.name]
          res = !f2.nil? and f1.many==f2.many and f1.type.name==f2.type
          res
        end
      end
    end
  end

  def type(interp)
    #create new schema
    @factory = Factory.new(Loader.load("schema.schema"))
    @schema = @factory.Schema()

    #create primitives
    @schema.types << @factory.Primitive("int", @schema)
    @schema.types << @factory.Primitive("str", @schema)
    @schema.types << @factory.Primitive("bool", @schema)

    #create a class for each rule
    interp.rules.each do |r|
      @schema.types << @factory.Klass(r.type, @schema)
    end

    #populate classes
    interp.rules.each do |r|
      klass = @schema.classes[r.type]
      r.vars.each do |var|
        klass.defined_fields << @factory.Field(var.name, klass, @schema.types[var.type])
      end
    end

    #finalize
    @schema.finalize()
    @schema
  end



  #############################################################################
  #start of private section
  private
  #############################################################################

end
