require 'core/system/load/load'
require 'core/grammar/render/render.rb'
require 'core/schema/tools/dumpjson.rb'

require 'ripper'
require 'pp'

class Params
  attr_accessor :params, :optionals, :rest, :block
  def initialize(params, optionals, rest, block)
    @params = params
    @optionals = optionals
    @rest = rest
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

class DemoBuilder < Ripper::SexpBuilder
   def initialize(src, filename=nil, lineno=nil)
      super
      schema = Loader.load('code.schema')
      @f = ManagedData::Factory.new(schema)
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
      @f.Index(target, args[0])
    end

    def on_aref_field(target, args)
      @f.Index(target, args[0])
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
      @f.Assign(lvalue, rvalue)
    end

    def on_assoc_new(key, value)
      @f.Binding(key, get_seq(value))
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
      puts "#{operator}"
      op = fix_op(operator)
      case op
      when "and"
        op = "&&"
      when "or"
        op = "||"
      end
      @f.EBinOp(op, get_seq(lvalue), get_seq(rvalue))
    end

    def fix_op(operator)
      operator.to_s.gsub("@", "")
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
      @f.Fun(params || [], get_seq(statements))
    end

    def on_break(args)
      undefined
    end

    def on_call(target, separator, identifier)
      @f.Call(get_seq(target), identifier)
    end

    def on_case(test, when_block)
      puts "CASE #{test} #{when_block}"
#      raise "Only one value for case" if test.length != 1
      if when_block.nil?
        nil
      elsif when_block.is_a?(When)
        if when_block.expressions.length == 1
          cond = @f.EBinOp("==", test, when_block.expressions[0])
        else
          cond = @f.Call(@f.List(when_block.expressions), "contains", [test])
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
      puts "CLASS #{const} < #{superclass} : #{body}"
      @f.Class(const, body, superclass && superclass.name)
    end

    def on_class_name_error(ident)
      raise SyntaxError, 'class/module name must be CONSTANT'
    end

    def on_command(name, args)
      if name == "require" || name == "include"
        @f.Directive(name, args[0])
      else
        @f.Call(nil, name, args)
      end
    end

    def on_command_call(target, separator, identifier, args)
      @f.Call(target, identifier, args)
    end

    def on_const(token)
      token
    end

    def on_const_path_field(namespace, const)
      @f.Call(@f.Lit(namespace), const)
    end

    def on_const_path_ref(namespace, const)
      @f.Call(namespace, const)
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
      formals.push block if block
      formals
    end

    def get_seq(body)
      puts "SEQ #{body}"
      return nil if body.nil?
      return body if !body.is_a?(Array)
      if body.size == 1
        return body[0]
      else
        return @f.Seq(body)
      end
    end

    def on_def(name, params, body)
      @f.Binding(name, @f.Fun(params, get_seq(body)))
    end

    def on_defs(target, separator, identifier, params, body)
      # TODO: target!!!
      @f.Binding(identifier, @f.Fun(params, get_seq(body)))
    end

    def on_defined(ref)
      Ruby::Defined.new(ref)
    end

    def on_do_block(params, body)
      @f.Fun(params || [], get_seq(body))
    end

    def on_dot2(min, max)
      @f.Call(@f.Var("Range"), "new", [min, max])
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
      @f.Call(nil, "END", nil, statements)
    end

    def on_ensure(statements)
      statements
    end

    def on_if(expression, statements, else_block)
      expression = get_seq(expression)
      if expression.EBinOp? && expression.e1.Var? && expression.e1.name == "__FILE__"
        @f.Binding("__main__", @f.Fun([], get_seq(statements)))
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
      @f.Call(nil, identifier)
    end

    def on_field(target, separator, identifier)
      @f.Call(target, identifier)
    end

    def on_float(token)
      @f.Lit(token.to_f)
    end

    def on_for(variable, range, statements)
      @f.Call(range, "each", @f.Fun([variable], get_seq(statements)))
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
      @f.Module(const, body)
    end

    def on_mrhs_add(assignment, ref)
      undefined
    end

    def on_mrhs_new_from_args(args)
      undefined
    end

    def on_next(args)
      @f.Call(nil, "next", args)
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
      @f.Module("TOP", defs)
    end
    
    def on_qwords_add(array, word)
      array.push(Ruby::String.new(word)); array
    end

    def on_qwords_new
      []
    end

    def on_redo
      @f.Call(nil, "redo")
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
      if types && types.length != 1
        raise "Only one rescue type allowed"
      end 
      if block
        [@f.Handler(types && types[0], var, statements)] + on_rescue(block)
      else
        []
      end
    end

    def on_rescue_mod(expression, statements)
      undefined
    end

    def on_rest_param(param)
      param
    end

    def on_retry
      @f.Call(nil, "retry")
    end

    def on_return(args)
      @f.Call(nil, "return", args)
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
      puts "STR #{string} #{content}"
      if string.Lit? && string.value == ""
        content
      elsif content.Lit? && content.value == ""
        string
      else
        if !string.Call? || string.name != "str"
          string = @f.Call(nil, "str", [string])
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
      @f.Call(nil, "super", args)
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
      @f.Call(nil, "undef", args)
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
      @f.Var(name)
    end

    def on_var_ref(name)
      name = name[1..-1] if name[0]=="$"
      @f.Var(name)
    end

    alias on_vcall on_var_ref

    def on_void_stmt
      nil
    end

    def on_when(expressions, statements, next_block)
      puts "WHEN #{expressions} >> #{statements} NEXT #{next_block}" 
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
      @f.Call(nil, "super")
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
  DisplayFormat.print(g, m, 80, out)
end


