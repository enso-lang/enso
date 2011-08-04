include Java

$CLASSPATH<<'../../batches/jaba/target/test-classes'

require "../../batches/runtime/target/runtime-1.0-SNAPSHOT.jar"
require "../../batches/libs/mysql-connector-java-5.1.10.jar"

include_class Java::batch.sql.schema.ISchema

require 'core/batches/code/java_impl/entitytype'

class Schema_Enso
  include ISchema

  #@schema : CheckedObject

  def initialize(root_klass)
    @root_klass = root_klass
  end

  #public IEntityType getEntity(String name);
  def getEntity(name)
    return EntityType_Enso.new(@root_klass.fields[name].type)
  end

end
