

ruby -I . core/lang/code/convert.rb $1.rb
ruby -I . core/grammar/render/trans.rb $1.code code_js > $1.js

