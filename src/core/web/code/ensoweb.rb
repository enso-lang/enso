
require 'core/web/code/handlers'

class EnsoWeb
  include Web::Eval

  def initialize(web, root, log)
    @root = root
    @log = log
    @env = {'root' => Result.new(root, Ref.new([]))}
    mod_eval = Mod.new(@env)
    mod_eval.eval(web)
  end

  def handle(req, out)
    handler = if req.get? then
                Get.new(req.url, req.params, @env, @root, @log)
              elsif req.post? then
                Post.new(req.url, req.params, @env, @root, @log)
              else
                raise "Unsupported request: #{req}"
              end
    handler.handle(out)
  end
end
