require 'core/expr/code/eval'
require 'core/expr/code/env'
require 'core/schema/tools/print'
require 'core/schema/code/factory'
require 'core/system/utils/paths'
require 'core/system/library/schema'
require 'core/semantics/code/interpreter'

module Layout
  
  # render an object into a grammar, to create a parse tree
  module RenderGrammar
    include Interpreter::Dispatcher

    def render(pat)
      stream = @D[:stream]
      @stack ||= []
      pair = "#{pat.to_s}/#{stream.current}"  # have to use strings, for JavaScript!
      if !@stack.include?(pair) # avoid infinite loop on recursive grammars
        @stack << pair 
        val = dispatch_obj(:render, pat)
        @stack.pop
        val
      end
    end

    def render_Grammar(this)
      stream = @D[:stream]
      @stack = []
      @create_stack = []
      @need_pop = 0
      # ugly, should be higher up
      @root = stream.current
      if @slash_keywords
        @literals = Scan.collect_keywords(this)
      end
      @modelmap = {}
      out = render(this.start.arg)
      format = {}
      format[:lines] = 0
      format[:space] = false
      format[:indent] = 0
      #puts @modelmap
      combine out, format
    end

    def render_Call(this)
      render(this.rule.arg)
    end

    def render_Alt(this)
      stream = @D[:stream]
      if @avoid_optimization
        this.alts.find_first do |pat|
          dynamic_bind stream: stream.copy do
            render(pat)
          end
        end
      else
        if !this.extra_instance_data
          this.extra_instance_data = []
          scan_alts(this, this.extra_instance_data)
          #puts "ALTS#{this.extra_instance_data}"
        end
        this.extra_instance_data.find_first do |info|
          pred = info[0]
          if !pred || pred.call(stream.current, @localEnv)
            dynamic_bind stream: stream.copy do
              render(info[1])
            end
          end
        end
      end
    end

    def render_Sequence(this)
      items = true
      ok = this.elements.all? do |x|
        item = render(x)
        if item
          if item == true
            true
          else
            if items.is_a?(Array)
              items << item
            elsif items != true
              items = [items, item]
            else
              items = item
            end
          end
        end
      end
      items if ok
    end

    def render_Create(this)
      stream = @D[:stream]
      obj = stream.current
      #puts "#{' '.repeat(@depth)}[#{this.name}] #{obj}"
      if !obj.nil? && obj.schema_class.name == this.name
        stream.next
        @create_stack.pop(@need_pop)
        @need_pop = @success = 0
        @create_stack.push [this, obj]
        res = dynamic_bind stream: SingletonStream.new(obj) do
          render(this.arg)
        end
        if res
          @success += 1
        end
        @need_pop += 1
        #this is the place to put some kind of tag around the res....
        if @add_tags and res!=nil
          format = {}
          format[:lines] = 0
          format[:space] = false
          format[:indent] = 0
          res = "*[*debug id='#{obj.schema_class.name}#{obj._id}'*]*" + combine(res, format) + "*[*/debug*]*"
        end
        @modelmap[res] = obj
        res
      else
        nil
      end
    end
  
    def render_Field(this)
      stream = @D[:stream]
      obj = stream.current
      # handle special case of [[ field:"text" ]] in a grammar 
      if this.arg.Lit?
        if this.arg.value == obj[this.name]
          this.arg.value
        end
      else
        #puts "#{' '.repeat(@depth)}FIELD #{this.name}"
        if this.name == "_id"
          data = SingletonStream.new(obj._id)
        else
          fld = obj.schema_class.all_fields[this.name]
          raise "Unknown field #{obj.schema_class.name}.#{this.name}" if !fld
