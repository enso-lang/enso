
require 'set'

def combine(tbl, unit)
  # Obtain the set of classes represented
  # by the set of Creates in the table.
  classes = tbl.keys.map do |cr|
    cr.name
  end.uniq

  # Union all fields referenced in tbl for
  # each class.
  fields = {}
  classes.each do |cl|
    fields[cl] ||= Set.new
    tbl.each do |cr, fs|
      if cr.name == cl then
        fields[cl] |= fs
      end
    end
  end

  result = {}
  classes.each do |cl|
    result[cl] ||= {}
    fields[cl].each do |f|
      tbl.each do |cr, fs|
        if cr.name == cl then
          if fs.include?(f)  then
            t = yield cr, f
            if result[cl][f.name] then
              result[cl][f.name] += t
            else
              result[cl][f.name] = t
            end
          elsif !result[cl][f.name]
            result[cl][f.name] = unit
          end
        end
      end
    end
  end  

  return result
end
