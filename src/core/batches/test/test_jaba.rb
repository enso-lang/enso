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
require 'core/batches/code/result2object'
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

class JabaTest < Test::Unit::TestCase

  # test setup
  def setup
    @schema = Loader.load("northwind.dbschema")
    @qfact = Factory.new(Loader.load("batch.schema"))
  end

  def test_query2batch
    q = @qfact.Query("Customer")
    q.fields << @qfact.Field("CompanyName")
    query_test = Query2Batch.query2batch(q, @schema)

    f = Jaba::Factory.factory
    query_jaba = f.Loop(Jaba::Op::SEQ, "Customer", f.Prop(f.Root(), "Customers"),
                        f.Prim(Jaba::Op::SEQ,
                            [f.Out("CompanyName", f.Prop(f.Var("Customer"), "CompanyName")),
                             f.Out("CustomerID", f.Prop(f.Var("Customer"), "CustomerID"))]))

    #1. assert that query_test == query_jaba
    assert(query_test.toString() == query_jaba.toString())

    #2. assert that the results from evaluating query_test and query_jaba are equal
    String cstr = "jdbc:mysql://localhost/Northwind?user=root&password="
    connection_j = Jaba::JDBC.new(Jaba::Schema.new(Northwind), cstr)
    connection_t = Jaba::JDBC.new(Schema_Enso.new(@schema.classes['Northwind']), cstr)
    result_j = connection_j.execute(query_jaba, Jaba::Forest.new())
    result_t = connection_t.execute(query_test, Jaba::Forest.new())
    list_j = []
    result_j.getIteration("Customer").each do |x|
      list_j << "name=#{x.getString("CompanyName")}"
    end
    list_t = []
    result_t.getIteration("Customer").each do |x|
      list_t << "name=#{x.getString("CompanyName")}"
    end
    assert (list_j == list_t)

  end

  def test_result2object
    q = @qfact.Query("Supplier")
    q.fields << @qfact.Field("CompanyName")
    f2 = @qfact.Field("Products")
    f2.query = @qfact.Query("Product")
    f2.query.fields << @qfact.Field("ProductName")
    q.fields << f2
    query_test = Query2Batch.query2batch(q, @schema)

    #2. assert that the results from evaluating query_test and query_jaba are equal
    String cstr = "jdbc:mysql://localhost/Northwind?user=root&password="
    connection_t = Jaba::JDBC.new(Schema_Enso.new(@schema.root_class), cstr)
    result_t = connection_t.execute(query_test, Jaba::Forest.new())

    root_obj = Result2Object.result2object(result_t, q, @schema)
    assert(root_obj.Suppliers.length == 29)
    assert(root_obj.Suppliers[3].CompanyName == "Grandma Kelly's Homestead")
    assert(root_obj.Suppliers[3].Products.length == 3)
    assert(root_obj.Suppliers[27].Products[58].ProductName == "Escargots de Bourgogne")
  end

end