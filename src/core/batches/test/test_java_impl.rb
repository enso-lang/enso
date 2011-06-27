include Java

$CLASSPATH<<'../../batches/jaba/target/test-classes'

require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/code/layout'
require 'core/diff/code/delta'
require 'core/diff/code/diff'
require 'core/schema/code/factory'

require "../../batches/runtime/target/runtime-1.0-SNAPSHOT.jar"
require "../../batches/libs/mysql-connector-java-5.1.10.jar"
java_import Java::tests.sql.northwind.schema.Northwind

include_class Java::batch.Op
include_class Java::batch.util.Forest
include_class Java::batch.sql.syntax.Factory
include_class Java::batch.sql.JDBC
include_class Java::tests.sql.northwind.schema.Northwind
include_class Java::batch.sql.schema.javareflect.Schema


schema = Loader.load("northwind.schema")

f = Factory.factory

q = f.Loop(Op::SEQ, "x", f.Prop(f.Root(), "Customers"), f.Out("A", f.Prop(f.Var("x"), "CompanyName")))

String cstr = "jdbc:mysql://localhost/Northwind?user=root&password="
#connection = JDBC.new(Schema.new(Northwind), cstr)
connection = JDBC.new(schema, cstr)

puts connection.setupQueries(q).toString()
result = connection.execute(q, Forest.new())

result.getIteration("x").each do |x|
  puts "name=#{x.getString("A")}"
end
