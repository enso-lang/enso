
require 'core/system/load/load'
require 'core/system/library/schema'
require 'core/grammar/code/typeof'
require 'core/grammar/code/nullable'


## TODO: check for (possible) multiplicity violations

class CheckGrammar

  def self.check(grammar, schema)
    self.new(schema).check(grammar.start)
  end

  def initialize(schema)
    @schema = schema
    @typeof = TypeOf.new(schema)
    @nullable = Nullable.new
    @memo = {}
  end

  def check(this, klass = nil, errors = [])
    if respond_to?(this.schema_class.name)
      send(this.schema_class.name, this, klass, errors)
    end
    errors
  end


  def Sequence(this, klass, errors)
    this.elements.each do |elt|
      check(elt, klass, errors)
    end
  end
  
  def Call(this, klass, errors)
    # NB: it essential we memoize on calls
    # *not* on rules, because we have to 
    # traverse rules multiple times for
    # different call sites
    return if @memo[this]
    @memo[this] = true
    check(this.rule, klass, errors)
  end

  def Rule(this, klass, errors)
    return unless this.arg
    check(this.arg, klass, errors)
  end

  def Create(this, _, errors)
    klass = @schema.classes[this.name]
    if !klass then
      errors << undef_class_error(this.name, this._origin)
    end
    check(this.arg, klass, errors)
  end

  def Field(this, klass, errors)
    if klass then

      # Memoize on field/klass combo
      @memo[this] ||= []
      return if @memo[this].include?(klass)
      @memo[this] << klass


      field = klass.fields[this.name]
      if field then
        # a set of types to deal with alternatives
        ts = @typeof.typeof(this.arg) 
        if ts.empty? then
          errors << field_error("no type available", field, this._origin)
        else
          if !field.optional && @nullable.nullable?(this)
            errors << field_error("nullable symbol", field, this._origin)
          end
          t1 = field.type
          ts.each do |t2|
            if t2.nil? then
              errors << field_error("untypable symbol", field, this._origin)
            elsif t1.Primitive? && t1.name == 'atom' && t2.Primitive? then
              next # all primitives can be assigned to atoms
            elsif t1.Primitive? && t2.Primitive? && t1 != t2 then
              errors << field_error("primitive mismatch #{t2.name} vs #{t1.name}", field, this._origin)
            elsif t1.Primitive? != t2.Primitive? then
              errors << field_error("type mismatch #{t2.name} vs #{t1.name}", field, this._origin)
            elsif !Subclass?(t2, t1) then
              # it now gives an error for each concrete class (mentioned in the grammar)
              # could do a lub if all types in ts are classes and the lub exists.
              errors << field_error("class mismatch #{t2.name} vs #{t1.name}", field, this._origin)
            end
          end
        end
      else
        errors << undef_field_error(this.name, klass, this._origin)
      end
    end

    # continue checking the argument
    check(this.arg, klass, errors)
  end

  def Alt(this, klass, errors)
    this.alts.each do |alt|
      check(alt, klass, errors)
    end
  end

  def Ref(this, _, errors)
    klass = @schema.classes[this.name]
    unless klass then
      errors << undef_class_error(this.name, this._origin)
    end
  end

  def Regular(this, klass, errors)
    check(this.arg, klass, errors)
  end

  private

  def undef_class_error(name, org)
    Error.new("undefined class #{name}", org)
  end

  def undef_field_error(name, klass, org)
    Error.new("undefined field #{klass.name}.#{name}", org)
  end

  def field_error(msg, fld, org)
    Error.new("#{msg} for #{fld.owner.name}.#{fld.name}", org)
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

  if ARGV[0] then
    grammars = [ARGV[0]]
  else
    grammars = ['diasuite.grammar',
                'esync.grammar',
                #              'ooal.grammar',
                'families.grammar',
                'genealogy.grammar',
                'graph.grammar',
                'pointer.grammar',
                'ledger.grammar',
                'petrinet.grammar',
                'petstore.grammar',
                'fexp.grammar',
                'repmin.grammar',
                #              'simpl.grammar',
                'state_machine.grammar',
                'todo.grammar',
                'diagram.grammar',
                'stencil.grammar',
                'grammar.grammar',
                'instance.grammar',
                'schema.grammar',
                'auth.grammar',
                'content.grammar',
                'element.grammar',
                'web-base.grammar',
                'web.grammar',
                'xml.grammar',
                'point.grammar']
  end

  errs = {}
  grammars.each do |grammar|
    g = Loader.load(grammar)
    s = Loader.load(grammar.split('.')[0] + ".schema")
    errs[grammar] = CheckGrammar.check(g, s)
  end

  errs.each do |grammar, errs|
    next if errs.empty?
    puts "Errors for #{grammar}".red
    errs.each do |err|
      puts err
    end
  end
end

