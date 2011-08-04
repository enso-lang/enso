
def tablename_from_name(root_class, classname)
  #figure out field name of root from classname
  #assume there is only one field of this type in the root class
  root_class.fields.detect{|f|f.type.name == classname}.name
end
