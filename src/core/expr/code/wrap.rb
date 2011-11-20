
module Wrap
  def wrap_?(fields, *args)
    Implicit[:render => "(#{render__(fields.render, *args)})"]
  end
end