#          path = obj.path().field(this.name)
          if fld.many
            data = ManyStream.new(obj[this.name])
          else
            data = SingletonStream.new(obj[this.name])
          end
        end
        res = dynamic_bind stream: data do
          render(this.arg)
        end
        if @add_tags and res!=nil
          format = {}
          format[:lines] = 0
          format[:space] = false
          format[:indent] = 0
          res = "*[*debug id='#{obj.schema_class.name}#{obj._id}#{this.name}'*]*" + combine(res, format) + "*[*/debug*]*"
        end
        res
      end
    end
    
    def render_Value(this)
      stream = @D[:stream]
      obj = stream.current
      if !obj.nil?
        if !(obj.is_a?(String) || obj.is_a?(Fixnum)  || obj.is_a?(Float))
          raise "Data is not literal #{obj}"
        end
        case this.kind
        when "str"
          if obj.is_a?(String)
            output(obj.inspect)
          end
        when "sym"
          if obj.is_a?(String)
            if @slash_keywords && @literals.include?(obj) then
              output('\\' + obj)
              output(obj)
            else
             output(obj)
            end
          end
        when "int"
          if obj.is_a?(Fixnum)
            output(obj.to_s)
          end
        when "real"
          if obj.is_a?(Float)
            output(obj.to_s)
          end
        when "atom"
          if obj.is_a?(String)
            output(obj.inspect)
          else
            output(obj.to_s)
          end
        else
          raise "Unknown type #{this.kind}"
        end
      end
    end
  
    def render_Ref(this)
      stream = @D[:stream]
      obj = stream.current
      if !obj.nil?
        # TODO: this is complete cheating! we need to search the path
        key_field = Schema::class_key(obj.schema_class)
        output(obj[key_field.name()])
      end
    end
  
    def render_Lit(this)
      stream = @D[:stream]
      obj = stream.current
      #puts "#{' '.repeat(@depth)}Rendering #{this.value} (#{this.value.class}) (obj = #{obj}, #{obj.class})"
      output(this.value)
    end
    
    def render_Code(this)
      stream = @D[:stream]
      obj = stream.current
      if this.expr.EBinOp? and this.expr.op=="eql?"
        rhs = Eval.eval(this.expr.e2, env: Env::ObjEnv.new(obj, @localEnv))
        if rhs.is_a? Factory::MObject
          lhs = Eval.eval(this.expr.e1, env: Env::ObjEnv.new(obj, @localEnv))
          puts "blah"
          lhs.schema_class == rhs.schema_class
        else
          Eval.eval(this.expr, env: Env::ObjEnv.new(obj, @localEnv))
        end
      else
        Eval.eval(this.expr, env: Env::ObjEnv.new(obj, @localEnv))
      end
    end
  
    def render_Regular(this)
      stream = @D[:stream]
      if !this.many
        # optional
        render(this.arg) || true
      else
        if stream.size > 0 || this.optional
          oldEnv = @localEnv
          @localEnv = Env::HashEnv.new
          @localEnv['_size'] = stream.size
          s = []
          i = 0
          ok = true
          while ok && stream.size > 0
            @localEnv['_index'] = i
            @localEnv['_first'] = (i == 0)
            @localEnv['_last'] = (stream.size == 1)
            if i > 0 && this.sep
              v = render(this.sep)
              if v
                s << v
              else
                ok = false
              end
            end
            if ok
              pos = stream.size
              v = render(this.arg)
              if v
                s << v
                stream.next if stream.size == pos
                i = i + 1
              else
                ok = false
              end
            end
          end
          @localEnv = oldEnv
          s if ok && (stream.size == 0)
        end
      end
    end
    
    def render_NoSpace(this)
      this
    end
    
    def render_Indent(this)
      this
    end
    
    def render_Break(this)
      this
    end
  
    def output(v)
      v
    end
    
    def scan_alts(this, alts)
      this.alts.each do |pat|
        if pat.Alt?
          scan_alts(pat, infos)
        else
          pred = PredicateAnalysis.new.recurse(pat)
          puts "pred = #{pred}"
          alts << [pred, pat]
        end
      end
    end

    def combine(obj, format)
      if obj == true
        # nothing
        ""
      elsif obj.is_a?(Array)
#        if @modelmap[obj]
#          o = @modelmap[obj]
#          @out << "<div id='<#{o.schema_class.name}:#{o._id}>' style='font-size: 48pt; color: fuchsia'>"
#          obj.each {|x| combine x}
#          @out << "</div>"
#        else
          res = ""
          obj.each {|x| res = res + combine(x, format)}
          res
