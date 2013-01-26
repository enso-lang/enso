def fact(n)
  if n == 0 then
    1
  else
    n * fact(n-1)
  end
end

class Person
  def initialize(fname, lname)
   @fname = fname
   @lname = lname
  end
  def to_s
     "Person: #@fname #@lname"
  end
end

if __FILE__ == $0 then
  person = Person.new("Augustus","Bondi")
  puts person
end
