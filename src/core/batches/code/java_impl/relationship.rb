include Java

$CLASSPATH<<'../../batches/jaba/target/test-classes'

require "../../batches/runtime/target/runtime-1.0-SNAPSHOT.jar"
require "../../batches/libs/mysql-connector-java-5.1.10.jar"

include_class Java::batch.sql.schema.IRelationship

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
