include Java

$CLASSPATH<<'lib/runtime-1.0-SNAPSHOT.jar'

require "lib/runtime-1.0-SNAPSHOT.jar"
require "lib/mysql-connector-java-5.1.10.jar"

include_class Java::batch.sql.schema.IRelationship

require 'apps/batches/code/java_impl/entitytype'
require 'apps/batches/code/java_impl/member'

class Relationship_Enso < Member_Enso
  include IRelationship

  #@field : CheckedObject

  def initialize(field)
    @field = field
    super(field)
  end

  #public IMember getInverse();
  def getInverse()
    return @field.inverse ? Member_Enso.make(@field.inverse) : nil
  end

  #public boolean singleValued();
  def singleValued()
    return !@field.many
  end

  #public IEntityType toType();
  def toType()
    return EntityType_Enso.new(@field.type)
  end

end
