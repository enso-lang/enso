require 'core/system/load/load'
require 'core/grammar/render/render.rb'
require 'core/schema/tools/dumpjson.rb'

require 'ripper'
require 'pp'

class Formals
  attr_accessor :normal, :block
  def initialize(normal, block)
    @normal = normal
    @block = block
  end
end

class When
  attr_accessor :expressions, :statements, :next_block
  def initialize(expressions, statements, next_block)
    @expressions = expressions
    @statements = statements
    @next_block = next_block
  end
end

class MetaDef
  attr_accessor :defn
  def initialize(defn)
    @defn = defn
  end
end

class DemoBuilder < Ripper::SexpBuilder
   def initialize(src, filename=nil, lineno=nil)
      super
      schema = Loader.load('code.schema')
      @f = ManagedData.new(schema)
    end

    class << self
      def build(src, filename=nil)
        new(src, filename).parse
      end
    end

    def on_alias(new_name, old_name)
      Undefined
    end

    def on_aref(target, args)
      make_call(target, "GET", [args[0]])
    end

    def on_aref_field(target, args)
      make_call(target, "GET", [args[0]])
    end

    def on_arg_paren(args)
      args
    end

    def on_args_add(args, arg)
      args.push(arg); args
    end

    def on_args_add_block(args, block)
      args.add_block(block) if block; args
    end

    def on_args_new
      []
    end

    def on_array(args)
      @f.List(args || [])
    end

    def on_assign(lvalue, rvalue)
      @f.Assign(lvalue, get_seq(rvalue))
    end

    def on_assoc_new(key, value)
      @f.Binding(fixup_name(key), get_seq(value))
    end

    def on_assoclist_from_args(args)
      args
    end

    def on_bare_assoc_hash(assocs)
      @f.Record
    end

    def on_BEGIN(statements)
      get_seq(statements)
    end

    def on_begin(body)
      body
    end

    def on_binary(lvalue, operator, rvalue)
      operator = fix_op(operator)
      @f.EBinOp(operator, get_seq(lvalue), get_seq(rvalue))
    end

    def fix_op(operator)
      operator = operator.to_s.gsub("@", "")
      case operator
      when "|"
        raise "Can't use | operator"
      when "&"
        raise "Can't use & operator"
      when "and"
        "&&"
      when "or"
        "||"
      when "not"
        "!"
      else
        operator
      end
    end

    def on_blockarg(arg)
      arg
    end

    def on_block_var(params, something)
      params
    end

    def on_bodystmt(body, rescue_block, else_block, ensure_block)
      if rescue_block || else_block || ensure_block
        puts "BODY #{body} RESCUE #{rescue_block} ENSURE #{ensure_block}"
        @f.Rescue(get_seq(body), rescue_block || [], ensure_block && get_seq(ensure_block))
      else
        body
      end
    end

    def on_brace_block(params, statements)
      @f.Fun(params ? params.normal : [], params && params.block, get_seq(statements))
    end

    def on_break(args)
      undefined
    end

    def on_call(target, separator, identifier)
      make_call(get_seq(target), identifier)
    end

    def on_case(test, when_block)
      #puts "CASE #{test} #{when_block}"
      #raise "Only one value for case" if test.length != 1
      if when_block.nil?
        nil
      elsif when_block.is_a?(When)
        if when_block.expressions.length == 1
          cond = @f.EBinOp("==", test, when_block.expressions[0])
        else
          cond = make_call(@f.List(when_block.expressions), "contains", [test])
        end
        @f.If(cond, when_block.statements, on_case(test, when_block.next_block))
      else
        get_seq(when_block)  # it's an else
      end
    end

    def on_CHAR(token)
      @f.Lit(token)
    end

    def on_class(const, superclass, body)
      #puts "CLASS #{const} < #{superclass} : #{body}"
      parts = split_meta(body)
      @f.Class(const, parts[0], parts[1], superclass && superclass.name)
    end

    def split_meta(body)
      parts = body.flatten.partition {|x| is_meta(x)}
      parts = [ fixup_defs(parts[0]), fixup_defs(parts[1]) ]
      return parts
    end
    
    def is_meta(d)
      if d.is_a? MetaDef
        return true
      elsif d.Assign?
        puts "DEF #{d.to.name} #{d.to.kind}"
        return d.to.kind == "@@"
      else
        return false 
      end
    end

    def fixup_defs(body)
      body.collect do |d|
        if d.is_a? MetaDef
          d.defn
        elsif d.Assign?            
          @f.Binding(fixup_name(d.to.name), d.from)
        else
          d
        end
      end
    end

    def on_class_name_error(ident)
      raise SyntaxError, 'class/module name must be CONSTANT'
    end

    def on_command(name, args)
      if name == "require" || name == "include"
        #puts "CMD #{name} #{args}"
        @f.Directive(name, args[0])
      elsif name == "attr_reader" || name == "attr_writer" || name == "attr_accessor"
        #puts "CMD #{name} #{args}"
        args.collect do |var|
          @f.Directive(name, var)
        end
      else
        make_call(nil, name, args)
      end
    end

    def on_command_call(target, separator, identifier, args)
      make_call(target, identifier, args)
    end

    def on_const(token)
      token
    end

    def on_const_path_field(namespace, const)
      raise "Can't use ::"
      # make_call(@f.Lit(namespace), const)
    end

    def on_const_path_ref(namespace, const)
      raise "Can't use ::"
      # make_call(namespace, const)
    end

    def on_const_ref(const)
      const
    end

    def on_cvar(token)
      token
    end

    def on_params(params, optionals, rest, something, block)
      raise "bad rest" if rest
      formals = []
      if params
        params.each do |x|
          formals << @f.Arg(x)
        end
      end
      if optionals
        optionals.collect do |x|
          formals << @f.Arg(x[0], x[1])
        end
      end
      #puts "FORM #{formals} #{block}"
      Formals.new(formals, block)
    end

    def get_seq(body)
      return nil if body.nil?
      return body if !body.is_a?(Array)
      if body.size == 1
        return body[0]
      else
        return @f.Seq(body)
      end
    end

    def on_def(name, params, body)
      #puts "DEF #{name} #{params} #{body}"
      @f.Binding(fixup_name(name), @f.Fun(params.normal, params.block, get_seq(body)))
    end

    def on_defs(target, separator, identifier, params, body)
      if !(target.Var? && target.name == "self")
        raise "only self meta-methods allowed"
      end
      MetaDef.new(@f.Binding(fixup_name(identifier), @f.Fun(params.normal, params.block, get_seq(body))))
    end

    def on_defined(ref)
      Ruby::Defined.new(ref)
    end

    def on_do_block(params, body)
      on_brace_block(params, body)
    end

    def on_dot2(min, max)
      make_call(@f.Var("Range"), "new", [min, max])
    end

    def on_dot3(min, max)
      undefined
    end

    def on_dyna_symbol(symbol)
      symbol.to_dyna_symbol
    end

    def on_else(statements)
      statements
    end

    def on_END(statements)
      make_call(nil, "END", nil, statements)
    end

    def on_ensure(statements)
      statements
    end

    def on_if(expression, statements, else_block)
      expression = get_seq(expression)
      if expression.EBinOp? && expression.e1.Var? && expression.e1.name == "__FILE__"
        @f.Binding("__main__", @f.Fun([], nil, get_seq(statements)))
      else
        @f.If(expression, get_seq(statements), get_seq(else_block))
      end
    end
    alias_method :on_elsif, :on_if

    def on_ifop(condition, then_part, else_part)
      @f.If(condition, then_part, else_part)
    end

    def on_if_mod(expression, statement)
      @f.If(expression, statement)
    end

    def on_fcall(identifier)
      make_call(nil, identifier)
    end

    def on_field(target, separator, identifier)
      make_call(target, identifier)
    end
    
    def make_call(target, method, args = [], block = nil)
       @f.Call(target, fixup_name(method), args, block)
    end

    def on_float(token)
      @f.Lit(token.to_f)
    end

    def on_for(variable, range, statements)
      block = @f.Fun([@f.Arg(variable.name)], nil, get_seq(statements))
      make_call(range, "each", [], block)
    end

    def on_gvar(token)
      token
    end

    def on_hash(assocs)
      @f.Record()
    end

    def on_ident(token)
      token
    end

    def on_int(token)
      @f.Lit(token.to_i)
    end

    def on_ivar(token)
      token
    end

    def on_kw(token)
      token
    end

    def on_label(token)
      token[0..-2]
    end

    def on_lambda(params, statements)
      undefined
    end

    def on_massign(lvalue, rvalue)
      undefined
    end

    def on_method_add_arg(call, args)
      if args
        args.each do |arg|
          call.args << arg
        end
      end
      call
    end

    def on_method_add_block(call, block)
      call.block = block; call
    end

    def on_mlhs_add(assignment, ref)
      undefined
    end

    def on_mlhs_add_star(assignment, ref)
      undefined
    end

    def on_mlhs_new
      []
    end

    def on_module(const, body)
      #puts "MODULE #{const} #{body}"
      parts = split_meta(body)
      @f.Module(const, parts[0], parts[1])
    end

    def on_mrhs_add(assignment, ref)
      undefined
    end

    def on_mrhs_new_from_args(args)
      undefined
    end

    def on_next(args)
      make_call(nil, "next", args)
    end

    def on_op(operator)
      operator
    end

    def on_opassign(lvalue, operator, rvalue)
      undefined
    end

    def on_paren(node)
      node
    end

    def on_parse_error(message)
      raise SyntaxError, message
    end

    def on_program(defs) # parser event
      defs.unshift(@f.Directive("require", @f.Lit("enso")))
      @f.Module("TOP", [], defs)
    end
    
    def on_qwords_add(array, word)
      array.push(Ruby::String.new(word)); array
    end

    def on_qwords_new
      []
    end

    def on_redo
      make_call(nil, "redo")
    end

    def on_regexp_add(regexp, content)
      regexp.push(content); regexp
    end

    def on_regexp_literal(regexp, rdelim)
      regexp
    end

    def on_regexp_new
      ""
    end

    def on_rescue(types, var, statements, block)
      puts "RESCUE #{types} #{var} #{block}"
      if types && types.length != 1
        raise "Only one rescue type allowed"
      end
      [@f.Handler(types && types[0], var, get_seq(statements))] + (block || [])
    end

    def on_rescue_mod(expression, statements)
      undefined
    end

    def on_rest_param(param)
      param
    end

    def on_retry
      make_call(nil, "retry")
    end

    def on_return(args)
      make_call(nil, "return", args)
    end

    def on_sclass(superclass, body)
      Ruby::SingletonClass.new(superclass, body)
    end

    def on_stmts_add(target, statement)
      target.push(statement) if statement; target
    end

    def on_stmts_new
      []
    end

    def on_string_add(string, content)
      #puts "STR #{string} #{content}"
      if string.Lit? && string.value == ""
        content
      elsif content.Lit? && content.value == ""
        string
      else
        if !string.Call? || string.name != "str"
          string = make_call(nil, "str", [string])
        end
        string.args << content
        string
      end
    end

    def on_string_concat(*strings)
      if strings.length == 0
        return @f.Lit("")
      else
        on_string_add(strings[0], on_string_concat(*strings[1..-1]))
      end
    end

    def on_string_content
      @f.Lit("")
    end

    # weird string syntax that I didn't know existed until writing this lib.
    # ex. "safe level is #$SAFE" => "safe level is 0"
    def on_string_dvar(variable)
      variable
    end

    def on_string_embexpr(expression)
      get_seq(expression)
    end

    def on_string_literal(string)
      string
    end

    def on_super(args)
      make_call(nil, "super", args)
    end

    def on_symbol(token)
      @f.Lit(token)
    end

    def on_symbol_literal(symbol)
      symbol
    end

    def on_top_const_field(field)
      field
    end

    def on_top_const_ref(const)
      const
    end

    def on_tstring_content(token)
      @f.Lit(token)
    end

    def on_unary(operator, operand)
      @f.EUnOp(fix_op(operator), operand)
    end

    def on_undef(args)
      make_call(nil, "undef", args)
    end

    def on_unless(expression, statements, else_block)
      on_if(@f.EUnOp("!", expression), statements, else_block)
    end

    def on_unless_mod(expression, statement)
      on_if_mod(@f.EUnOp("!", expression), statement)
    end

    def on_until(expression, statements)
      on_while(@f.EUnOp("!", expression), statements)
    end

    def on_until_mod(expression, statement)
      on_while_mod(@f.EUnOp("!", expression), statement)
    end

    def on_var_alias(new_name, old_name)
      undefined
    end

    def on_var_field(name)
      make_var(name)
    end

    def on_var_ref(name)
      make_var(name)
    end
    
    def make_var(name)
      kind = nil
      if name[0] == "@"
        if name[1] == "@"
          name = name[2..-1]
          kind = "@@"
        else
          name = name[1..-1]
          kind = "@"
        end
      end
      @f.Var(fixup_name(name), kind)
    end
    
    def fixup_name(name)
      if name == "[]"
         name = "get"
      end
      name = name[1..-1] if name[0]=="$"
      return name.gsub("?", "")
    end
    
    alias on_vcall on_var_ref

    def on_void_stmt
      nil
    end

    def on_when(expressions, statements, next_block)
      #puts "WHEN #{expressions} >> #{statements} NEXT #{next_block}" 
      When.new(expressions, get_seq(statements), next_block)
    end

    def on_while(expression, statements)
      @f.While(expression, get_seq(statements))
    end

    def on_while_mod(expression, statement)
      @f.While(expression, get_seq(statements))
    end

    def on_word_add(string, word)
      string.push(word); string
    end

    def on_words_add(array, word)
      array.push(word); array
    end

    def on_word_new
      ""
    end

    def on_words_new
      []
    end

    def on_xstring_add(string, content)
      on_string_add(string, content)
    end

    def on_xstring_new
      []
    end

    def on_xstring_literal(string)
      @f.Lit(string)
    end

    def on_yield(args)
      undefined
    end

    def on_yield0
      undefined
    end

    def on_zsuper(*)
      make_call(nil, "super")
    end

end

if __FILE__ == $0 then
  name = ARGV[0]
#  name = "applications/StateMachine/code/state_machine_basic.rb"
  f = File.new(name, "r")
  pp Ripper.sexp_raw(f)
  
  f = File.new(name, "r")
  m = DemoBuilder.build(f)
  g = Loader.load("code.grammar")
  jj ToJSON::to_json(m)
   
  out = File.new("#{name.chomp(".rb")}.code", "w")
  DisplayFormat.print(g, m, 80, out, false)
end


