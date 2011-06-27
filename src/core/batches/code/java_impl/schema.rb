include Java

$CLASSPATH<<'../../batches/jaba/target/test-classes'

require "../../batches/runtime/target/runtime-1.0-SNAPSHOT.jar"
require "../../batches/libs/mysql-connector-java-5.1.10.jar"

include_class Java::batch.sql.schema.ISchema

class Schema_Enso
  include ISchema

  #@schema : CheckedObject

  def initialize(schema)
    @schema = schema
  end

  #public IEntityType getEntity(String name);
  def getEntity(name)
    return @schema.klasses['name']
  end

end
