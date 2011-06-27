include Java

$CLASSPATH<<'../../batches/jaba/target/test-classes'

require "../../batches/runtime/target/runtime-1.0-SNAPSHOT.jar"
require "../../batches/libs/mysql-connector-java-5.1.10.jar"

include_class Java::batch.sql.schema.IAttribute

class Attribute_Enso < Member_Enso
  include IAttribute

  #@field : CheckedObject

  def initialize(field)
    @field = field
    super(field)
  end

  #public DataType getType();
  def getType()
    @field.type
  end

  #public boolean isKey();
  def isKey()
    return @field.key
  end

end
