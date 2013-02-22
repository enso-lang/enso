# -*-ruby-*-

# RUBYOPT="-I." thin start -V -D --stats . -R apps/web/code/serve.ru

require 'apps/web/code/batch-toplevel'
require 'core/system/load/load'

require 'logger'

web = Loader.load(ENV['WEB'])
schema = Loader.load(ENV['SCHEMA'])
log = Logger.new($stderr)

# TODO: detect when thin is debug mode, otherwise use WARN
log.level = Logger::DEBUG

app = BatchWeb::EnsoWeb.new(web, schema, ENV['AUTH'], log)
use Rack::CommonLogger
run app
