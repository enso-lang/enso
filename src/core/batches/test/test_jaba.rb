include Java

$CLASSPATH<<'../../batches/jaba/target/test-classes'

require 'test/unit'

require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/code/layout'
require 'core/diff/code/delta'
require 'core/diff/code/diff'
require 'core/schema/code/factory'
require 'core/batches/code/query2batch'
require 'core/batches/code/java_impl/schema'

require "../../batches/runtime/target/runtime-1.0-SNAPSHOT.jar"
require "../../batches/libs/mysql-connector-java-5.1.10.jar"

module Jaba
include_class Java::batch.Op
include_class Java::batch.util.Forest
include_class Java::batch.sql.syntax.Factory
include_class Java::batch.sql.JDBC
include_class Java::tests.sql.northwind.schema.Northwind
include_class Java::batch.sql.schema.javareflect.Schema
end

java_import Java::tests.sql.northwind.schema.Northwind

class BatchTest < Test::Unit::TestCase

  # test setup
  def setup
    @schema = Loader.load("northwind.dbschema")
    @qfact = Factory.new(Loader.load("batch.schema"))
  end

  def test_jaba
    q = @qfact.Query("Customers")
    q.fields << @qfact.Field("CompanyName")
    query_test = Query2Batch.query2batch(q)

    f = Jaba::Factory.factory
    query_jaba = f.Loop(Jaba::Op::SEQ, "root", f.Prop(f.Root(), "Customers"), f.Out("root_CompanyName", f.Prop(f.Var("root"), "CompanyName")))

    #1. assert that query_test == query_jaba
    assert(query_test.toString() == query_jaba.toString())

    #2. assert that the results from evaluating query_test and query_jaba are equal
    String cstr = "jdbc:mysql://localhost/Northwind?user=root&password="
    connection_j = Jaba::JDBC.new(Jaba::Schema.new(Northwind), cstr)
    connection_t = Jaba::JDBC.new(Schema_Enso.new(@schema.classes['Northwind']), cstr)
    result_j = connection_j.execute(query_jaba, Jaba::Forest.new())
    result_t = connection_t.execute(query_test, Jaba::Forest.new())
    list_j = []
    result_j.getIteration("root").each do |x|
      list_j << "name=#{x.getString("CompanyName")}"
    end
    list_t = []
    result_t.getIteration("root").each do |x|
      list_t << "name=#{x.getString("CompanyName")}"
    end
    assert (list_j == list_t)

    #3. create a CheckedObject


  end

end