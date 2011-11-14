=begin

Sub-type of factory that creates secure checkobjects
Secure checkobjects have a security model attach that checks for permissions each time

Note that many operations will silently fail (eg delete)

List of all security checks:

(C)reate (o:t)
- when making a new object o in the factory

(R)ead (o:t)
- when accessing any field of type t (many and non-many)
(R)ead (o:t, f)
- when accessing a field f in object o (many and non-many)

(U)pdate (o:t, f)
- when updating a field f in object o (many and non-many)

(D)elete (o:t)
- removing a traversal field with value o (many and non-many)

=end

require 'core/security/code/security'
require 'core/schema/code/factory'

class SecureFactory < Factory

  def initialize(schema, rulefile, fail_silent=false)
    @schema = schema
    @security = rulefile
    @user = nil
    @root = nil
    @fail_silent = fail_silent
  end

  def self.make_secure(obj, rulefile)
    sfact = SecureFactory.new(obj.schema_class.schema, rulefile)
    sfact.clone(obj)
  end

  def trusted_mode
    @security.trusted_mode {
      yield
    }
  end

  def clone(obj)
    @security.trusted_mode {
      Copy(self, obj)
    }
  end

  def check_privileges(op, obj, *field)
    @security.check_privileges(op, obj, *field)
  end

  def get_allow_constraints(op, obj, *field)
    @security.get_allow_constraints(op, obj, *field)
  end

  def set_root(root)
    @root = root
  end

  def set_user(user)
    @user = user
    @security.user = user
  end

  # factory.Foo(args) creates an instance of Foo initialized with arguments
  def method_missing(class_name, *args)
    obj = nil
    @security.trusted_mode {
      schema_class = @schema.classes[class_name.to_s]
      raise "Unknown class '#{class_name}'" unless schema_class
      obj = SecureCheckedObject.new(schema_class, self)
      if @root.nil?
        set_root(obj) #set the first created object as the root
      end
      n = 0
      obj.schema_class.fields.each do |field|
        if n < args.length
          if field.many
            col = obj[field.name]
            args[n].each do |x|
              col << x
            end
          else
            obj[field.name] = args[n]
          end
        elsif !field.key && !field.optional && field.type.Primitive?
          case field.type.name
          when "str" then obj[field.name] = ""
          when "int" then obj[field.name] = 0
          when "float" then obj[field.name] = 0.0
          when "bool" then obj[field.name] = false
          when "datetime" then obj[field.name] = DateTime.now
          else
            raise "Unknown type: #{field.type.name}"
          end
        elsif field.key && field.auto && field.type.Primitive? then
          case field.type.name
          when "str" then obj[field.name] = "id_#{object_id}_#{@key_gen += 1}"
          when "int" then obj[field.name] = @key_gen += 1
          else
            raise "Cannot autogen key for #{field.type.name}"
          end
        end
        n += 1
      end
      raise "too many constructor arguments supplied for '#{class_name}" if n < args.length
    }
    auth, msg = check_privileges("OpCreate", obj)
    (@fail_silent ? (return nil) : (raise SecurityError, msg)) if !auth
    return obj
  end

end

class SecureCheckedObject < CheckedObject

  def initialize(schema_class, factory) #, many_index, many, int, str, b1, b2)
    @_id = @@_id += 1
    @hash = {}
    @_origin_of = OpenStruct.new
    @_path = Paths::Path.new
    @schema_class = schema_class
    @factory = factory
    schema_class.fields.each do |field|
      if field.many
        key = ClassKey(field.type)
        if key
          @hash[field.name] = SecureManyIndexedField.new(key.name, self, field)
        else
          @hash[field.name] = SecureManyField.new(self, field)
        end
      end
    end
  end

  def ask_privileges(op, *field)
    auth, msg = @factory.check_privileges(op, self, *field)
    return auth
  end

  def [](field_name)
    if field_name[-1] == "?"
      name = field_name[0..-2]
      return @schema_class.name == name || Subclass?(@schema_class, @schema_class.schema.types[name])
    end
    field = @schema_class.all_fields[field_name];
    raise "Accessing non-existant field '#{field_name}' of #{self} of class #{self.schema_class}" unless field

    sym = field.name.to_sym
    if field.computed
      exp = field.computed.gsub(/@/, "self.")
      define_singleton_method(sym) do
        instance_eval(exp)
      end
    else
      define_singleton_method(sym) do
        #check security: can I read this entire field?
        auth1, msg1 = @factory.check_privileges("OpRead", self, field_name)
        return nil if !auth1
        res = @hash[field_name]
        #check security: can I read the target object?
        auth2, msg2 = @factory.check_privileges("OpRead", res)
        return nil if !auth2
        res
      end
    end
    return send(sym)
  end

  def []=(field_name, new)
    #check security for write permissions
    auth, msg = @factory.check_privileges("OpUpdate", self, field_name)
    @fail_silent ? (return nil) : (raise SecurityError, msg) if !auth
    field = self.schema_class.fields[field_name]
    if !field.type.Primitive? and field.traversal
      #check for delete permissions on old object
      old = @hash[field_name]
      auth, msg = @factory.check_privileges("OpDelete", old)
      @fail_silent ? (return nil) : (raise SecurityError, msg) if !auth
    end
    super
  end

