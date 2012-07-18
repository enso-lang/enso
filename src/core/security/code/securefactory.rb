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

module SecureFactory

  module SecureFactoryMixin
    attr_accessor :security, :fail_silent, :user, :trusted

    def make_secure(obj)
      trusted_mode {
        Copy(self, obj)
      }
    end

    def check_privileges(op, obj, field=nil)
      @trusted = 0 unless @trusted
      if @trusted > 0
        true
      else
        @interp.check(@security, op: op, obj: obj, field: field, user: @user)
      end
    end

    def trusted_mode
      @trusted = 0 unless @trusted
      @trusted = @trusted + 1
      res = yield
      @trusted = @trusted - 1
      res
    end
  end

  module SecureMObjectMixin
    def [](name)
      #check security: can I read this entire field?
      auth1, msg1 = check_privileges("OpRead", self, name)
      if !auth1
        raise SecurityError, "Trying to access #{name} in #{self}"
      end
      nil if !auth1
      super if auth1
    end

    def []=(name, x)
      auth1, msg = check_privileges("OpUpdate", @self, name)
      raise SecurityError, msg if !auth1 and !@fail_silent
      field = schema_class.fields[name]
      auth2 = true
      if !field.type.Primitive? and field.traversal
        old = self[name]
        auth2, msg = check_privileges("OpDelete", old)
        raise SecurityError, msg if !auth2 and !@fail_silent
      end
      super if auth1 and auth2
    end

    def delete!
      auth, msg = check_privileges("OpDelete", self)
      raise SecurityError, msg if !auth and !@fail_silent
      super if auth
    end

    def check_privileges(op, obj, field=nil)
      @factory.check_privileges(op, obj, field)
    end
  end

  module SecureSingleMixin
    def get
      res = super
      auth2, msg2 = @owner.check_privileges("OpRead", res)
      !auth2 ? nil : res
    end
  end

  module SecureManyMixin

    def <<(mobj)
      auth, msg = @owner.check_privileges("OpUpdate", @owner, @field.name)
      raise SecurityError, msg if !auth and !@fail_silent
      super if auth
    end

    def delete(mobj)
      auth2, msg = @owner.check_privileges("OpUpdate", @owner, @field.name)
      raise SecurityError, msg if !auth2 and !@fail_silent
      auth3, msg = @owner.check_privileges("OpDelete", mobj)
      raise SecurityError, msg if !auth3 and !@fail_silent
      super if auth2 and auth3
    end

    def __insert(mobj)
      auth, msg = @owner.check_privileges("OpUpdate", @owner, @field.name)
      raise SecurityError, msg if !auth and !@fail_silent
      super if auth
    end

    def __delete(mobj)
      auth2, msg = @owner.check_privileges("OpUpdate", @owner, @field.name)
      raise SecurityError, msg if !auth2 and !@fail_silent
      auth3, msg = @owner.check_privileges("OpDelete", mobj)
      raise SecurityError, msg if !auth3 and !@fail_silent
      super if auth2 and auth3
    end

    def values
      super.select do |v|
        auth2, msg2 = @owner.check_privileges("OpRead", v)
        auth2
      end
    end

  end

  module SecureSetMixin
    include SecureManyMixin

    def __value
      super.select do |k,v|
        auth2, msg2 = @owner.check_privileges("OpRead", v)
        auth2
      end
    end

  end

  module SecureListMixin
    include SecureManyMixin

    def __value
      super.select do |v|
        auth2, msg2 = @owner.check_privileges("OpRead", v)
        auth2
      end
    end

  end

  def Make_Schema(args=nil)
    res = super
    res.extend SecureFactoryMixin
    res.security = args[:rules]
    res.fail_silent = args[:fail_silent]
    res.interp.compose!(CheckPrivileges)
    res
  end

  def Make_Class(args=nil)
    res = super
    auth, msg = args[:factory].check_privileges("OpCreate", res)
    if !auth
      raise SecurityError, msg unless args[:factory].fail_silent
      nil
    else
      res.extend SecureMObjectMixin
      res
    end
  end

  def Make_Field(computed, many, type, args=nil)
    res = super
    if !many
      res.extend SecureSingleMixin
    elsif res.is_a? ManagedData::Set
      res.extend SecureSetMixin
    elsif res.is_a? ManagedData::List
      res.extend SecureListMixin
    end
    res
  end

end


