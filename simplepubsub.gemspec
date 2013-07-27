Gem::Specification.new do |s|
  s.name = 'simplepubsub'
  s.version = '0.4.2'
  s.summary = 'simplepubsub'
  s.authors = ['James Robertson']
  s.files = Dir['lib/**/*.rb']
  s.signing_key = '../privatekeys/simplepubsub.pem'
  s.cert_chain  = ['gem-public_cert.pem']  
  s.add_dependency('dws-registry')
  s.license = 'MIT'
  s.email = 'james@r0bertson.co.uk'
  s.homepage = 'https://github.com/jrobertson/simplepubsub'
end
