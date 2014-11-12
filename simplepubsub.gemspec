Gem::Specification.new do |s|
  s.name = 'simplepubsub'
  s.version = '1.1.10'
  s.summary = 'simplepubsub'
  s.authors = ['James Robertson']
  s.files = Dir['lib/**/*.rb']
  s.signing_key = '../privatekeys/simplepubsub.pem'
  s.cert_chain  = ['gem-public_cert.pem']  
  s.add_runtime_dependency('websocket-eventmachine-server', '~> 1.0', '>=1.0.1')
  s.add_runtime_dependency('websocket-eventmachine-client', '~> 1.0', '>=1.0.1')
  s.add_runtime_dependency('xml-registry', '~> 0.2', '>=0.2.3')
  s.license = 'MIT'
  s.email = 'james@r0bertson.co.uk'
  s.homepage = 'https://github.com/jrobertson/simplepubsub'
  s.required_ruby_version = '>= 2.1.0'
end
