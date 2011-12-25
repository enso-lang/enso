require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/code/layout'

module Render

  def Render(obj, *args)
    send("Render_"+obj.schema_class.name, obj, *args)
  end

  def Render_School(obj)
    puts "Earnings reports for Podunk High School"
    puts "---------------------------------------"
    obj.courses.each {|c|Render(c)}
  end

  def Render_Course(obj)
    puts "\nCourse: #{obj.cname}"
    obj.students.each {|s|Render(s)}
    puts "Cost to run = $#{obj.duration*obj.cost}"
  end

  def Render_Student(obj)
    puts "  #{obj.sname} ($#{obj.fees})"
  end

end

class Eval
  include Render
end


myschool = Loader.load('test.school')
Eval.new.Render(myschool)
