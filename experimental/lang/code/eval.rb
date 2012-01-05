=begin
Evaluation takes place in two phases.
1. LoadRVs and ParseRVs are replaced with actual schema objects
2. Program is interpreted
=end

class LangEval

  def self.eval(prog)

    @env = {}
    @schema = nil
    @grammar_map = {}
    @interp_map = {}

    #create a new schema by dynamically loading schemas in prog header
    @schemafact = ManagedData::Factory.new(Loader.load('schema.schema'))
    @schema = Copy(schemafact, prog.schema_class.schema)
    prog.header.each do |lf|
      sch = Loader.load(lf.filename)
      gram = lf.filename.sub(".schema", "")
      CopyInto(schemafact, sch, schema)
      sch.types.each do |c|
        schema.classes[c.name].supers << schema.classes['RValue'] if c.Klass?
        @grammar_map[c.name] = gram
      end
    end

    #replace all LoadRVs and ParseRVs with actual schema objects
    @fact = ManagedData::Factory.new(schema)
    prog1 = Copy(@fact, prog)
    prog1.header.clear
    prog1 = replaceRV!(prog1)

    #eval the rest of the deal by interpretation
    env = {}
    prog1.body.each do |com|
      case com.schema_class.name
        when "Assignment"
          env[com.lhs.id] = com.rhs
        when "App"
          env1 = Hash.clone
          com.args.each do |arg|
          end
          run(com.fun, env1)

          interp = Interpreter.new(Loader.load(@grammar_map[obj.type]+'-'+com.fun+'.interp'))
      end
    end
  end


  def self.replaceRV!(obj, *args)
    begin
      send('replaceRV_'+obj.schema_class.name, obj, *args)
    rescue NoMethodError
      #send visit to each of its traversal children
      obj.schema_class.fields.each do |f|
        if f.traversal
          if !f.many
            obj[f.name] = replaceRV!(obj[f.name], *args)
          else
            list = obj[f.name]
            list.keys.each do |k|
              list[k] = replaceRV!(list[k], *args)
            end
          end
        end
      end
      obj
    end
  end

  def self.eval(obj, *args)
    send('eval_'+obj.schema_class.name, obj, *args)
  end

  def self.replaceRV_LoadRV(obj)
    rv = Loader.load(obj.filename)
    Copy(@fact, rv)
  end

  def self.replaceRV_ParseRV(obj)
    rv = Loader.load_text(@grammar_map[obj.type], @fact, obj.parse)
    Copy(@fact, rv)
  end

end
