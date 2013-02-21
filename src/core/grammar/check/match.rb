

class MatchSchema

  def initialize(from, to)
    # from might have anonymous classes
    @from = from
    @to = to
  end

  # TODO: reuse from extract.
  def anon?(c)
    c.name =~ /^C_[0-9]+$/
  end

  def match
    eq = {}
    @from.types.each do |t1|
      @to.types.each do |t2|
        if t1.name == t2.name
          eq[t1] = t2
        end
      end
    end
    in_from = @from.types.select do |t1|
      !eq.has_key?(t1)
    end
    in_to = @to.types.select do |t2|
      !eq.has_value?(t2)
    end
    puts "In from: "
    p in_from
    puts "In to: "
    p in_to

    anons = in_from.select do |name, x|
      anon?(name)
    end
    puts "ANONS:"
    puts anons.inspect

    all_in_to = eq.values + in_to.values
    p all_in_to
    all_in_to.repeated_permutation(anons.length) do |comb|
      puts "COMB: #{comb}"
    end
  end

end
