
require 'core/grammar/check/deref-type'
require 'core/schema/code/factory'
require 'core/system/library/schema'
require 'core/system/load/load'
require 'core/grammar/check/reach-eval'
require 'core/grammar/check/mult-eval'
require 'core/grammar/check/combine'
require 'core/grammar/check/multiplicity'


class ExtractSchema
  def initialize(ss = Load::load('schema.schema'))
    @fact = Factory::new(ss)
    @anon_counter = 0
  end

  def log(str)
    # $stderr << "LOG: #{str}\n"
  end

  def extract(grammar, root, collapse = true)
    @schema = @fact.Schema
    log("Inferring reachable fields")
    tbl = ReachEval.reachable_fields(grammar)
    log("Running type inference")
    run(tbl, root)
    log("Collapsing inheritance hierarchy")
    collapse!(@schema) if collapse
    log("Inferring multiplicities")
    infer_multiplicities(tbl)
    return @schema
  end
    
  def Rule(this, in_field)
    eval(this.arg, in_field)
  end

  def Call(this, in_field)
    if @memo.has_key?(this)
      # use has_key, since nil is also bottom
      return @memo[this]
    end

    @memo[this] = nil
    x = eval(this.rule, in_field)
    log("First round of call #{this.rule.name}: #{x}")
    while x != @memo[this]
      @memo[this] = x
      x = lub(x, eval(this.rule, in_field))
      log("  next: #{x}")
    end
    return x
  end

  def Sequence(this, in_field)
    if this.elements.length == 1 then
      eval(this.elements[0], in_field)
    else
      this.elements.inject(nil) do |cur, elt|
        lub(cur, eval(elt, false))
      end
    end
  end

  def Alt(this, in_field)
    this.alts.inject(nil) do |cur, alt|
      lub(cur, eval(alt, in_field))
    end
  end

  def Regular(this, in_field)
    eval(this.arg, in_field)
  end

  def Field(this, _)
    #eval(this.arg, true)
  end


  def Value(this, _);
    primitive(this.kind == 'sym' ? 'str' : this.kind)
  end

  def Ref(this, _)
    DerefType.deref(@schema, @root_class, @owner, this.path)
  end

  def Create(this, _)
    @traversal = true
    @schema.types[this.name]
  end

  def Lit(this, in_field)
    in_field ? primitive('str') : nil
  end

  private

  def run(tbl, root)
    init_classes(tbl, root)
    i = 0
    begin
      log("Starting iteration #{i}")
      @memo = {}
      @change = false
      tbl.each do |cr, fs|
        fs.each do |f|
          log("Inferring type for #{cr.name}.#{f.name}")
          infer_field(cr, f)
        end
      end
      i += 1
    end while @change
  end


  def infer_field(cr, f)
    @traversal = false
    @owner = cls = @schema.classes[cr.name]
    unless cls.defined_fields[f.name]
      cls.defined_fields << @fact.Field(f.name)
      @change = true
    end
    type = eval(f.arg, true)
    old_type = cls.defined_fields[f.name].type
    new_type = lub(old_type, type)
    if new_type != old_type then
      cls.defined_fields[f.name].type = new_type
      @change = true
    end
    cls.defined_fields[f.name].traversal ||= @traversal
  end

  def init_classes(tbl, root)
    tbl.each_key do |cr|
      unless @schema.types[cr.name] then
        @schema.types << @fact.Class(cr.name)
      end
    end
    @root_class = @schema.types[root]
  end

  def eval(this, in_field)
    if respond_to?(this.schema_class.name) then
      #log("Evaluating: #{this}")
      x = send(this.schema_class.name, this, in_field)
      return x
    end
  end

  def primitive(name)
    unless @schema.types[name] 
      @schema.types << @fact.Primitive(name)
      @change = true
    end
    @schema.types[name]
  end

  def class_lub(t1, t2)
    xs = @schema.classes.select do |x|
      Schema::subclass?(t1, x) && Schema::subclass?(t2, x)
    end
    lub = xs.find do |x|
      any_bigger = @schema.classes.any? do |y|
        x != y && Schema::subclass?(x, y)
      end
      !any_bigger
    end
    return lub
  end


  def lub(t1, t2)
    return t1 if t2.nil?
    return t2 if t1.nil?
    return t1 if t1 == t2
    if t1.Primitive? && t2.Primitive? then
      return primitive('atom')
    elsif t1.Class? && t2.Class? then
      x = class_lub(t1, t2)
      return x if x
      anon_class = @fact.Class(anon!)
      @schema.types << anon_class
      t1.supers << anon_class
      t2.supers << anon_class
      @change = true
      return anon_class
    else
      raise "Cannot lub primitive and class types #{t1.name} and #{t2.name}"
    end
  end

  def anon!
    @anon_counter += 1
    "C_#{@anon_counter}"
  end

  def anon?(c)
    c.name =~ /^C_[0-9]+$/
  end

  def infer_multiplicities(tbl)
    result = combine(tbl, Multiplicity::ZERO) do |cr, f|
      log("Inferring multiplicity for #{cr.name}.#{f.name}")
      FieldMultEval.new(f).eval(cr.arg, false)
    end

    result.each do |c, fs|
      fs.each do |f, m|
        cls = @schema.classes[c]
        fld = cls.defined_fields[f]
        if m.is_a?(Multiplicity::Zero) then
          $stderr << "WARNING: #{c}.#{f} has multiplicity 0\n"
        elsif m.is_a?(Multiplicity::One) then
        elsif m.is_a?(Multiplicity::OneOrMore) then
          fld.many = true
        elsif m.is_a?(Multiplicity::ZeroOrMore) then
          fld.many = true
          fld.optional = true
        elsif m.is_a?(Multiplicity::ZeroOrOne) then
          fld.optional = true
        else
          raise "Unsupported multiplicity: #{m}"
        end
      end
    end
  end



  def collapse!(schema)
    del = []
    schema.classes.each do |c|
      next unless anon?(c)
      next unless c.supers.length == 1
      to_del = []
      c.subclasses.each do |sub|
        sub.supers.delete(c)
        to_del << c
        # use each because no positinos in keyed colls.
        c.supers.each do |sup|
          sub.supers << sup
        end
      end
      schema.classes.each do |c2|
        c2.defined_fields.each do |fld|
          if fld.type == c then
            # use each because no positinos in keyed colls.
            c.supers.each do |sup|
              fld.type = sup
            end
          end
        end
      end
      del << c
    end
    del.each do |c|
      schema.types.delete(c)
    end
  end


