require 'core/system/load/load'
require 'core/schema/code/factory'
require 'csv'


f = Factory::new(Load::load("grades.schema"))

customers = CSV.read('demo/LiveSheet/test/grades.csv')

course = f["Course"]

# categories
# assignments
# points
# labels...
# number,name,id <blank> <grades...>


# read the assignments
label = nil
nass = 0
assignments = []
customers[1].each do |col|
  if col.nil?
  elsif label.nil?
    label = col
  else
    a = f["Assignment"]
    a.name = col
    a.increase_to_max = true
    course.assignments << a
    assignments[nass] = a
    nass = nass + 1
  end
end
# read the categories
ncol = 0
label = nil
customers[0].each do |col|
  if col.nil?
    # skip it
  elsif label.nil?
    label = col
  else
    cat = course.categories[col]
    if cat.nil?
      cat = f["Category"]
      cat.name = col
	    course.categories << cat
    end
    assignments[ncol].category = cat
    ncol = ncol + 1
  end
end
# read the points
ncol = 0
label = nil
customers[2].each do |col|
  if col.nil?
    # skip it
  elsif label.nil?
    label = col
  else
    assignments[ncol].points = col.to_f
    ncol = ncol + 1
  end
end
# read the curve
ncol = 0
label = nil
customers[3].each do |col|
  if col.nil?
    # skip it
  elsif label.nil?
    label = col
  else
    assignments[ncol].curve = col.to_f
    ncol = ncol + 1
  end
end
# read the number
label = nil
customers[4].each do |col|
	#puts "CAT '#{col}' #{col.nil?} "
  if col.nil?
    # skip it
    ncol = ncol + 1
  elsif label.nil?
    label = col
    ncol = 0
  else
    assignments[ncol].category.number = col.to_i
    #puts "#{ncol} #{assignments[ncol]} = #{assignments[ncol].category.number}"
    ncol = ncol + 1
  end
end
# read the percent
ncol = 0
label = nil
customers[5].each do |col|
  if col.nil?
    # skip it
  elsif label.nil?
    label = col
  else
    assignments[ncol].percent = col.to_f / 100
    ncol = ncol + 1
  end
end


customers.slice(7,1000).each do |row|
  student = f["Student"]
  student.number = row[0].to_i
  student.name = row[1]
  student.id = row[2]
  course.students << student
  
  ncol = 0
  row.slice(4,1000).each do |col|
    grade = f["Grade"]
    grade.grade = col.to_f
    grade.student = student
    grade.assignment = assignments[ncol]
    ncol = ncol + 1
  end
end

Cache.save_cache("cs345.grades", course)
#g = Load::load("grades.grammar")
#$stderr << "## Printing #{ARGV[0]}...\n"
#Layout::DisplayFormat.print(g, m, out, false)


#course.assignments.each do |a|
#  puts "CAT #{a.name}: #{a.maximum} avg=#{a.averageN} std=#{a.stdevN} med=#{a.medianN} max=#{a.maxGradeN} min=#{a.minGradeN} c=#{a.curve} #{a.target}"
#  puts "  #{a.averageC} #{a.stdevC} #{a.medianC} #{a.maxGradeC} #{a.minGradeC}"
#  puts "  perc=#{a.percent} num=#{a.category.number} cont=#{a.contribution}"
#end

course.students.each do |s|
 # s.grades.each do | g|
 #   puts "GRADE #{g.grade} -> GRADE #{g.normal} -> #{g.curved} -> #{g.combined}"
 # end
  puts "#{s.name}: #{s.finalGrade * 100}"
end

puts "CHECK #{course.check}"
