
# RUBYOPT="-I." thin start -V -D --stats . -R core/web/code/serve.ru

require 'core/web/code/toplevel'
require 'core/system/load/load'

require 'logger'

root = Loader.load('genealogy.schema')
web = Loader.load('example.web')
log = Logger.new($stderr)

# TODO: detect when thin is debug mode, otherwise use WARN
log.level = Logger::WARN

app = Toplevel.new(web, root, log)
use Rack::CommonLogger
run app
