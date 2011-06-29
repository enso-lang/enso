include Java

$CLASSPATH<<'../../batches/jaba/target/test-classes'

require "../../batches/runtime/target/runtime-1.0-SNAPSHOT.jar"
require "../../batches/libs/mysql-connector-java-5.1.10.jar"

include_class Java::batch.sql.schema.IAlias

class Alias_Enso
  include IAlias

  #public abstract Fun getExpr();
  def getExpr()
    return nil
  end

end
