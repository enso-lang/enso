require 'core/system/load/load'
require 'core/schema/tools/dumpjson'
require 'core/grammar/render/layout'

require 'ripper'
require 'pp'

# problems:
# - is_a? works on nil in Ruby but not JS


class Formals
  attr_accessor :normal, :block, :rest, :parens
  def initialize(normal = [], block = nil, rest = nil)
    @normal = normal
    @block = block
    @rest = rest
  end
  def to_s
    "FORMALS #{normal} *#{rest} &#{block}" 
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

class ModuleDef
  attr_accessor :name, :defs
  def initialize(name, defs)
    @name = name
    @defs = defs
  end
end

class CodeBuilder < Ripper::SexpBuilder
   def initialize(src, filename=nil, lineno=nil)
    super
    schema = Load::load('code.schema')
    @predefined = ["self", "nil", "true", "false", "raise", "puts"]
    @f = Factory::new(schema)
    reset_assigned_vars()
  end
  
  def reset_assigned_vars()
    vars = @assignedVariables
    @assignedVariables = []
    vars
  end  

  class << self
    def build(src, filename=nil)
      new(src, filename).parse
    end
  end

  def on_alias(new_name, old_name)
    raise "Variable aliases not supported"
  end

  def on_aref(target, args)
    #puts "AREF #{target} #{args}"
    if args.normal.size != 1 || args.block || args.rest
      raise "Illegal index reference"
    end
    @f.Index(target, args.normal[0])
  end

  def on_aref_field(target, args)
    on_aref(target, args)
  end

  def on_arg_paren(args)
    args.parens = true if args; args
  end

  def on_args_add(args, arg)
    #puts "ARGS #{arg}"
    args.normal << arg; args
  end

  def on_args_add_block(args, block)
    args.block = fixup_block(block) if block; args
  end
  
  def on_args_add_star(args, rest)
    args.rest = rest; args
  end

  def on_args_new
    Formals.new
  end

  def on_array(args)
    @f.List(args ? args.normal : [])
  end

  def on_assign(lvalue, rvalue)
    if lvalue.Var?
      if !lvalue.kind && !@predefined.include?(lvalue.name) && !@assignedVariables.include?(lvalue.name)
        @assignedVariables << lvalue.name
      end
    end
    @f.Assign(lvalue, get_seq(rvalue))
  end

  def on_assoc_new(key, value)
    if key.is_a?(String) then 
      name = key 
    elsif key.Lit? then 
      name = key.value 
    elsif key.Call? then 
      name = key.method 
    else 
      name = key.name
    end
    @f.Binding(name, get_seq(value))
  end

  def on_assoclist_from_args(args)
    args
  end

  def on_bare_assoc_hash(assocs)
    @f.Record(assocs)
  end

  def on_BEGIN(statements)
    get_seq(statements)
  end

  def on_begin(body)
    body
  end

  def on_binary(lvalue, operator, rvalue)
    operator = fix_op(operator)
    case operator
    when "<<"
      make_call(get_seq(lvalue), "push", [get_seq(rvalue)])
    else
      @f.EBinOp(operator, get_seq(lvalue), get_seq(rvalue))
    end
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
      #puts "BODY #{body} RESCUE #{rescue_block} ENSURE #{ensure_block}"
      @f.Rescue(get_seq(body), rescue_block || [], ensure_block && get_seq(ensure_block))
    else
      body
    end
  end

  def on_brace_block(params, statements)
    make_simple_fun(params, statements)
  end

  def on_break(args)
    raise "BREAK not allowed"
  end

  def on_call(target, separator, identifier)
    make_call(get_seq(target), identifier)
  end

  def on_case(test, when_block)
    #puts "CASE #{test} #{when_block}"
    #raise "Only one value for case" if test.size != 1
    switch = @f.Switch(test)
    scan = when_block
    while !scan.nil?
      if scan.is_a?(When)
        switch.cases << @f.Case(scan.expressions.normal, get_seq(scan.statements))
        scan = scan.next_block
      else
        switch.cases << @f.Case([], get_seq(scan))
        break
      end
    end
    switch
  end

  def on_CHAR(token)
    @f.Lit(token)
  end

  def on_class(const, superclass, body)
    #puts "CLASS #{const} < #{superclass} : #{body}"
    parts = split_meta(body)
    if superclass
      if superclass.Var?
        superclass = @f.Ref(nil, superclass.name)
      elsif superclass.Call?
        superclass = @f.Ref(superclass.target.name, superclass.method)
      else
        raise "Invalid superclass"
      end
    end
    @f.Class(const, parts[0], parts[1], parts[2], superclass)
  end

  # returns [metas, normal, includes/requires]
  def split_meta(body)
    #puts "META #{body.flatten}"
    metas = body.flatten.partition {|x| is_meta(x)}
    others = metas[1].partition {|x| !x.is_a?(ModuleDef) && (x.Ref? || x.Require?) }
    parts = [ fixup_defs(metas[0]), fixup_defs(others[1]), others[0] ]
    #puts "PARTS #{parts}"
    return parts
  end
  
  def is_meta(d)
    if d.is_a? MetaDef
      return true
    elsif d.is_a? ModuleDef
      return false
    elsif d.Assign?
      #puts "DEF #{d.to.name} #{d.to.kind}"
      return d.to.kind == "@@"
    else
      return false 
    end
  end

  def fixup_defs(body)
    body.collect do |d|
      if d.is_a? MetaDef
        d.defn
      elsif d.is_a? ModuleDef
        parts = split_meta(d.defs)
        @f.Mixin(d.name, *parts)
      elsif d.Assign?            
        @f.Binding(fixup_method_name(d.to.name), d.from)
      else
        d
      end
    end
  end

  def on_class_name_error(ident)
    raise SyntaxError, 'class/module name must be CONSTANT'
  end

  def on_command(name, args)
    if name == "require"
      path = args.normal[0].value
      mod = path.split("/")[-1]
      mod = mod.split("_").map(&:capitalize).join
      #puts "REQUIRE #{mod} #{path}"
      @f.Require(mod, path)
    elsif name == "include"
      path = args.normal[0]
      if path.Var?
        @f.Ref(nil, path.name)
      else
        path
      end
    elsif name == "attr_reader" || name == "attr_writer" || name == "attr_accessor"
      #puts "CMD #{name} #{args}"
      args.normal.collect do |var|
        @f.Attribute(var.value, name)
      end
    else
      make_call_formals(nil, name, args)
    end
  end

  def on_command_call(target, separator, identifier, args)
    make_call_formals(target, identifier, args)
  end

  def on_const(token)
    token
  end

  def on_const_path_field(namespace, const)
    @f.Ref(namespace, const)
  end

  def on_const_path_ref(namespace, const)
    @f.Ref(namespace.name, const)
  end

  def on_const_ref(const)
    const
  end

  def on_cvar(token)
    token
  end

  def on_params(params, optionals, rest, something, block)
    formals = []
    if params
      params.each do |x|
        formals << @f.Decl(x)
      end
    end
    if optionals
      optionals.collect do |x|
        formals << @f.Decl(x[0], x[1])
      end
    end
    #puts "FORM #{formals} #{block}"
    Formals.new(formals, block, rest)
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
    make_def_binding(name, params, body)
  end
  
  def make_def_binding(name, params, body)
    vars = reset_assigned_vars()
    #puts "DEF #{name} #{params} #{vars}"
    raise "can't redefine #{name}" if ["==", "is_a?"].include?(name)
    name = fixup_method_name(name)
    @f.Binding(name, make_simple_fun(params, body, vars.map {|v| @f.Decl(v) }))
  end

  def make_simple_fun(params, body, vars=[])
    if params
      make_fun(params.normal, params.block, params.rest, vars, get_seq(body))
    else
      make_fun([], nil, nil, [], get_seq(body))
    end
  end
  
  def make_fun(normal, block, rest, locals, body)
    @f.Fun(normal, block, rest, locals, body)
  end
  
  def fixup_expr(o, env=[])
    return nil if !o
    case o.schema_class.name
    when "Module"
      o.defs.each do |d| 
        @selfVar = o.name
        fixup_expr(d, env)
      end
      
    when "Class", "Mixin"
      @selfVar = "self"
      if o.schema_class.name == "Class"
        @currentParent = o.parent
      end
      o.defs.each { |d| fixup_expr(d, env) }
      o.meta.each { |d| fixup_expr(d, env) }
      
    when "Binding"
      if o.value.Fun?
        @currentMethod = o.name
        #puts "FIXUP_METHOD #{@currentMethod} #{@selfVar}"
      end
      o.value = fixup_expr(o.value, env)
  
    when "EBinOp"
      o.e1 = fixup_expr(o.e1, env)
      o.e2 = fixup_expr(o.e2, env)

    when "EUnOp"
      o.e = fixup_expr(o.e, env)
    
    when "Seq"
      fixup_list(o.statements, env)

    when "Index"
      o.base = fixup_expr(o.base, env)
      o.index = fixup_expr(o.index, env)

    when "Call"
      if o.target
        if o.target.Super?
          o.method = @currentMethod
        end
      else
        if @selfVar && !(o.method =~ /^[A-Z]/) && (o.method != "puts") 
          o.target = @f.Var(@selfVar)
        end
      end
      raise "Cannot use 'length'.. use 'size' instead" if o.method == "length"
      o.target = fixup_expr(o.target, env)
      fixup_list(o.args, env)
      o.rest = fixup_expr(o.rest, env)
      o.block = fixup_expr(o.block, env)

    when "Fun"
      newvars = []
      o.args.each {|x| newvars << x.name}
      newvars << o.block if o.block
      newvars << o.rest if o.rest
      o.locals.each {|x| newvars << x.name}
      #puts "FUN #{newvars}"
      
      newEnv = newvars + env
      o.args.each{|decl| fixup_expr(decl, newEnv) }
      o.block = fixup_var_name(o.block)
      o.rest = fixup_var_name(o.rest)
      o.locals.each{|decl| fixup_expr(decl, newEnv) }

      o.body = fixup_expr(o.body, newEnv)

    when "Decl"
      o.name = fixup_var_name(o.name)
      o.default = fixup_expr(o.default, env)

    when "Ref", "Attribute", "Super"
      
    when "Lit"
      if o.value.is_a? String
        o.value.gsub!('\\', "\\")
        o.value.gsub!('\n', "\n")
        o.value.gsub!('\"', "\"")
      end

    when "Assign"
      o.to = fixup_expr(o.to, env)
      o.from = fixup_expr(o.from, env)

    when "If"
      o.cond = fixup_expr(o.cond, env)
      o.sthen = fixup_expr(o.sthen, env)
      o.selse = fixup_expr(o.selse, env)

    when "While"
      o.cond = fixup_expr(o.cond, env)
      o.body = fixup_expr(o.body, env)

    when "Rescue"
      o.base = fixup_expr(o.base, env)
      o.rescues.each {|x| fixup_expr(x, env) }
      o.ensure = fixup_expr(o.ensure, env)
    
    when "Switch"
      o.subject = fixup_expr(o.subject, env)
      o.cases.each {|x| fixup_expr(x.body, env) }

    when "Handler"
      o.body = fixup_expr(o.body, [o.var] + env)

    when "Var"
      if o.name[0] == "$"
        o = @f.Call(@f.Var("System"), o.name.slice(1,1000))
      elsif @selfVar && !(o.name =~ /^[A-Z]/) && !o.kind && !env.include?(o.name) && !@predefined.include?(o.name)
        o = @f.Call(@f.Var(@selfVar), o.name)
      else
        o.name = fixup_var_name(o.name)
      end

    when "List"
      fixup_list(o.items, env)

    when "Record"
      o.fields.each {|x| fixup_expr(x, env) }

    else
      raise "Unknown expression type #{o.schema_class.name}"
    end 
    o
  end      
  
  @@jskeywords = ["catch", "continue", "debugger", "default", "delete", "finally", "function", "new", "in", "instanceof", "switch", "this", "throw", "try", "typeof", "var", "void", "with"]

  def fixup_var_name(name)
    if @@jskeywords.include? name
      name = "#{name}_V"
    end
    return name
  end
  
  
  def fixup_list(list, env)
    list.each_with_index do |obj, i|
      list[i] = fixup_expr(obj, env)
    end
  end

  def on_defs(target, separator, name, params, body)
    if !(target.Var? && target.name == "self")
      raise "only self meta-methods allowed"
    end
    MetaDef.new(make_def_binding(name, params, body))
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
    raise "Three dots ... not supported"
  end

  def on_dyna_symbol(symbol)
    symbol.to_dyna_symbol
  end

  def on_else(statements)
    statements
  end

  def on_END(statements)
    raise "WHAT IS THIS??"
  end

  def on_ensure(statements)
    statements
  end

  def on_if(expression, statements, else_block)
    expression = get_seq(expression)
    if expression.EBinOp? && expression.e1.Var? && expression.e1.name == "__FILE__"
      @f.Binding("__main__", make_fun([], nil, nil, [], get_seq(statements)))
    else
      @f.If(expression, get_seq(statements), get_seq(else_block))
    end
  end
  alias_method :on_elsif, :on_if

  def on_ifop(condition, then_part, else_part)
    @f.If(get_seq(condition), get_seq(then_part), get_seq(else_part))
  end

  def on_if_mod(expression, statement)
    @f.If(expression, get_seq(statement))
  end

  def on_fcall(identifier)
    make_call(nil, identifier)
  end

  def on_field(target, separator, identifier)
    make_call(target, identifier)
  end
  
  def make_call(target, method, args = [], rest = nil, block = nil)
    method = fixup_method_name(method)
    if method == "nil_P"
      @f.EBinOp("==", target, @f.Var("nil"))
    elsif method == "is_a_P"
      args = [target]+args
      @f.Call(@f.Var("System"), "test_type", args, nil, nil)
    else
      @f.Call(target, method, args, nil, fixup_block(block))
    end
  end

  def make_call_formals(target, method, args)
    make_call(target, method, args.normal, args.rest, args.block)
  end

  def on_float(token)
    @f.Lit(token.to_f)
  end

  def on_for(variable, range, statements)
    block = make_fun([@f.Decl(variable.name)], nil, nil, [], get_seq(statements))
    make_call(range, "each", [], nil, block)
  end

  def on_gvar(token)
    token
  end

  def on_hash(assocs)
    assocs.nil? ? @f.Record() : @f.Record(assocs)
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
    raise "Explicit lambda not supported (use blocks?)"
  end

  def on_massign(lvalue, rvalue)
    raise "Whatever 'massign' is, we don't currently support it"
  end

  def on_method_add_arg(call, args)
    if args
      #puts "CALL #{call} #{args}"
      args.normal.each do |arg|
        call.args << arg
      end
      raise "ARG PROBLEM" if args.rest && call.rest || args.block && call.block
      call.rest = get_seq(args.rest) if args.rest
      call.block = get_seq(args.block) if args.block
    end
    call
  end

  def on_method_add_block(call, block)
    call.block = block; call
  end
  
  def fixup_block(block)
    if block && block.Lit?
      make_fun([@f.Decl("x")], nil, nil, [], make_call(@f.Var("x"), block.value))
    else
      block
    end
  end

  def on_mlhs_add(assignment, ref)
    raise "Multiple assignments not supported"
  end

  def on_mlhs_add_star(assignment, ref)
    raise "Multiple assignments not supported"
  end

  def on_mlhs_new
    raise "Multiple assignments not supported"
  end

  def on_module(const, body)
    ModuleDef.new(const, body)
  end

  def on_mrhs_add(assignment, ref)
    raise "Multiple assignments not supported"
  end

  def on_mrhs_new_from_args(args)
    raise "Multiple assignments not supported"
  end

  def on_next(args)
    raise "NEXT not allowed"
  end

  def on_op(operator)
    operator
  end

  def on_opassign(lvalue, operator, rvalue)
    if operator[-1] == "="
      raise "LValue must be variable for assignment operator #{operator}: #{lvalue}" if !lvalue.Var?
      @f.Assign(lvalue, @f.EBinOp(operator.chop, lvalue, rvalue))
    else
      @f.Assign(lvalue, rvalue)
    end
  end

  def on_paren(node)
    node
  end

  def on_parse_error(message)
    raise SyntaxError, message
  end

  def on_program(defs) # parser event
    #puts "DEFS #{defs}"
    split = defs.partition {|x| x.is_a?(ModuleDef) }
    if split[0].size == 0
      mod = ModuleDef.new("MAIN", [])
    elsif split[0].size == 1
      mod = split[0][0]
    else
      raise "Only one top-level module allowed"
    end
    split1 = split[1].partition {|x| x.Require? }
    requires = split1[0] 
    if split1[1].size > 0
      @selfVar = nil
      others = fixup_expr(@f.Seq(split1[1]))
    else
      others = nil
    end
    
    # returns [metas, normal, includes/requires]
    parts = split_meta(mod.defs)
    fixup_expr(@f.Module(mod.name, requires, parts.flatten, others))
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
    raise "regular expressions not supported"
  end

  def on_regexp_literal(regexp, rdelim)
    raise "regular expressions not supported"
  end

  def on_regexp_new
    raise "regular expressions not supported"
  end

  def on_rescue(types, var, statements, block)
    #puts "RESCUE #{types} #{var} #{block}"
    if types && types.size != 1
      raise "Only one rescue type allowed"
    end
    [@f.Handler(types && types[0].name, var && var.name, get_seq(statements))] + (block || [])
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
    raise "Return statements are illegal"
  end

  def on_return0
    raise "Return statements are illegal"
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

  def on_string_add(base, content)
    #puts "STR #{base} #{content}"
    if base.Lit? && base.value == ""
      content
    elsif content.Lit? && content.value == ""
      base
    else
      # create the "str" call to handle string interpolation
      if !base.Call? || base.method != "S"
        base = make_call(nil, "S", [base])
      end
      base.args << content
      base
    end
  end

  def on_string_concat(*strings)
    if strings.size == 0
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
    if !args || !args.parens && args.normal == [] && !args.rest && !args.block
      raise "Super with no arguments not supported!"
    else
      make_call_formals(@f.Super, "UNKONWN", args)
    end
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
#    puts "FOO [#{token}]"
#    token = eval("\"#{token}\"")
    @f.Lit(token)
  end

  def on_unary(operator, operand)
    @f.EUnOp(fix_op(operator), get_seq(operand))
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
    raise "Variable aliases not supported"
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
    @f.Var(name, kind)
  end

  def fixup_method_name(name)
    last = name[-1]
    if name == "<<"
       name = "push"
    elsif name == "+"
       name = "add"
    elsif last == "=" && name != "[]="
       name = "set_#{name[0..-2]}"
    elsif last == "!"
       name = "#{name[0..-2]}_in_place" 
    elsif last == "?"
       name = "#{name[0..-2]}_P" 
    elsif last == "$"
       name = "#{name[0..-2]}" 
    end
    return name
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
    @f.While(get_seq(expression), get_seq(statements))
  end

  def on_while_mod(expression, statement)
    @f.While(get_seq(expression), get_seq(statements))
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
    token = eval("\"#{token}\"")
    @f.Lit(string)
  end

  def on_yield(args)
    raise "Yield not support... use an explicit block"
  end

  def on_yield0
    raise "Yield not support... use an explicit block"
  end

  def on_zsuper(*)
    make_call(nil, "super")
  end

end

if __FILE__ == $0 then
  name = ARGV[0]
  outname = ARGV[1]
  grammar = ARGV[2] || "code"
  
  #pp Ripper::SexpBuilder.new(File.new(name, "r")).parse
  
  puts "Converting to JS: #{name}"
  m = CodeBuilder.build(File.new(name, "r"))
  g = Load::load("#{grammar}.grammar")
  #jj Dumpjson::to_json(m)
   
  out = File.new(outname, "w")
  $stdout << "## storing #{outname}\n"
  Layout::DisplayFormat.print(g, m, out, false)
end


