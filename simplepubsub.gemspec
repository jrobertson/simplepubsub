Gem::Specification.new do |s|
  s.name = 'simplepubsub'
  s.version = '0.3.3'
  s.summary = 'simplepubsub'
  s.authors = ['James Robertson']
  s.files = Dir['lib/**/*.rb']
  s.signing_key = '../privatekeys/simplepubsub.pem'
  s.cert_chain  = ['gem-public_cert.pem']  
  s.add_dependency('dws-registry')
end
