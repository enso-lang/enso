self.require("rbconfig");
(ruby_release = S("", self.RUBY_VERSION(), " (", self.RUBY_RELEASE_DATE(), ")"));
puts(ruby_release);
puts(self.ARGV());