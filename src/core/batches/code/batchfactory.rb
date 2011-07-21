=begin

Note that unlike SecureFacotry, BatchFactory has nothing to do with the original factory class

=end

include Java

$CLASSPATH<<'../../batches/jaba/target/test-classes'

require 'core/system/load/load'
require 'core/web/code/web'
require 'core/web/code/handlers'
require 'core/web/code/module'
require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/code/layout'
require 'core/schema/code/factory'
require 'core/batches/code/query2batch'
require 'core/batches/code/result2object'
require 'core/batches/code/java_impl/schema'

require "../../batches/runtime/target/runtime-1.0-SNAPSHOT.jar"
require "../../batches/libs/mysql-connector-java-5.1.10.jar"

module Jaba
include_class Java::batch.Op
include_class Java::batch.util.Forest
include_class Java::batch.sql.syntax.Factory
include_class Java::batch.sql.JDBC
include_class Java::batch.sql.schema.javareflect.Schema
end


class BatchFactory

  def initialize(schema, query, db, user, password)
    @schema = schema
    @factory = Factory.new(schema)
    #init db here
    @database = db
    @user = user
    @password = password
    #pass query object to db and get back a resultset
    @query = query
    String cstr = "jdbc:#{@database}?user=#{@user}&password=#{@password}"
    connection_t = Jaba::JDBC.new(Schema_Enso.new(@schema.root_class), cstr)

    @root = @factory[@schema.root_class.name]
    query.fields.each do |f|
      q = f.query
      next if q.nil?
      bq = Query2Batch.query2batch(q, @schema)
      result_t = connection_t.execute(bq, Jaba::Forest.new())
      obj = Result2Object.result2object(result_t, q, @schema)
      CopyInto(@factory, obj, @root)
    end
  end

  #return a checked object corresponding to the root of the query
  def root()
    @root
  end

  #turn this resultset into a bunch of checked objects
  def populate_with_db(factory, resultset)
  end

end
