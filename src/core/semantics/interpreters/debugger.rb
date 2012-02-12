
def Debugger(op, mod)
  Compose(op, [mod]) do |fields, type, args={}|
    puts "[DEBUG] At #{type}.#{op}: #{fields} args=(#{args})"
    gets
    __call(op, fields, type, args)
  end
end
