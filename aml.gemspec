Gem::Specification.new do |s|
  s.name          = 'aml'
  s.version       = '0.1.3.1'
  s.date          = Time.new.strftime('%Y-%m-%d')
  s.summary       = "Abstract Markup Language"
  s.description   = "Abstract Markup Language is a robust and feature rich markup language designed to avoid repetition and promote clear, well-indented markup."
  s.authors       = ["Daniel Esquivias"]
  s.email         = 'daniel@abstractmarkup.com'
  s.files         = Dir.glob("{bin,lib}/**/*")
  s.require_path  = 'lib'
  s.executables   = ['aml']
  s.homepage      = 'https://abstractmarkup.com'
  s.license       = 'MIT'
  s.required_ruby_version = '>=2.0.0'
end