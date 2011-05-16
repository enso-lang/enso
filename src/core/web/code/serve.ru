
# RUBYOPT="-I." thin start -V -D --stats . -R core/web/code/serve.ru

require 'core/web/code/toplevel'

app = Toplevel.new

use Rack::CommonLogger

run app
