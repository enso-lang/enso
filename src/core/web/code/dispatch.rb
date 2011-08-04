
require 'core/web/code/web'

module Web::Eval
  module Dispatch
    def eval(obj, *args)
      send(obj.schema_class.name, obj, *args)
    end
  end
end
