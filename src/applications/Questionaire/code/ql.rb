require 'core/system/load/load'
require 'core/diagram/code/stencil'

if !ARGV[0] then
  $stderr << "Usage: #{$0} <model>\n"
  exit!
end

Loader.load "expr.grammar"
Loader.load "impl.grammar"

qns = Loader.load(ARGV[0])

Print.print(qns)

Wx::App.run do
  win = StencilFrame.new
  win.setup 'ql', qns
  win.show
end
