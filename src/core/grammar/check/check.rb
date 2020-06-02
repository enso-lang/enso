
require 'core/system/library/schema'
require 'core/grammar/check/type-eval'
require 'core/grammar/check/mult-eval'
require 'core/grammar/check/reach-eval'
require 'core/grammar/check/types'
require 'core/grammar/check/multiplicity'

#=begin
#
#Open problems
#
#- check general reachability of creates? (e.g. dead code)
#- check presence, and type correctness of path references
#- check that field bindings are always on the spine, if the bound value
#  is not a path reference.
#- check correct use of primitives (i.e. in the schema)
#- deal with atoms correctly.
#- maintain lub-tree as part of computed types so that we can
#  give better error messages.
#- how to ensure that referenced classes in paths are actually
#  instantiated as such on the spine? E.g. the ref could expect
#  a field in klass C, whereas on the spine a superclass of C
#  could be created that does not have that field (cf. field.inverse)
#- have to support abstract classes to check whether all classes 
#  are represented in the grammar.
#- schemas need to identify root classes.
#- optimization: this check traverses the grammar many, many times.
#- duplicate errors with same message: because multiple creates of 
#  the same class might trigger the same error.
#- what to do with code blocks: need first class expressions.
#=end


class CheckGrammar
  include Multiplicity
  include GrammarTypes

  def self.check(schema, root_class, grammar)
    check = self.new(schema, root_class, grammar)
    errors = check.check(grammar.start)    
  end

  def initialize(schema, root_class, grammar)
    @schema = schema
    @root_class = root_class
    @grammar = grammar
    @memo = {}
  end

  def check(this)
    if respond_to?(this.schema_class.name) then
      send(this.schema_class.name, this)
    else
      []
    end
  end

  def Rule(this)
    return [] if @memo[this]
    @memo[this] = true
    check(this.arg)
  end

  def Sequence(this)
    this.elements.inject([]) do |errs, elt|
      errs + check(elt)
    end
  end

  def Alt(this)
    this.alts.inject([]) do |errs, alt|
      errs + check(alt)
    end
  end

  def Call(this)
    check(this.rule)
  end

  # todo: what if this create has multiplicity 0 ?
  def Create(this)
    # todo: also somewhere check on classes not in grammar
    klass = @schema.classes[this.name]
    errors = []
    if klass then
      fs = ReachEval.new.eval(this, false)
      te = TypeEval.new(@schema, @root_class, klass)
      fs.each do |f|
        sf = klass.fields[f.name]
        if sf then
          t = te.eval(f.arg, true)
          if t == UNDEF || t == VOID then 
            # what does VOID mean here???
            errors << uncomputable_type_error(klass, f, t)
          elsif sf.type.is_a?("Primitive") && t.primitive? then
            if sf.type != t.primitive then
              errors << incompatible_types_error(klass, f, sf.type, t.primitive)
            end
          elsif sf.type.is_a?("Primitive") then
            errors << primitive_class_mismatch(klass, f, sf.type, t.klass)
          elsif t.primitive? then
            errors << primitive_class_mismatch(klass, f, t.klass, sf.type)
          elsif !Schema::subclass?(t.klass, sf.type) # must be both klass now
            errors << incompatible_types_error(klass, f, sf.type, t.klass)
          end

          m = FieldMultEval.new(f).eval(this.arg, false)
          if !sf.optional && [ZERO, ZERO_OR_ONE, ZERO_OR_MORE].include?(m) then
            errors << optionality_mismatch(klass, f, sf, m)
          end
          if !sf.many && [ONE_OR_MORE, ZERO_OR_MORE].include?(m) then
            errors << manyness_mismatch(klass, f, sf, m)
          end          
        else
          errors << no_such_field_error(klass, f)
        end
      end

      # this does not work well with inverses
      # and code blocks
#       klass.fields.each do |f|
#         gf = fs.find { |x| x.name == f.name }
#         if !gf then
#           errors << missing_field_error(this, f)
#         end
#       end    
    else
      errors << undef_class_error(this)
    end
    errors + check(this.arg)
  end

  def Field(this)
    check(this.arg)
  end

  def Regular(this)
    check(this.arg)
  end

  private

  def undef_class_error(create)
    Error.new("undefined class #{create.name}", create.org)
  end

  def uncomputable_type_error(klass, field, type)
    Error.new("uncomputable type for #{klass.name}.#{field.name} (#{type})", field._origin)
  end


  def incompatible_types_error(klass, field, stype, gtype)
    Error.new("type of #{klass.name}.#{field.name} (#{gtype.name}) is incompatible with #{stype.name}", field._origin)
  end 

  def primitive_class_mismatch(gklass, field, prim, klass)
    # todo: make better message, you now don't know which is which
    Error.new("primitive/class mismatch #{gklass.name}.#{field}: #{prim.name} vs #{klass.name}", field._origin)
  end

  def optionality_mismatch(klass, field, sfield, mult)
    Error.new("value with multiplicity #{mult} assigned to non-optional #{klass.name}.#{sfield.name}", field._origin)
  end

  def manyness_mismatch(klass, field, sfield, mult)
    Error.new("value with multiplicity #{mult} assigned to non-many #{klass.name}.#{sfield.name}", field._origin)
  end

  def missing_field_error(create, sfield)
    Error.new("no binding for non-optional field #{create.name}.#{sfield.name}",
              create._origin)
  end


  def no_such_field_error(klass, field)
    Error.new("undefined field #{klass.name}.#{field.name}", field._origin)
  end

  class Error
    attr_reader :msg, :loc
    def initialize(msg, loc)
      @msg = msg
      @loc = loc
    end

    def to_s
      "#{msg}#{loc && (': ' + loc.to_s)}"
    end
  end
end



if __FILE__ == $0 then
  require 'colorize'

  if !ARGV[0] || !ARGV[1] || !ARGV[2] then
    puts "use check.rb <name>.grammar <name>.schema <rootclass>"
    exit!(1)
  end

  require 'core/system/load/load'

  schema = Load::load(ARGV[1])
  start = ARGV[2]
  root = schema.classes[start]
  if !root then
    $stderr << "No such root class in schema: #{start}\n"
    exit!(1)
  end
  grammar = Load::load(ARGV[0])

  errs = CheckGrammar.check(schema, root, grammar)

  errs.each do |err|
    puts err
  end
end

