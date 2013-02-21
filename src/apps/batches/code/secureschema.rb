=begin

Transform a schema into a secure schema by adding extra write permission fields

=end

require 'apps/security/code/security'
require 'apps/security/code/bind'

class SecureSchema

  def self.write_prefix
    "_write_"
  end

  def self.secure_transform!(schema)
    factory = schema.factory
    schema.classes.each do |c|
      field_list = c.fields.clone()
      field_list.each do |f|
        cf = factory.Field()
        cf.name = write_prefix+f.name
        cf.type = schema.primitives["bool"]
        cf.optional = true
        cf.many = false
        cf.key = false
        cf.traversal = false
        c.defined_fields << cf
      end
      Print.print(c)
    end
    schema.finalize()
    schema
  end

end
