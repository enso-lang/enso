require 'core/system/load/load'
require 'core/grammar/render/render.rb'

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
      @f.Index(target, args[1])
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
      @f.List(args)
    end

    def on_assign(lvalue, rvalue)
      @f.Assign(lvalue, rvalue)
    end

    def on_assoc_new(key, value)
      @f.Binding(key, value)
    end

    def on_assoclist_from_args(args)
      args
    end

    def on_bare_assoc_hash(assocs)
      @f.Record
    end

    def on_BEGIN(statements)
      undefined
    end

    def on_begin(body)
      body.is_a?(Ruby::ChainedBlock) ? body : body.to_chained_block
    end

    def on_binary(lvalue, operator, rvalue)
      @f.EBinOp(operator.to_s, lvalue, rvalue)
    end

    def on_blockarg(arg)
      arg
    end

    def on_block_var(params, something)
      params
    end

    def on_bodystmt(body, rescue_block, else_block, ensure_block)
      statements = [rescue_block, else_block, ensure_block].compact
      statements.empty? ? body : body.to_chained_block(statements)
    end

    def on_brace_block(params, statements)
      statements.to_block(params)
    end

    def on_break(args)
      undefined
    end

    def on_call(target, separator, identifier)
      @f.Call(target, identifier)
    end

    def on_case(args, when_block)
      undefined
    end

    def on_CHAR(token)
      @f.Lit(token)
    end

    def on_class(const, superclass, body)
      @f.Class(const, superclass, body)
    end

    def on_class_name_error(ident)
      raise SyntaxError, 'class/module name must be CONSTANT'
    end

    def on_command(name, args)
      if name == "require"
        @f.Require(args[0].value)
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
      const.namespace = namespace; const
    end

    def on_const_path_ref(namespace, const)
      const.namespace = namespace; const
    end

    def on_const_ref(const)
      const
    end

    def on_cvar(token)
      Ruby::ClassVariable.new(token, position)
    end

    def on_params(params, optionals, rest, something, block)
      raise "bad optionals" if optionals
      raise "bad rest" if rest
      params = [] if !params
      params.push block if block
      params.collect do |x|
        @f.Arg x
      end
    end

    def get_seq(body)
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
      Ruby::Method.new(target, identifier, params, body)
    end

    def on_defined(ref)
      Ruby::Defined.new(ref)
    end

    def on_do_block(params, body)
      @f.Fun(params, get_seq(body))
    end

    def on_dot2(min, max)
      Ruby::Range.new(min, max, false)
    end

    def on_dot3(min, max)
      Ruby::Range.new(min, max, true)
    end

    def on_dyna_symbol(symbol)
      symbol.to_dyna_symbol
    end

    def on_else(statements)
      Ruby::Else.new(statements)
    end

    def on_END(statements)
      @f.Call(nil, ident(:END), nil, statements)
    end

    def on_ensure(statements)
      statements
    end

    def on_if(expression, statements, else_block)
      if expression.EBinOp? && expression.e1.Var? && expression.e1.name == "__FILE__"
        @f.Binding("__main__", @f.Fun([], get_seq(statements)))
      else
        @f.If(expression, get_seq(statements), else_block)
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
      Ruby::Float.new(token, position)
    end

    def on_for(variable, range, statements)
      Ruby::For.new(variable, range, statements)
    end

    def on_gvar(token)
      token
    end

    def on_hash(assocs)
      @f.Record()
    end

    def on_ident(token)
      ident(token)
    end

    def on_int(token)
      @f.Lit(token)
    end

    def on_ivar(token)
      token
    end

    def on_kw(token)
      token
    end

    def on_label(token)
      Ruby::Label.new(token, position)
    end

    def on_lambda(params, statements)
      Ruby::Block.new(statements, params)
    end

    def on_massign(lvalue, rvalue)
      lvalue.assignment(rvalue, ident(:'='))
    end

    def on_method_add_arg(call, args)
      args.each do |arg|
        call.args << arg
      end
      call
    end

    def on_method_add_block(call, block)
      call.block = block; call
    end

    def on_mlhs_add(assignment, ref)
      assignment.push(ref); assignment
    end

    def on_mlhs_add_star(assignment, ref)
      assignment.push(Ruby::SplatArg.new(ref)); assignment
    end

    def on_mlhs_new
      []
    end

    def on_module(const, body)
      @f.Module(const, body)
    end

    def on_mrhs_add(assignment, ref)
      assignment.push(ref); assignment
    end

    def on_mrhs_new_from_args(args)
      Ruby::MultiAssignmentList.new(args.elements)
    end

    def on_next(args)
      @f.Call(nil, ident(:next), args)
    end

    def on_op(operator)
      operator.intern
    end

    def on_opassign(lvalue, operator, rvalue)
      lvalue.assignment(rvalue, operator)
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
      @f.Call(nil, ident(:redo))
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
      statements.to_chained_block(block, Ruby::RescueParams.new(types, var))
    end

    def on_rescue_mod(expression, statements)
      Ruby::RescueMod.new(expression, statements)
    end

    def on_rest_param(param)
      param
    end

    def on_retry
      @f.Call(nil, ident(:retry))
    end

    def on_return(args)
      @f.Call(nil, ident(:return), args)
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
      "#{string}#{content}"
    end

    def on_string_concat(*strings)
      Ruby::StringConcat.new(strings)
    end

    def on_string_content
      ""
    end

    # weird string syntax that I didn't know existed until writing this lib.
    # ex. "safe level is #$SAFE" => "safe level is 0"
    def on_string_dvar(variable)
      undefined
    end

    def on_string_embexpr(expression)
      expression
    end

    def on_string_literal(string)
      @f.Lit(string)
    end

    def on_super(args)
      @f.Call(nil, ident(:super), args)
    end

    def on_symbol(token)
      @f.Lit(token)
    end

    def on_symbol_literal(symbol)
      @f.Lit(symbol)
    end

    def on_top_const_field(field)
      field
    end

    def on_top_const_ref(const)
      const
    end

    def on_tstring_content(token)
      token
    end

    def on_unary(operator, operand)
      @f.Unary(operator, operand)
    end

    def on_undef(args)
      @f.Call(nil, ident(:undef), Ruby::Args.new(args.collect { |e| to_ident(e) }))
    end

    def on_unless(expression, statements, else_block)
      Ruby::Unless.new(expression, statements, else_block)
    end

    def on_unless_mod(expression, statement)
      Ruby::UnlessMod.new(expression, statement)
    end

    def on_until(expression, statements)
      Ruby::Until.new(expression, statements)
    end

    def on_until_mod(expression, statement)
      Ruby::UntilMod.new(expression, statement)
    end

    def on_var_alias(new_name, old_name)
      Ruby::Alias.new(to_ident(new_name), to_ident(old_name))
    end

    def on_var_field(field)
      @f.Var(field)
    end

    def on_var_ref(ref)
      @f.Var(ref)
    end

    alias on_vcall on_var_ref

    def on_void_stmt
      nil
    end

    def on_when(expression, statements, next_block)
      Ruby::When.new(expression, statements, next_block)
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
      @f.Call(nil, ident(:super))
    end

  private

    def ident(ident)
      ident
    end

    def to_ident(ident_or_sym)
      ident_or_sym.is_a?(Ruby::Identifier) ? ident_or_sym : ident(ident_or_sym)
    end

    def position
      Ruby::Position.new(lineno, column)
    end

 
end

# s = "def x ; 23 + 43 * 2; end"
f = File.new("applications/StateMachine/code/state_machine.rb", "r")
pp Ripper.sexp_raw(f)

f = File.new("applications/StateMachine/code/state_machine.rb", "r")
m = DemoBuilder.build(f)
g = Loader.load("code.grammar")
pp m
DisplayFormat.print(g, m)


