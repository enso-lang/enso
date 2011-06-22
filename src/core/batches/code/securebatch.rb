=begin

Transform a batch script query into a secure version with the help of a security object

=end

require 'core/security/code/security'
require 'core/security/code/bind'

class SecureBatch

  include ExprBind

  def self.secure_transform!(query, securityobj)
    SecureBatch.new.secure_transform!(query, securityobj)
  end

  def secure_transform!(query, securityobj)
    queryfact = query.factory
    classname = query.classname

    #figure out the predicate expressions by asking securityobj:

    # Read Permissions
    #-----------------
    #what do i need to read this class?
    read_obj = Copy(queryfact,securityobj.get_allow_constraints("OpRead", classname))
    #what do i need to read these fields?
    read_fields = query.fields.reduce(nil) do |conj, f|
      exp = Copy(queryfact,securityobj.get_allow_constraints("OpRead", classname, f.name))
      conj.nil? ? exp : queryfact.EBinOp('and', conj, exp)
    end
    read_constraint = queryfact.EBinOp('and', read_obj, read_fields)
    query.filter = bind!(query.filter.nil? ? read_constraint : queryfact.EBinOp('and', query.filter, read_constraint))

    # Write Permissions
    #------------------
    #what do i need to update these fields?
    update_fields = query.fields.reduce(nil) do |conj, f|
      exp = Copy(queryfact,securityobj.get_allow_constraints("OpUpdate", classname, f.name))
      conj.nil? ? exp : queryfact.EBinOp('and', conj, exp)
    end

    query.fields.each do |f|
      secure_transform!(f.query, securityobj) unless f.query.nil?
    end

    return query
  end

end
