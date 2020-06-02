# -*- coding: iso-8859-1 -*-



#=begin

#---> We have two things
#  fields themselves can get repeated
#  and the argument of a field can be multiple
#  (and perhaps even both...).

#----------------------------------
#stats:Stats
#Stats ::= 
#       | Stat Stats
#Stat ::= [Stat] ...

#----------------------------------
#stats:Stat*
#Stat ::= [Stat] ...
#### path Stat*/Stat/[Stat]
#----------------------------------
#Stats
#Stats ::= 
#       | stats:Stat Stats
#Stat ::= [Stat] ...

#-----------------------------------
#Stats
#Stats ::= 
#       | stats:Stat Stats
#Stat ::= [Stat] ...
#       | "{" Stats "}"
#-----------------------------------
#Stats
#Stats ::= 
#       | stats:Stat Stats
#Stat ::= [Stat] ...
#       | "{" Stat* "}" //flattening
#-----------------------------------
#Stats
#Stats ::= 
#       | stats:Stat stats:Stat stats:Stat
#Stat ::= [Stat] ...
#-----------------------------------

#=end

module Multiplicity

#=begin

#Notes on the algebra

#A = {0, 1, +, *, ?}
#_*_ : A x A -> A
#_+_ : A x A -> A

#+/* are both commutative and associative

#_*_ is not idempotent on 1 and ?

#0 is the unit of _*_.

#1 is *not* the unit of _+_ because 0 + 1 != 0 (but ?)

#_*_ distributes over _+_: a * (b + c) = (a * b) + (a * c)

#A is a partially ordererd set (poset)

#a <= b =def (b == a + b)

#+/* are both monotone wrt the order <=

#The order can be drawn as follows (upside down):

# 0  1
# | /|
# |/ |
# ?  +
#  \/
#  *

#So we seem to have two bottoms: 1 and 0.

#A is not a lattice, because
# - absorption laws do not hold (e.g. a + (a * b) = a)
# - _*_ is not idempotent
# - _+_ has no unit

#It is, however, a semi-lattice for _+_:
# - assoc, comm, idemp 


