Gem::Specification.new do |s|
  s.name = 'puma-status'
  s.version = "0.1.1"
  s.authors = ["Yoann Lecuyer"]
  s.date = '2019-07-14'
  s.summary = 'Command-line too for puma to display information about running request/process'
  s.license = "MIT"
  s.homepage = 'https://github.com/ylecuyer/puma-status'

  s.files = Dir.glob("{bin,lib}/**/*") + %w(LICENSE)
  s.require_paths = ["lib"]
  s.executables = ['puma-status']

  s.add_runtime_dependency "colorize", '~> 0.8'
  s.add_runtime_dependency "net_http_unix", '~> 0.2'

  s.add_development_dependency "rspec", '~> 3.8'
  s.add_development_dependency "climate_control", '~> 0.2'
  s.add_development_dependency "timecop", '~> 0.9'
end
