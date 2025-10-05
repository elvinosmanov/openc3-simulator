# encoding: ascii-8bit

# Create the overall gemspec
spec = Gem::Specification.new do |s|
  s.name = 'openc3-cosmos-fakesat'
  s.summary = 'OpenC3 cosmos-fakesat plugin'
  s.description = <<-EOF
    cosmos-fakesat plugin facilitating COSMOS user training
  EOF
  s.licenses = ['AGPL-3.0-only', 'Nonstandard']
  s.authors = ['Ryan Melton', 'Jason Thomas']
  s.email = ['ryan@openc3.com', 'jason@openc3.com']
  s.homepage = 'https://github.com/OpenC3/cosmos'
  s.platform = Gem::Platform::RUBY

  time = Time.now.strftime("%Y%m%d%H%M%S")
  if ENV['VERSION']
    s.version = ENV['VERSION'].dup
  else
    time = Time.now.strftime("%Y%m%d%H%M%S")
    s.version = '0.0.0' + ".#{time}"
  end
  s.files = Dir.glob("{targets,lib,tools,microservices}/**/*") + %w(Rakefile LICENSE.txt README.md plugin.txt)
end