#=end

  def test_alg_props
    test_comm_add
    test_assoc_add
    test_comm_mul
    test_assoc_mul
    test_absorption
    test_idempotent
    test_poset
    test_identities
    test_distributivity
    test_monotonicity
  end

  def test_comm_add
    puts "Testing commutativity of +"
    Alg.each do |e1|
      Alg.each do |e2|
        if e1 + e2 != e2 + e1 then
          puts "#{e1} + #{e2} != #{e2} + #{e1}"
          puts "\t#{e1} + #{e2} = #{e1 + e2}"
          puts "\t#{e2} + #{e1} = #{e2 + e1}"
        end
      end
    end
  end

  def test_assoc_add
    puts "Testing associativity of +"
    Alg.each do |e1|
      Alg.each do |e2|
        Alg.each do |e3|
          if e1 + (e2 + e3) != (e1 + e2) + e3 then
            puts "#{e1} + (#{e2} + #{e3}) != (#{e1} + #{e2}) + #{e3}"
            puts "\t#{e1} + (#{e2} + #{e3}) = #{e1 + (e2 + e3)}"
            puts "\t#(#{e1} + #{e2}) + #{e3} = #{(e1 + e2) + e3}"
          end
        end
      end
    end
  end

  def test_comm_mul
    puts "Testing commutativity of *"
    Alg.each do |e1|
      Alg.each do |e2|
        if e1 * e2 != e2 * e1 then
          puts "#{e1} * #{e2} != #{e2} * #{e1}"
          puts "\t#{e1} * #{e2} = #{e1 * e2}"
          puts "\t#{e2} * #{e1} = #{e2 * e1}"
        end
      end
    end
  end

  def test_assoc_mul
    puts "Testing associativity of *"
    Alg.each do |e1|
      Alg.each do |e2|
        Alg.each do |e3|
          if e1 * (e2 * e3) != (e1 * e2) * e3 then
            puts "#{e1} * (#{e2} * #{e3}) != (#{e1} * #{e2}) * #{e3}"
            puts "\t#{e1} * (#{e2} * #{e3}) = #{e1 * (e2 * e3)}"
            puts "\t#(#{e1} * #{e2}) * #{e3} = #{(e1 * e2) * e3}"
          end
        end
      end
    end
  end

  def test_absorption
    puts "Testing absorption laws"
    Alg.each do |e1|
      Alg.each do |e2|
        if e1 + (e1 * e2) != e1 then
          puts "#{e1} + (#{e1} * #{e2}) != #{e1}"
        end
        if e1 * (e1 + e2) != e1 then
          puts "#{e1} * (#{e1} + #{e2}) != #{e1}"
        end
      end
    end
  end

  def test_idempotent
    puts "Testing idempotent laws"
    Alg.each do |e|
      if e + e != e then
        puts "#{e} + #{e} != #{e}"
      end
      if e * e != e then
        puts "#{e} * #{e} != #{e}"
      end
    end
  end

  def test_poset
    puts "Testing poset requirements (refl, anti-symm, trans)"
    Alg.each do |elt1|
      if !(elt1 <= elt1) then
        puts "#{elt1} <= #{elt1} is false"
      end
      Alg.each do |elt2|
        if (elt1 <= elt2) && (elt2 <= elt1) then
          if elt1 != elt2 then
            puts "#{elt1} <= #{elt2} and #{elt2} <= #{elt1} but #{elt1} != #{elt2}"
          end
        end
      end
    end
    Alg.each do |elt1|
      Alg.each do |elt2|
        Alg.each do |elt3|
          if elt1 <= elt2 && elt2 <= elt3 then
            if !(elt1 <= elt3) then
              puts "#{elt1} <= #{elt2}, and #{elt2} <= #{elt3} but #{elt1} <= #{elt3}"
            end
          end
        end
      end
    end
  end

  def test_monotonicity
    puts "Testing monotonicity of +"
    Alg.each do |a1|
      Alg.each do |a2|
        Alg.each do |b1|
          Alg.each do |b2|
            if a1 <= a2 && b1 <= b2 then
              if !(a1 + b1 <= a2 + b2) then
                puts "#{a1} <= #{a2} and #{b1} <= #{b2}, but"
                puts "\t not #{a1} + #{b1} <= #{a2} + #{b2}"
              end
            end
          end
        end
      end
    end

    puts "Testing monotonicity of *"
    Alg.each do |a1|
      Alg.each do |a2|
        Alg.each do |b1|
          Alg.each do |b2|
            if a1 <= a2 && b1 <= b2 then
              if !(a1 * b1 <= a2 * b2) then
                puts "#{a1} <= #{a2} and #{b1} <= #{b2}, but"
                puts "\t not #{a1} * #{b1} <= #{a2} * #{b2}"
              end
            end
          end
        end
      end
    end

  end
    

  def test_identities
    puts "Testing identities #{ONE} id for +, #{ZERO} id for *"
    Alg.each do |e|
      if e + ONE != e then
        puts "#{e} + #{ONE} != #{e}"
      end
      if e * ZERO != e then
        puts "#{e} * #{ZERO} != #{e}"
      end
    end
    
    Alg.each do |unit|
      yes = true
      Alg.each do |e2|
        yes &&= ((unit + e2) == e2)
      end
      if yes then
        puts "Unit of +: #{unit}"
      end

      yes = true
      Alg.each do |e2|
        yes &&= ((unit * e2) == e2)
      end
      if yes then
        puts "Unit of *: #{unit}"
      end
    end
  end    

  def show_matrix
    puts "% table for meet (+)"
    puts "\\begin{tabular}{|c||c|c|c|c|c|}\\hline"
    print "$\\mid$ "
    Alg.each do |e|
      print "& $#{e}$ "
    end
    puts "\\\\\\hline\\hline"
    Alg.each do |e1|
      print "$#{e1}$ "
      Alg.each do |e2|
        print "& $#{e1 + e2}$ "
      end
      puts "\\\\\\hline"
    end
    puts "\\end{tabular}"
    puts

    puts "% table for join (*)"
    puts "\\begin{tabular}{|c||c|c|c|c|c|}\\hline"
    print "$\\cdot$ "
    Alg.each do |e|
      print "& $#{e}$ "
    end
    puts "\\\\\\hline\\hline"
    Alg.each do |e1|
      print "$#{e1}$ "
      Alg.each do |e2|
        print "& $#{e1 * e2}$ "
      end
      puts "\\\\\\hline"
    end
    puts "\\end{tabular}"

  end
    

  def show_table
    done = []
    puts "TABLE"
    Alg.each do |e1|
      Alg.each do |e2|
        next if done.include?([e2,e1])
        done << [e1, e2]
        puts "#{e1} + #{e2} = #{e1 + e2}"
      end
    end
    done = []
    Alg.each do |e1|
      Alg.each do |e2|
        next if done.include?([e2,e1])
        done << [e1, e2]
        puts "#{e1} * #{e2} = #{e1 * e2}"
      end
    end    
  end

  def test_distributivity
    puts "Testing distributivity"
    # SO: * does  distribute over +
    puts "\t a * (b + c) = (a * b) + (a * c)"
    Alg.each do |e1|
      Alg.each do |e2|
        Alg.each do |e3|
          x = e1 * (e2 + e3)
          y = (e1 * e2) + (e1 * e3)
          if x != y then
            puts "#{e1} * (#{e2} + #{e3}) = (#{e1} * #{e2}) + (#{e1} * #{e3})"
            puts "\t #{x} != #{y}"
          end
        end
      end
    end

    # SO: + does not distribute over *
    puts "\t a + (b * c) = (a + b) * (a + c)"
    Alg.each do |e1|
      Alg.each do |e2|
        Alg.each do |e3|
          x = e1 + (e2 * e3)
          y = (e1 + e2) * (e1 + e3)
          if x != y then
            puts "\t\t#{e1} + (#{e2} * #{e3})! = (#{e1} + #{e2}) * (#{e1} + #{e3})"
          end
        end
      end
    end
  end

  def todot(file)
    File.open(file, 'w') do |f|
      f.puts "digraph bla {"
      Alg.each do |e1|
        f.puts "n#{e1.objectidentity} [label=\"#{e1}\"]"
        Alg.each do |e2|
          if e1 <= e2 then
            f.puts "n#{e2.objectidentity} -> n#{e1.objectidentity} [dir=back]"
          end
        end
      end
      f.puts "}"
    end
  end

  def show_bottom
    puts "Finding bottom"
    Alg.each do |e1|
      yes = true
      Alg.each do |e2|
        yes &&= e1 <= e2
      end
      if yes
        puts "bottom: #{e1}"
      end
    end
  end

  def show_top
    puts "Finding top"
    Alg.each do |e1|
      yes = true
      Alg.each do |e2|
        yes &&= e2 <= e1
      end
      if yes
        puts "top: #{e1}"
      end
    end
    puts 
  end


  class Mult
    def zero; ZERO end
    def one; ONE end
    def one_or_more; ONE_OR_MORE end
    def zero_or_more; ZERO_OR_MORE end
    def zero_or_one; ZERO_OR_ONE end

