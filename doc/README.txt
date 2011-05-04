This project contains Ensō, a theoretically sound and practical reformulation of the 
concepts of model-driven software development.

1) The system requires Ruby 1.9 to run.
  ** You must compile Ruby with tail-call optimization, by editing "vm_opts.h":
  #define OPT_TRACE_INSTRUCTION        0
  #define OPT_TAILCALL_OPTIMIZATION    1

2) The diagram editor requires wxRuby
  NOTE: On that mac installing Ruby 1.9 with wxRuby requires some care:
  a) configure ruby with "--with-arch=x86_64,i386" to get both architectures
  b) use "gem" to install "wxruby-ruby19-2.0.1-x86-darwin-9.gem"
  c) to run Ruby with wxRuby, use "arch -i386 ruby <ruby-file>"