#        end
      elsif obj.is_a?(String)
        res = ""
        if format[:lines] > 0
          res = res + ("\n".repeat(format[:lines]))
          res = res + (" ".repeat(format[:indent]))
          format[:lines] = 0
        else
          (res = res + " ") if format[:space]
        end
        res = res + obj
        format[:space] = true
        res
      elsif obj.NoSpace?
        format[:space] = false
        ""
      elsif obj.Indent?
        format[:indent] = format[:indent] + 2 * obj.indent
        ""
      elsif obj.Break?
        format[:lines] = System.max(format[:lines], obj.lines)
        ""
      else
        raise "Unknown format #{obj}"
      end
    end  

  end
  
  class PredicateAnalysis
  
    def recurse(pat)
      send(pat.schema_class.name, pat)
    end
  
    def Call(this)
      recurse(this.rule.arg)
    end
  
    def Alt(this)
      if this.alts.all? {|alt| alt.Field? && alt.arg.Lit? }
        fields = this.alts.map {|alt| alt.name }
        name = fields[0]
        #puts "ALT lits!! #{fields}"
        if fields.all? {|x| x == name}
          symbols = this.alts.map {|alt| alt.arg.value }
          lambda{|obj, env| symbols.include?(obj[name]) }
        end
      end
    end
  
    def Sequence(this)
      memo = nil
      this.elements.each do |x|
        pred = recurse(x)
        if memo && pred
          lambda{|obj, env| memo.call(obj, env) && pred.call(obj, env) }
        else
          memo ||= pred
        end
      end
      memo
    end
  
    def Create(this)
      name = this.name
      pred = recurse(this.arg)
      if pred
        lambda{|obj, env| !obj.nil? && obj.schema_class.name == name && pred.call(obj, env)}
      else
        lambda{|obj, env| !obj.nil? && obj.schema_class.name == name}
      end
    end
  
    def Field(this)
      name = this.name
      # handle special case of [[ field:"text" ]] in a grammar 
      if this.arg.Lit?
        value = this.arg.value
        lambda{|obj, env| value == obj[name]}
      elsif this.name != "_id"
        pred = recurse(this.arg)
        if pred
          lambda{|obj, env| pred.call(obj[name], env)}
        end
      end
    end
    
    def Value(this)
    end
  
    def Ref(this)
      lambda{|obj, env| !obj.nil?}
    end
  
    def Lit(this)
    end
  
    def Code(this)
      if this.schema_class.defined_fields.map{|f|f.name}.include?("code") && this.code != ""
       # FIXME: this case is needed to parse bootstrap grammar
        code = this.code.gsub("=", "==").gsub(";", "&&").gsub("@", "self.")
        lambda{|obj, env| obj.instance_eval(code) }
      else
        interp = Eval::EvalExprC.new
        lambda do |obj, env| 
          interp.dynamic_bind env: Env::ObjEnv.new(obj, env) do
            interp.eval(this.expr)
          end
        end
      end
    end
  
    def Regular(this)
      if this.many && !this.optional
        lambda{|obj, env| obj.size > 0 }
      end
    end
    
    def NoSpace(this)
    end
    
    def Indent(this)
    end
    
    def Break(this)
    end
  end
  
  class SingletonStream
    def initialize(data, used = false)
      @data = data
      @used = used
    end
    def size
      @used ? 0 : 1
    end
    def current
      @used ? nil : @data
    end
    def next
      @used = true
    end
    def copy
      SingletonStream.new(@data, @used)
    end
  end
  
  class ManyStream
    def initialize(collection, index = 0)
      @collection = collection.is_a?(Array) ? collection : collection.values 
      @index = index
      if @collection.include?(false)
        raise "not an object!!"
      end
    end
    def size
      @collection.size - @index
    end
    def current
      (@index < @collection.size) && @collection[@index]
    end
    def next
      @index = @index + 1
    end
    def copy
      ManyStream.new(@collection, @index)
    end
  end
 
  class DisplayFormat
    include RenderGrammar

    def self.print(*args)
      Layout::DisplayFormat.new.print(*args)
    end

    def print(grammar, obj, output=$stdout, slash_keywords = true, add_tags=false)
#      interp = RenderGrammarC.new
      @slash_keywords = slash_keywords
      @avoid_optimization = true
      @out = output
      @add_tags = add_tags
      res = dynamic_bind stream: SingletonStream.new(obj) do
        render(grammar)
      end
      output << res
      output << "\n"
      res
    end
  end
end

