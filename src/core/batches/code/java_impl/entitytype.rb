include Java

$CLASSPATH<<'../../batches/jaba/target/test-classes'

require "../../batches/runtime/target/runtime-1.0-SNAPSHOT.jar"
require "../../batches/libs/mysql-connector-java-5.1.10.jar"

include_class Java::batch.sql.schema.IEntityType

class EntityType_Enso
  include IEntityType

  #@klass : CheckedObject

  def initialize(klass)
    @klass = klass
  end

  #public String getTableName();
  def getTableName()
    return @klass.name
  end

  #public IMember get(String name);
  def get(name)
    return Attribute_Enso.new(@klass.fields[name])
  end

  #public IRelationship getRelationship(String name);
  def getRelationship(name)
    return Relationship_Enso.new(@klass.fields[name])
  end

  #public IAttribute getKey();
  def getKey()
    return Attribute_Enso.new(@klass.fields.find {|f| f.key})
  end

end