#=begin
#if we define <= using * 
#poset requirements break:  not 1 <= 1, not ? <= ?
#(similar to idempotent laws not holding: 1 * 1 != 1, ? * ? != ?;
#this is the cause, of course)
#[it is, however, not a strict partial order, since irreflexivity
#does not hold for all elements.]
#=end
    def <=(b)
      #self * b == self
      b == self + b
    end
  end

  class Zero < Mult
    def +(m) m.add_zero; end
    def *(m) m.mul_zero; end

    def add_zero; zero end
    def mul_zero; zero end

    def add_one; zero_or_one end
    def mul_one; one end

    def add_one_or_more; zero_or_more end
    def mul_one_or_more; one_or_more end

    def add_zero_or_more; zero_or_more end
    def mul_zero_or_more; zero_or_more end

    def add_zero_or_one; zero_or_one end
    def mul_zero_or_one; zero_or_one end

    def star; self end
    def plus; self end
    def opt; self end

    def to_s; '0' end
  end

  class One < Mult
    def +(m) m.add_one; end
    def *(m) m.mul_one; end

    def add_zero; zero_or_one end
    def mul_zero; one end

    def add_one; one end
    def mul_one; one_or_more end

    def add_one_or_more; one_or_more end
    def mul_one_or_more; one_or_more end

    def add_zero_or_more; zero_or_more end
    def mul_zero_or_more; one_or_more end

    def add_zero_or_one; zero_or_one end
    def mul_zero_or_one; one_or_more end

    def opt; ZERO_OR_ONE end
    def star; ZERO_OR_MORE end
    def plus; ONE_OR_MORE end

    def to_s; '1' end
  end

  class OneOrMore < Mult
    def +(m) m.add_one_or_more; end
    def *(m) m.mul_one_or_more; end

    def add_zero; zero_or_more end
    def mul_zero; one_or_more end

    def add_one; one_or_more end
    def mul_one; one_or_more end

    def add_one_or_more; one_or_more end
    def mul_one_or_more; one_or_more end

    def add_zero_or_more; zero_or_more end
    def mul_zero_or_more; one_or_more end

    def add_zero_or_one; zero_or_more end
    def mul_zero_or_one; one_or_more end

    def opt; ZERO_OR_MORE end
    def star; ZERO_OR_MORE end
    def plus; ONE_OR_MORE end

    def to_s; '+' end
  end

  class ZeroOrMore < Mult
    def +(m) m.add_zero_or_more; end
    def *(m) m.mul_zero_or_more; end

    def add_zero; zero_or_more end
    def mul_zero; zero_or_more end

    def add_one; zero_or_more end
    def mul_one; one_or_more end

    def add_one_or_more; zero_or_more end
    def mul_one_or_more; one_or_more end

    def add_zero_or_more; zero_or_more end
    def mul_zero_or_more; zero_or_more end

    def add_zero_or_one; zero_or_more end
    def mul_zero_or_one; zero_or_more end

    def opt; self end
    def star; self end
    def plus; self end

    def to_s; '*' end
  end

  class ZeroOrOne < Mult
    def +(m) m.add_zero_or_one; end
    def *(m) m.mul_zero_or_one; end

    def add_zero; zero_or_one end
    def mul_zero; zero_or_one end

    def add_one; zero_or_one end
    def mul_one; one_or_more end

    def add_one_or_more; zero_or_more end
    def mul_one_or_more; one_or_more end

    def add_zero_or_more; zero_or_more end
    def mul_zero_or_more; zero_or_more end

    def add_zero_or_one; zero_or_one end
    def mul_zero_or_one; zero_or_more end

    def star; ZERO_OR_MORE end
    def plus; ZERO_OR_MORE end
    def opt; self end

    def to_s; '?' end
  end

  ZERO = Zero.new
  ONE = One.new
  ONE_OR_MORE = OneOrMore.new
  ZERO_OR_MORE = ZeroOrMore.new
  ZERO_OR_ONE = ZeroOrOne.new

  Alg = [ZERO, ONE, ZERO_OR_ONE, ZERO_OR_MORE, ONE_OR_MORE]

end


if __FILE__ == $0 then
  include Multiplicity
  test_alg_props
  show_table
  show_bottom
  show_top
  show_matrix
  todot('bla.dot')
end
