include Java

$CLASSPATH<<'lib/runtime-1.0-SNAPSHOT.jar'

require "lib/runtime-1.0-SNAPSHOT.jar"
require "lib/mysql-connector-java-5.1.10.jar"

include_class Java::batch.sql.schema.IAlias

class Alias_Enso
  include IAlias

  #public abstract Fun getExpr();
  def getExpr()
    return nil
  end

end
