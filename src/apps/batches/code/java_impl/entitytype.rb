include Java

$CLASSPATH<<'lib/runtime-1.0-SNAPSHOT.jar'

require "lib/runtime-1.0-SNAPSHOT.jar"
require "lib/mysql-connector-java-5.1.10.jar"

include_class Java::batch.sql.schema.IEntityType

require 'apps/batches/code/java_impl/attribute'
require 'apps/batches/code/java_impl/relationship'
require 'apps/batches/code/java_impl/member'

class EntityType_Enso
  include IEntityType

  #@klass : CheckedObject

  def initialize(klass)
    @klass = klass
  end

  #public String getTableName();
  def getTableName()
    return @klass.table
  end

  #public IMember get(String name);
  def get(name)
    return Member_Enso.make(@klass.fields[name])
  end

  #public IRelationship getRelationship(String name);
  def getRelationship(name)
    return Relationship_Enso.new(@klass.fields[name])
  end

  #public IAttribute getKey();
  def getKey()
    key = @klass.fields.find {|f| f.key}
    return key ? Attribute_Enso.new(key) : nil
  end

  def toString()
		"Entity-#{@klass.name} #{@klass.inspect}"
  end

  alias :inspect :toString
  alias :to_s :toString

end