end


class SecureManyIndexedField < ManyIndexedField

  def filtered
    @hash.select do |key,obj|
      auth, msg = @realself.factory.check_privileges("OpRead", obj)
      auth
    end
  end
  private :filtered

  def [](x)
    filtered()[x]
  end

  def length
    filtered().length
  end

  def keys
    filtered().keys
  end

  def values
    filtered().values
  end

  def <<(v)
    auth, msg = @realself.factory.check_privileges("OpUpdate", @realself, @field.name)
    @fail_silent ? (return nil) : (raise SecurityError, msg) if !auth
    super
  end

  def []=(k, v)
    auth, msg = @realself.factory.check_privileges("OpUpdate", @realself, @field.name)
    @fail_silent ? (return nil) : (raise SecurityError, msg) if !auth
    if !@field.type.Primitive? and @field.traversal
      old = @hash[k]
      auth, msg = @realself.factory.check_privileges("OpDelete", old)
      raise SecurityError, msg if !auth
    end
    super
  end

  def delete(v)
    #check: can I remove things from the field?
    auth, msg = @realself.factory.check_privileges("OpUpdate", @realself, @field.name)
    @fail_silent ? (return nil) : (raise SecurityError, msg) if !auth
    if !@field.type.Primitive? and @field.traversal
      #check: can I delete the removed object?
      auth, msg = @realself.factory.check_privileges("OpDelete", v)
      @fail_silent ? (return nil) : (raise SecurityError, msg) if !auth
    end
    super
  end

  def clear()
    #check: can I remove things from the field?
    auth, msg = @realself.factory.check_privileges("OpUpdate", @realself, @field.name)
    @fail_silent ? (return nil) : (raise SecurityError, msg) if !auth
    #check: reject from hash objects I have permission to delete
    if !@field.type.Primitive? and @field.traversal
      super.each do |v| #ManyField each-es do NOT return a key
        auth, msg = @realself.factory.check_privileges("OpDelete", obj)
        @hash.delete(v) if auth
      end
    end
  end

  def each(&block)
    filtered().each_value &block
  end
end

# eg. "classes" field on Schema
class SecureManyField < ManyField

  def filtered
    @list.select do |obj|
      auth, msg = @realself.factory.check_privileges("OpRead", obj)
      auth
    end
  end
  private :filtered

  def [](x)
    filtered()[x]
  end

  def length
    filtered().length
  end

  def last
    filtered().last
  end

  def <<(v)
    auth, msg = @realself.factory.check_privileges("OpUpdate", @realself, @field.name)
    @fail_silent ? (return nil) : (raise SecurityError, msg) if !auth
    if !@field.type.Primitive? and @field.traversal
      auth, msg = @realself.factory.check_privileges("OpCreate", v)
      @fail_silent ? (return nil) : (raise SecurityError, msg) if !auth
    end
    super
  end

  def []=(i, v)
    auth, msg = @realself.factory.check_privileges("OpUpdate", @realself, @field.name)
    @fail_silent ? (return nil) : (raise SecurityError, msg) if !auth
    if !@field.type.Primitive? and @field.traversal
      old = @list[i]
      auth, msg = @realself.factory.check_privileges("OpDelete", old)
      @fail_silent ? (return nil) : (raise SecurityError, msg) if !auth
    end
    super
  end

  def delete(v)
    #check: can I remove things from the field?
    auth, msg = @realself.factory.check_privileges("OpUpdate", @realself, @field.name)
    @fail_silent ? (return nil) : (raise SecurityError, msg) if !auth
    if !@field.type.Primitive? and @field.traversal
      #check: can I delete the removed object?
      auth, msg = @realself.factory.check_privileges("OpDelete", v)
      @fail_silent ? (return nil) : (raise SecurityError, msg) if !auth
    end
    super
  end

  def clear()
    #check: can I remove things from the field?
    auth, msg = @realself.factory.check_privileges("OpUpdate", @realself, @field.name)
    @fail_silent ? (return nil) : (raise SecurityError, msg) if !auth
    #check: reject from hash objects I have permission to delete
    if !@field.type.Primitive? and @field.traversal
      super.each do |v| #ManyField each-es do NOT return a key
        auth, msg = @realself.factory.check_privileges("OpDelete", obj)
        @list.delete(v) if auth
      end
    end
  end

  def each(&block)
    filtered().each &block
  end

  def values
    filtered()
  end

end
