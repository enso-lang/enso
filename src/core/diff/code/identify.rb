

require 'core/system/library/schema'

class Identify

  # TODO: subtype check etc.

  def initialize
    @created = []
    @deleted = {}
    @mapped = {}
  end


  def levenshtein(s, t) 
    #for all i and j, d[i,j] will hold the Levenshtein distance between
    #the first i characters of s and the first j characters of t;
    #note that d has (m+1)x(n+1) values
    d = {}

    m = s.length
    n = t.length

    0.upto(m) do |i|
      d[i] ||= {}
      d[i][0] = i
    end
    
    0.upto(n) do |j|
      d[0] ||= {}
      d[0][j] = j
    end

    1.upto(m) do |i|
      1.upto(n) do |j|
        if shallow_equal?(s[i - 1], t[j - 1]) then
          d[i][j] = d[i-1][j-1]
        else
          d[i][j] = min(d[i - 1][j] + 1,  # delete
                        d[i][j - 1] + 1, # insert
                        d[i - 1][j - 1] + 1) # replace
        end
      end
    end
    
    return d[m][n]
  end
  
  # TODO: propagate paths along the spine
  # and track mappings, so that cross-link
  # fixing can use them

  def edits(o1, o2)
    diff(o1, o2)
    fixup(o1, o2)
  end

  def diff(o1, o2, path = '')
    return if o1.nil? && o2.nil?

    if o1.nil? then
      # TODO: recreate the whole spine below o2
      # the crosslinks  in this subtree must be
      # fixed somehow... using the reverse of mapped?
      # (only if they are outside of the recreated spine???)
      puts "create #{o2}"
      # Use path in key of created?
      @created << o2
      return
    end
    
    if o2.nil? then
      puts "delete #{path}"
      @deleted[o1] = true
      return
    end

    the_class = nil
    if Schema::subclass?(o1.schema_class, o2.schema_class) &&
        o1.schema_class.name != o2.schema_class.name then
      puts "1: replace #{path} with #{o2}"
      @mapped[o1] = o2
      the_class = o2.schema_class
    elsif Schema::subclass?(o2.schema_class, o1.schema_class) &&
        o1.schema_class.name != o2.schema_class.name then
      @mapped[o1] = o2
      the_class = o1.schema_class
      puts "2: replace #{path} with #{o2}"
    elsif o1.schema_class.name == o2.schema_class.name then
      @mapped[o1] = o2
      the_class = o1.schema_class
    elsif Schema::class_minimum((o1.schema_class, o2.schema_class) then
      the_class = Schema::class_minimum((o1.schema_class, o2.schema_class) 
      @mapped[o1] = o2
      puts "3: replace #{path} with #{o2}"
    else
      raise "Incomparable: #{o1} and #{o2}"
    end

    the_class.fields.each do |f|
      if f.type.Primitive? # optionality???
        if o1[f.name] != o2[f.name] then
          puts "set #{path}.#{f.name} to #{o2[f.name]}"
        end
      end
    end

    # TODO: this does not support insertions in a list
    # only in-place updating, appending and removing.
    # Check whether not one list is sublist of the other
    # or vice versa, and then update the whole list.
    the_class.fields.each do |f|
      if !f.type.Primitive? && f.traversal && f.many && !Schema::is_keyed?(f.type) then
        i = 0
        while i < o1[f.name].length do
          break if i >= o2[f.name].length
          diff(o1[f.name][i], o2[f.name][i], path + ".#{f.name}[#{i}]")
          i += 1
        end
        while i < o1[f.name].length do 
          puts "remove #{path}.#{f.name}[#{i}]"
          i += 1
        end
        while i < o2[f.name].length do
          puts "insert  #{o2[f.name][i]} at #{i} in #{path}.#{f.name}[#{i}]"
          i += 1
        end
      end
    end
    
    the_class.fields.each do |f|
      if !f.type.Primitive? && f.traversal && f.many && Schema::is_keyed?(f.type) then
        key = Schema::class_key(f.type).name
        o1[f.name].each do |x1|
          x2 = o2[f.name].find { |x| x[key] == x1[key] }
          if x2 then
            diff(x1, x2, path + ".#{f.name}[#{x1[key]}]")
          else
            puts "remove #{path}.#{f.name}[#{x1[key]}]"
          end
        end
        o2[f.name].each do |x2|
          x1 = o1[f.name].find { |x| x[key] == x2[key] }
          if !x1 then
            puts "insert #{x2} at #{path}.#{f.name}[#{x2[key]}]"
          end
        end
      end
    end

    the_class.fields.each do |f|
      if !f.type.Primitive? && f.traversal && !f.many then
        diff(o1[f.name], o2[f.name], path + ".#{f.name}")
      end
    end
    
  end


  def fixup(o1, o2, path = '')
    return if o1.nil? || o2.nil?

    the_class = nil
    if Schema::subclass?(o1.schema_class, o2.schema_class) &&
        o1.schema_class.name != o2.schema_class.name then
      the_class = o2.schema_class
    elsif Schema::subclass?(o2.schema_class, o1.schema_class) &&
        o1.schema_class.name != o2.schema_class.name then
      the_class = o1.schema_class
    elsif o1.schema_class.name == o2.schema_class.name then
      the_class = o1.schema_class
    elsif Schema::class_minimum((o1.schema_class, o2.schema_class) then
      the_class = Schema::class_minimum((o1.schema_class, o2.schema_class) 
    else
      raise "Incomparable: #{o1} and #{o2}"
    end

    # single non-traversal links
    the_class.fields.each do |f|
      if !f.type.Primitive? && !f.traversal && !f.many then
        if !o1[f.name] && !o2[f.name] then
          # do nothing
        elsif o1[f.name] && !o2[f.name] then
          puts "1 ^set #{o1}.#{f.name} to nil"
        elsif !o1[f.name] && o2[f.name] then
          puts "2 ^set #{o1}.#{f.name} to #{o2[f.name]}"
        elsif !@mapped[o1[f.name]] then
          puts "3 ^set #{o1}.#{f.name} to #{o2[f.name]}"
        elsif @mapped[o1[f.name]] == o2[f.name] then
          # do nothing          
        else
          #path = o2[f.name].path # ???
          puts "4 ^set #{o1}.#{f.name} to #{o2[f.name]}}"
        end
      end
    end

    the_class.fields.each do |f|
      if !f.type.Primitive? && !f.traversal && f.many && Schema::is_keyed?(f.type) then
        key = Schema::class_key(f.type).name
        o1[f.name].each do |x1|
          x2 = o2[f.name].find { |x| x[key] == x1[key] }
          if x2 && !@mapped[x1] then
            # nothing
          elsif x2 && @mapped[x1] && @mapped[x1] == x2 then
            # nothing
          elsif x2 && @mapped[x1] && @mapped[x1] != x2 then
            puts "^ replace #{x1} at #{x1[key]} with #{x2}"
          elsif !x2 then
            puts "^ remove #{x1} at #{x1[key]} from #{o1}.#{f.name}"
          end
        end
        o2[f.name].each do |x2|
          x1 = o1[f.name].find { |x| x[key] == x2[key] }
          if !x1 then
            puts "^ insert #{x2} at #{x2[key]} to #{o1}.#{f.name}"
          end
        end
      end
    end


    # many non-spine, non-keyed collections
    the_class.fields.each do |f|
      if !f.type.Primitive? && !f.traversal && f.many && !Schema::is_keyed?(f.type) then
        i = 0
        while i < o1[f.name].length do
          break if i >= o2[f.name].length
          x1 = o1[f.name][i]
          x2 = o2[f.name][i]
          if !@mapped[x1] then
            #nothing
          elsif @mapped[x1] && @mapped[x1] == x2 then
            # nothing
          elsif @mapped[x1] && @mapped[x1] != x2 then
            puts "^ replace #{x1} at #{i} with #{x2}"
          end
            
          # puts "insert #{o2[f.name][i]} at #{i} in #{o2}.#{f.name}"
          i += 1
        end

        while i < o1[f.name].length do 
          puts "^ remove #{path}.#{f.name}[#{i}]"
          i += 1
        end
        while i < o2[f.name].length do
          # WRONG: need path of the o2 thing
          puts "^ add #{path}.#{f.name}[#{i}] to #{o1}.#{f.name}"
          i += 1
        end
      end
    end

    # Traverse down the spine to fixup children
    the_class.fields.each do |f|
      if !f.type.Primitive? && f.traversal && !f.many then
        fixup(o1[f.name], o2[f.name], path + ".#{f.name}")
      end
    end

    the_class.fields.each do |f|
      if !f.type.Primitive? && f.traversal && f.many && Schema::is_keyed?(f.type) then
        key = Schema::class_key(f.type).name
        o1[f.name].each do |x1|
          x2 = o2[f.name].find { |x| x[key] == x1[key] }
          if x2 then
            fixup(x1, x2, path + ".#{f.name}[#{x1[key]}]")
          end
        end
        o2[f.name].each do |x2|
          x1 = o1[f.name].find { |x| x[key] == x2[key] }
          if x1 then
            fixup(x1, x2, path + ".#{f.name}[#{x1[key]}]")
          end
        end
      end
    end


    the_class.fields.each do |f|
      if !f.type.Primitive? && f.traversal && f.many && !Schema::is_keyed?(f.type) then
        i = 0
        while i < o1[f.name].length do
          break if i >= o2[f.name].length
          fixup(o1[f.name][i], o2[f.name][i], path + ".#{f.name}[#{i}]")
          i += 1
        end
      end
    end

  end

  



end
  

require 'core/system/load/load'
ss1 = Load::load('schema.schema')
ss2 = Load::load('schema2.schema')

Identify.new.edits(ss1, ss2)

gg1 = Load::load('grammar.grammar')
gg2 = Load::load('grammar2.grammar')

Identify.new.edits(gg1, gg2)

gg1 = Load::load('grammar.grammar')
gg2 = Load::load('web.grammar')

Identify.new.edits(gg1, gg2)

gg1 = Load::load('attr-schema.schema')
gg2 = Load::load('schema.schema')

Identify.new.edits(gg1, gg2)
Identify.new.edits(gg2, gg1)

