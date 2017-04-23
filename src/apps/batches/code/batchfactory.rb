=begin

Note that unlike SecureFacotry, BatchFactory has nothing to do with the original factory class

=end

include Java

require 'rubygems'
require 'jdbc/mysql'
include_class "com.mysql.jdbc.Driver"

$CLASSPATH<<'lib/runtime-1.0-SNAPSHOT.jar'

require 'core/system/load/load'
require 'apps/web/code/web'
require 'apps/web/code/handlers'
require 'apps/web/code/module'
require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/render/layout'
require 'core/schema/code/factory'
require 'apps/batches/code/query2batch'
require 'apps/batches/code/result2object'
require 'apps/batches/code/java_impl/schema'
require 'apps/batches/code/securebatch'
require 'apps/batches/code/secureschema'
require 'core/security/code/security'
require 'core/security/code/nullsecurity'

require "lib/runtime-1.0-SNAPSHOT.jar"
require "lib/mysql-connector-java-5.1.10.jar"

module Jaba
include_class Java::batch.Op
include_class Java::batch.util.Forest
include_class Java::batch.sql.syntax.Factory
include_class Java::batch.sql.JDBC
include_class Java::batch.sql.schema.javareflect.Schema
end


class BatchFactory

  def initialize(web, schema, auth = NullSecurity.new, db, dbuser, password)
    if auth == ""
      @auth = NullSecurity.new()
    else
      @auth = Security.new(auth)
    end
    @all_queries = BatchEval.batch(web, schema.root_class)
    @schema = schema
    @factory = Factory::new(schema)
    #init db here
    @database = db
    @dbuser = dbuser
    @password = password
    @jaba_addr = "jdbc:#{@database}?user=#{@dbuser}&password=#{@password}"
    @connection_t = Jaba::JDBC.new(Schema_Enso.new(@schema.root_class), @jaba_addr)

    @address = "jdbc:#{@database}"
    @jdbc_conn = java.sql.DriverManager.getConnection(@address, @dbuser, @password)
  end

  #return a checked object corresponding to the root of the query
  def query(query_name, user = nil)
    query = @all_queries[query_name]
    @auth.user = user
    secure_query = SecureBatch.secure_transform!(Copy(query.factory, query), @auth)
    root = @factory[@schema.root_class.name]
    secure_query.fields.each do |f|
      q = f.query
      next if q.nil?
      bq = Query2Batch.query2batch(q, @schema)
      puts "Batch query is #{bq.toString}"
      result_t = @connection_t.execute(bq, Jaba::Forest.new())
      if result_t.nil?
        crash with terminate force
      end
      obj = Result2Object.result2object(result_t, q, @schema)
      CopyInto(@factory, obj, root)
    end
    root
  end

  def update(table, key, field_name, value, user = nil)

    #privilege = obj[SecureSchema.write_prefix+field_name]
    #if !privilege
    #  return false
    #end

    klass = @schema.classes.find_first {|t| t.table==table}
    keyfield = klass.key
    keycol = keyfield.column || keyfield.name
    #check if this is a relationship or an attribute.
    puts "setting key #{key} in table #{table} to value #{value}"
    if klass.fields[field_name].type.Primitive?
      # attribute - simple update
      puts "as an attribute"
      query = "update #{table} set #{field_name}=#{value.inspect} where #{keycol}=#{key.inspect}"
    else #TODO!
      # relationship - simple update on foreign key
      puts "as a relation"
    end
    puts query
    jdbc_exec(query)
    true
  end

  def create(path, value)
    privilege = @auth.check_privileges("OpCreate", obj, field)
    if !privilege
      return false
    end
    jdbc_exec(query)
    true
  end

  private

  def jdbc_exec(query)
    @jdbc_conn.createStatement.execute(query)
  end

  def jdbc_query(query)
    @jdbc_conn.createStatement.executeQuery(query)
  end

end
