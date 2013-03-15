require 'core/grammar/parse/deformat'


module NormalizeGrammar

  # TODO: this should just work on grammar.schema
  # without prev, next, End etc.
  
  def self.normalize(grammar)
    Normalizer.new(grammar._graph_id).normalize(grammar, []).finalize
  end

  class Normalizer    
    def initialize(fact)
      @fact = fact
    end

    def normalize(x, added)
      # puts "NORM: #{x}"
      if respond_to?(x.schema_class.name)
        send(x.schema_class.name, x, added)
      else
        x
      end
    end
    
    def Grammar(this, added)
      @grammar = this
      # snapshot
      rules = []
      this.rules.each { |r| rules << r }
      rules.each do |rule|
        m = rule.arg.alts.size
        0.upto(m-1) do |i|
          alt = rule.arg.alts[i]
          if alt.schema_class.name == 'Sequence' then
            n = alt.elements.size
            0.upto(n-1) do |j|
              alt.elements[j] = normalize(alt.elements[j], added)
            end
          else
            seq = @fact.Sequence
            seq.elements << normalize(alt, added)
            rule.arg.alts[i] = seq
          end
        end
        #puts "RULE arg is now: #{rule.arg}"
      end

      added.each do |x|
        #puts "Rule: #{x.name} arg = #{x.arg}"
        this.rules << x
      end


      this
    end

    def Sequence(this, added)
      rule = @fact.Rule
      rule.name = "Sequence_#{this._id}"
      rule.arg = @fact.Alt(nil, nil, [this])
      rule.original = this
      n = this.elements.size
      0.upto(n-1) do |i|
        this.elements[i] = normalize(this.elements[i], added)
      end
      added << rule
      @fact.Call(nil, nil, rule)
    end

    def Alt(this, added)
      rule = @fact.Rule
      rule.name = "Alt_#{this._id}"
      rule.arg = this
      n = this.alts.size
      0.upto(n-1) do |i|
        alt = this.alts[i]
        if alt.schema_class.name == 'Sequence' then
          m = alt.elements.size
          0.upto(m-1) do |j|
            alt.elements[j] = normalize(alt.elements[j], added)
          end
        else
          seq = @fact.Sequence
          seq.elements << normalize(alt, added)
          this.alts[i] = seq
        end
      end
      rule.original = this
      added << rule
      @fact.Call(nil, nil, rule)
    end

    def Create(this, added)
      #puts "Create: #{this}; added = #{added}"
      n = this.arg.elements.size
      #new_elts = []
      0.upto(n-1) do |i|
        this.arg.elements[i] = normalize(this.arg.elements[i], added)
      end
      #this.arg.elements.clear
      #new_elts.each do |x|
      #  this.arg.elements << x
      #end
      rule = @fact.Rule
      rule.name = "Create_#{this.name}_#{this._id}"
      rule.arg = @fact.Alt(nil, nil, [this.arg])
      rule.original = this
      added << rule
      call = @fact.Call
      call.rule = rule
      call
      # @fact.Call(nil, rule)
    end

    def Field(this, added)
      arg = normalize(this.arg, added)
      rule = @fact.Rule
      rule.name = "Field_#{this.name}_#{this._id}"
      rule.arg = @fact.Alt(nil, nil, [@fact.Sequence(nil, nil, [arg])])
      rule.original = this
      added << rule
      @fact.Call(nil, nil, rule)
    end
    
    def Regular(this, added)
      arg = normalize(this.arg, added)
      if !this.many && this.optional then
        rule = @fact.Rule
        rule.name = "Optional_#{this._id}"
        rule.arg = @fact.Alt(nil, nil, [@fact.Sequence(nil, nil, []), 
                                   @fact.Sequence(nil, nil, [arg])])
      elsif this.many && !this.optional && !this.sep then
        arg1 = clone(arg)
        arg2 = clone(arg)
        rule = @fact.Rule
        rule.name = "IterPlus_#{this._id}"
        rule.arg = @fact.Alt(nil, nil, [@fact.Sequence(nil, nil, [arg1, @fact.Call(nil, nil, rule)]), 
                                        @fact.Sequence(nil, nil, [arg2])])
      elsif this.many && this.optional && !this.sep then
        rule = @fact.Rule
        rule.name = "IterStar_#{this._id}"
        rule.arg = @fact.Alt(nil, nil, [@fact.Sequence(nil, nil, []), 
                                        @fact.Sequence(nil, nil, [arg, @fact.Call(nil, nil, rule)])])
      elsif this.many && !this.optional && this.sep then
        arg1 = clone(arg)
        arg2 = clone(arg)
        sep = normalize(this.sep, added)
        raise "Wrong sep: #{sep}" if !(sep.Terminal? || sep.Call?)
        rule = @fact.Rule
        rule.name = "IterPlusSep_#{this._id}"
        rule.arg = @fact.Alt(nil, nil, [@fact.Sequence(nil, nil, [arg1]), 
                                   @fact.Sequence(nil, nil, [arg2, sep, @fact.Call(nil, nil, rule)])])
      elsif this.many && this.optional && this.sep then
        arg1 = clone(arg)
        arg2 = clone(arg)
        sep = normalize(this.sep, added)
        raise "Wrong sep: #{sep}" if !(sep.Terminal? || sep.Call?)
        helper = @fact.Rule
        helper.name = "IterPlusSepHelper_#{this._id}"
        helper.arg = @fact.Alt(nil, nil, [@fact.Sequence(nil, nil, [arg1]), 
                                     @fact.Sequence(nil, nil, [arg2, sep, @fact.Call(nil, nil, helper)])])
        helper.original = this
        added << helper
        rule = @fact.Rule
        rule.name = "IterStarSep_#{this._id}"
        rule.arg = @fact.Alt(nil, nil, [@fact.Sequence(nil, nil, []), 
                                   @fact.Sequence(nil, nil, [@fact.Call(nil, nil, helper)])])
      else
        raise "Invalid regular: #{this}"
      end
      rule.original = this
      added << rule
      @fact.Call(nil, nil, rule)
    end

    def clone(arg)
      if arg.Call? then
        @fact.Call(nil, nil, arg.rule)
      elsif arg.Terminal? || arg.Epsilon? then
        Copy.new(@fact).copy(arg)
      else
        raise "Error invalid normalized item"
      end
    end

  end


end


if __FILE__ == $0 then
  require 'core/system/load/load'
  require 'core/grammar/render/layout'
  require 'core/schema/tools/copy'

  gg1 = Load::load('grammar.grammar')
  DeformatGrammar::deformat(gg1)
  gg_norm = NormalizeGrammar::normalize(copy(gg1))

  gg2 = Load::load('grammar.grammar')
  # Print::print(gg_norm)
  puts gg_norm.inspect
  Layout::DisplayFormat.print(gg2, gg_norm, $stdout, false)
end
