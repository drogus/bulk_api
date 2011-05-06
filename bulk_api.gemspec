# Provide a simple gemspec so you can easily use your enginex
# project in your rails apps through git.
Gem::Specification.new do |s|
  s.name = "bulk_api"
  s.summary = "Easy integration of rails apps with sproutcore."
  s.description = "Easy integration of rails apps with sproutcore."
  s.files = Dir["{app,lib,config}/**/*"] + ["MIT-LICENSE", "Rakefile", "Gemfile", "README.rdoc"]
  s.version = "0.0.1"

  s.add_dependency "rails",      "~> 3.0"
  s.add_dependency "sproutcore", "~> 1.0"
end