end



def dump_inheritance_dot(schema, fname)
  File.open(fname, 'w') do |f|
    f.puts("digraph inheritance {")
    schema.classes.each do |c|
      c.supers.each do |s|
        f.puts("#{s.name} -> #{c.name} [dir=back]")
      end
    end
    f.puts("}")
  end
end



if __FILE__ == $0 then
  if !ARGV[0] || !ARGV[1] then
    puts "use extract.rb <name>.grammar <rootclass> [<goal>.schema]"
    exit!(1)
  end

  require 'core/schema/tools/print'
  require 'core/grammar/check/match'
  require 'core/grammar/check/bisim'
  require 'core/grammar/check/schema-lts'
  require 'core/grammar/render/layout'

  g = Load::load(ARGV[0])
  root = ARGV[1]

  ti = ExtractSchema.new
  ns = ti.extract(g, root, true)

  dump_inheritance_dot(ns, 'bla.dot')
  Print.print(ns)

  DisplayFormat.print(Loader.load('schema.grammar'), ns)

  goal = ARGV[2]
  if goal then
    goal_s = Loader.load(goal);

    lts = LTS.new
    goal_s.classes.each do |kls|
      kls.supers.each do |sup|
        lts.transitions << Transition.new(kls, "<:", sup)
      end
      kls.fields.each do |fld|
        if !fld.computed && !fld.type.Primitive? then
          lts.transitions << Transition.new(kls, fld.name, fld.type)
        end
        if fld.type.Primitive? then
          lts.transitions << Transition.new(kls, fld.name + ":" + fld.type.name, kls)
        end
      end
    end

    ns.classes.each do |kls|
      kls.supers.each do |sup|
        a = goal_s.classes[kls.name] || kls
        b = goal_s.classes[sup.name] || sup
        lts.transitions << Transition.new(a, "<:", b)
      end
      kls.fields.each do |fld|
        if !fld.computed && !fld.type.Primitive? then
          a = goal_s.classes[kls.name] || kls
          b = goal_s.classes[fld.type.name] || fld.type
          lts.transitions << Transition.new(a, fld.name, b)
        end
        if fld.type.Primitive? then
          a = goal_s.classes[kls.name] || kls
          lts.transitions << Transition.new(a, fld.name + ":" + fld.type.name, a)
        end
      end
    end      


    puts "LTS"
    lts.transitions.each do |tr|
      puts tr
    end

    part = bisim(lts)

    puts "PARTITION RESULT: "
    part.each do |set|
      puts "\t#{set.to_a.join(', ')}"
    end



    #DisplayFormat.print(Loader.load('diff.grammar'), p)
  end
  
end
