

module LayoutGrammar
  # assumes normalized, deformatted

  def self.layout(grammar)
    fact = grammar.graph_identity
    grammar.rules.each do |rule|
      rule.arg.alts.each do |alt|
        # assume alt is a seq because of normalization        
        n = alt.elements.size
        elts = []
        0.upto(n-1) do |i|
          elts << alt.elements[i]
          if i < n - 1 then
            elts << fact.Layout
          end
        end
        alt.elements.clear
        elts.each do |x|
          alt.elements << x
        end
      end
    end  
    
  end
end

