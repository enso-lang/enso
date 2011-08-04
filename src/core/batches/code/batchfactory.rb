=begin

Note that unlike SecureFacotry, BatchFactory has nothing to do with the original factory class

=end

include Java

require 'rubygems'
require 'jdbc/mysql'
include_class "com.mysql.jdbc.Driver"

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

  def initialize(web, schema, db, user, password)
    @all_queries = BatchEval.batch(web, schema.root_class)
    @schema = schema
    @factory = Factory.new(schema)
    #init db here
    @database = db
    @user = user
    @password = password
    @jaba_addr = "jdbc:#{@database}?user=#{@user}&password=#{@password}"
    @connection_t = Jaba::JDBC.new(Schema_Enso.new(@schema.root_class), @jaba_addr)

    @address = "jdbc:#{@database}"
    @jdbc_conn = java.sql.DriverManager.getConnection(@address, @user, @password)

  end

  #return a checked object corresponding to the root of the query
  def query(query_name)
    query = @all_queries[query_name]
    root = @factory[@schema.root_class.name]
    query.fields.each do |f|
      q = f.query
      next if q.nil?
      bq = Query2Batch.query2batch(q, @schema)
      result_t = @connection_t.execute(bq, Jaba::Forest.new())
      obj = Result2Object.result2object(result_t, q, @schema)
      CopyInto(@factory, obj, root)
    end
    root
  end

  def update(obj, field, value)
    klass = obj.schema_class
    table = klass.table
    puts "klass = #{klass.name}"
    keyfield = ClassKey(klass).name
    puts "keyfield = #{keyfield}"
    puts "value = #{value}"
    key = obj[keyfield]
    puts "key = #{key.inspect}"
    #check if this is a relationship or an attribute.
    puts "setting key #{key} in table #{table} to value #{value}"
    if klass.fields[field].type.Primitive?
      # attribute - simple update
      puts "as an attribute"
      query = "update #{table} set #{field}=#{value} where #{keyfield}=#{key.inspect}"
    else
      # relationship - simple update on foreign key
      puts "as a relation"
    end
    puts query
    jdbc_exec(query)
  end

  def create(path, value)
    jdbc_exec(query)
  end

  private

  def jdbc_exec(query)
    @jdbc_conn.createStatement.execute(query)
  end

  def jdbc_query(query)
    @jdbc_conn.createStatement.executeQuery(query)
  end

end
