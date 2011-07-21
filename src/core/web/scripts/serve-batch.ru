# -*-ruby-*-

# RUBYOPT="-I." thin start -V -D --stats . -R core/web/code/serve.ru

require 'core/web/code/toplevel-batch'
require 'core/system/load/load'

require 'logger'

web = Loader.load(ENV['WEB'])
root = Loader.load(ENV['ROOT'])
log = Logger.new($stderr)

# TODO: detect when thin is debug mode, otherwise use WARN
log.level = Logger::DEBUG

app = Web::EnsoBatchWeb.new(web, root, log)
use Rack::CommonLogger
run app
