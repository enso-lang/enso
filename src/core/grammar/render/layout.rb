
require 'core/expr/code/eval'
require 'core/expr/code/env'
require 'core/system/utils/paths'

module Layout
  
  # render an object into a grammar, to create a parse tree
  class RenderClass
    include Paths
  
    def initialize(slash_keywords = true)
      @depth = 0
      @stack = []
      @indent_amount = 2
      @slash_keywords = slash_keywords
      @create_stack = []
      @need_pop = 0
    end
  
    def recurse(obj, *args)
      #puts "RENDER #{obj} #{arg}"
      raise "**UNKNOWN #{obj.class} #{obj}" if !obj.schema_class.name
      send(obj.schema_class.name, obj, *args)
    end
    
    def render(grammar, obj)
      r = recurse(grammar, SingletonStream.new(obj))
      if !r
        @create_stack.each_with_index do |p, i|
          puts "*****#{i + @success >= @create_stack.length ? 'SUCCESS' : 'FAIL'}*****"          
          Print.print(p[0], 2)
          puts "-----------------"
          Print.print(p[1], 2)
        end
        puts "grammar=#{grammar} obj=#{obj}\n\n"
        Print.print(grammar)
        Print.print(obj)
        raise RuntimeError, 'Message goes here'
        abort "No matches found"
      end
      r
    end
  
    def Grammar(this, stream, container)
      # ugly, should be higher up
      @root = stream.current
      @literals = Scan.collect_keywords(this)
      this.rules.each do |rule|
        if rule.arg.alts.length == 1
          rule.arg = rule.arg.alts[0]
        end
      end
      recurse(this.start.arg, SingletonStream.new(stream.current), container)
    end
  
    def recurse(pat, data, container=nil)
      pair = [pat, data.current]
      if !@stack.include?(pair)
        @stack << pair 
        #puts "#{' '*@depth}#{pat} #{data.current}"
        @depth = @depth + 1
        val = send(pat.schema_class.name, pat, data, container)
        @depth = @depth - 1
        #puts "#{' '*@depth}#{pat} #{data.current} ==> #{val}"
        @stack.pop
        val
      end
    end
  
    def Call(this, stream, container)
      recurse(this.rule.arg, stream, container)
    end
  
    def Alt(this, stream, container)
      if !this.extra_instance_data
        this.extra_instance_data = []
        scan_alts(this, this.extra_instance_data)
        #puts "ALTS#{this.extra_instance_data}"
      end
      this.extra_instance_data.find_first do |info|
        pred = info[0]
        if !pred || pred.call(stream.current, @localEnv)
          recurse(info[1], stream.copy, container)
        end
      end
    end
    
    def scan_alts(this, alts)
      this.alts.each do |pat|
        if pat.Alt?
          scan_alts(pat, infos)
        else
          pred = PredicateAnalysis.new.recurse(pat)
          alts << [pred, pat]
        end
      end
    end
  
    def Sequence(this, stream, container)
      items = true
      ok = this.elements.all? do |x|
        item = recurse(x, stream, container)
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
  
    def Create(this, stream, container)
      obj = stream.current
      #puts "#{' '*@depth}[#{this.name}] #{obj}"
      if !obj.nil? && obj.schema_class.name == this.name
        stream.next
        @create_stack.pop(@need_pop)
        @need_pop = @success = 0
        @create_stack.push [this, obj]
        res = recurse(this.arg, SingletonStream.new(obj), obj)
        if res
          @success += 1
        end
        @need_pop += 1
        res
      else
        nil
      end
    end
  
    def Field(this, stream, container)
      obj = stream.current
      # handle special case of [[ field:"text" ]] in a grammar 
      if this.arg.Lit?
        if this.arg.value == obj[this.name]
          this.arg.value
        end
      else
        #puts "#{' '*@depth}FIELD #{this.name}"
        if this.name == "_id"
          data = SingletonStream.new(obj._id)
        else
          fld = obj.schema_class.all_fields[this.name]
          raise "Unknown field #{obj.schema_class.name}.#{this.name}" if !fld
          if fld.many
            data = ManyStream.new(obj[this.name])
          else
            data = SingletonStream.new(obj[this.name])
          end
        end
        recurse(this.arg, data, container)
      end
    end
    
    def Value(this, stream, container)
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
  
    def Ref(this, stream, container)
      obj = stream.current
      if !obj.nil?
        it = PathVar.new("it")
        path = ToPath.to_path(this.path, it)
        #puts "#{' '*@depth}RENDER #{path} REF /=#{@root} .=#{container}"
        bind = path.search(@root, container, obj)
        
        #puts "#{' '*@depth}RENDER REF '#{bind[:it]}' #{container}=#{bind}"
        output(bind[:it]) if !bind.nil? # TODO: need "." keys
      end
    end
  
    def Lit(this, stream, container)
      obj = stream.current
      #puts "#{' '*@depth}Rendering #{this.value} (#{this.value.class}) (obj = #{obj}, #{obj.class})"
      output(this.value)
    end
  
    def output(v)
      v
    end
    
    def Code(this, stream, container)
      obj = stream.current
      if this.schema_class.defined_fields.map{|f|f.name}.include?("code") && this.code != ""
       # FIXME: this case is needed to parse bootstrap grammar
        code = this.code.gsub("=", "==").gsub(";", "&&").gsub("@", "self.")
        obj.instance_eval(code)
      else
        interp = Eval::EvalExprC.new
        interp.dynamic_bind env: Env::ObjEnv.new(obj, @localEnv) do
          interp.eval(this.expr)
        end
      end
    end
  
    def Regular(this, stream, container)
      if !this.many
        # optional
        recurse(this.arg, stream, container) || true
      else
        if stream.length > 0 || this.optional
          oldEnv = @localEnv
          @localEnv = Env::HashEnv.new
          @localEnv['_length'] = stream.length
          s = []
          i = 0
          ok = true
          while ok && stream.length > 0
            @localEnv['_index'] = i
            @localEnv['_first'] = (i == 0)
            @localEnv['_last'] = (stream.length == 1)
            if i > 0 && this.sep
              v = recurse(this.sep, stream, container)
              if v
                s << v
              else
                ok = false
              end
            end
            if ok
              pos = stream.length
              v = recurse(this.arg, stream, container)
              if v
                s << v
                stream.next if stream.length == pos
                i = i + 1
              else
                ok = false
              end
            end
          end
          @localEnv = oldEnv
          s if ok && (stream.length == 0)
        end
      end
    end
    
    def NoSpace(this, stream, container)
      this
    end
    
    def Indent(this, stream, container)
      this
    end
    
    def Break(this, stream, container)
      this
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
      this.elements.reduce(nil) do |memo, x|
        pred = recurse(x)
        if memo && pred
          lambda{|obj, env| memo.call(obj, env) && pred.call(obj, env) }
        else
          memo || pred
        end
      end
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
        lambda{|obj, env| obj.length > 0 }
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
      if @data == false
        raise "not an object!!"
      end
    end
    def length
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
    def length
      @collection.length - @index
    end
    def current
      (@index < @collection.length) && @collection[@index]
    end
    def next
      @index = @index + 1
    end
    def copy
      ManyStream.new(@collection, @index)
    end
  end
  
  class DisplayFormat
    def initialize(output)
      @output = output
    end
  
    def self.print(grammar, obj, output=$stdout, slash_keywords = true)
      layout = RenderClass.new(slash_keywords).render(grammar, obj)
      #pp layout
      DisplayFormat.new(output).print(layout)
      output << "\n"
    end
  
    def initialize(out)
      @out = out
      @indent = 0
      @lines = 0
    end
  
    def print obj
      if obj == true
        # nothing
      elsif obj.is_a?(Array)
        obj.each {|x| print x}
      elsif obj.is_a?(String)
        if @lines > 0
          @out << ("\n" * @lines)
          @out << (" " * @indent)
          @lines = 0
        else
          @out << " " if @space
        end
        @out << obj
        @space = true
      elsif obj.NoSpace?
        @space = false
      elsif obj.Indent?
        @indent += 2 * obj.indent
      elsif obj.Break?
        @lines = [@lines, obj.lines].max
      else
        raise "Unknown format #{obj}"
      end
    end  
  end
end