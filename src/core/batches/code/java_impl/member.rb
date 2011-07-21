include Java

$CLASSPATH<<'../../batches/jaba/target/test-classes'

require "../../batches/runtime/target/runtime-1.0-SNAPSHOT.jar"
require "../../batches/libs/mysql-connector-java-5.1.10.jar"

include_class Java::batch.sql.schema.IMember

require 'core/batches/code/java_impl/attribute'

class Member_Enso
  include IMember

  #@field : CheckedObject

  def initialize(field)
    raise "Tried to create a member with nil" if field.nil?
    @field = field
  end

  #public String getName();
  def getName()
    return @field.name
  end

	#public String columnName();
  def columnName()
    return !@field.column.nil? ? @field.column : @field.name
  end

  def self.make(field)
    if field.type.Primitive?
      Attribute_Enso.new(field)
    else
      Relationship_Enso.new(field)
    end
  end
end
