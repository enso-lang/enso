This project contains Ensō, a theoretically sound and practical reformulation of the 
concepts of model-driven software development.

1) The system requires Ruby 1.9 to run.

2) Recommend that you install with RVM
  a) Install RVM
    http://www.rvm.beginrescueend.com/
  b) Edit ~/.rvmrc before installing the ruby interpreter: 
      rvm_archflags="--arch x86_64,i386"
  c) Install ruby 
      rvm install 1.9.2
      rvm 1.9.2
      
2) The diagram editor requires wxRuby
  a) use "gem" to install "wxruby-ruby19-2.0.1-x86-darwin-9.gem"
     download the gem file (its in a zip, so unzip it), and invoke
         gem install <path>/wxruby-ruby19-2.0.1-x86-darwin-9.gem
  b) to run Ruby with wxRuby, use "arch -i386 ruby <ruby-file>"

3) Change your ~/.bashrc file to define RUBYOPT
     export RUBYOPT="-I ."
     
4) Run the tests
     cd src
     ruby -I . test/runall.rb
     
Try the mini mini GUI demo
    arch -i386 ruby -I . core/diagram/code/diagram.rb
   