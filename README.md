# Running a SimplePubSub Broker

The SimplePubSub gem uses a messaging system similar to MQTT.

## Getting started

Gem install the simplepubsub gem e.g. `sudo gem install simplpubsub`

## Running the broker

The broker can conveniently be run from an IRB session e.g.

    require 'simplepubsub'

    SimplePubSub::Broker.start

Notes:

* The default IP address binding is 0.0.0.0 which can be changed by supplying the named parameter *host* to initialize() e.g. `initialize(host: '127.0.0.1')`.
* The default port is 59000 which can be changed by supplying the named parameter *port* to initialize() e.g. `initialize(port: '8080')`.

## Resources

* simplepubsub https://rubygems.org/gems/simplepubsub
* Introducing the Sps-sub gem http://www.jamesrobertson.eu/snippets/2015/may/16/introducing-the-sps-sub-gem.html
* Introducing the sps-pub gem http://www.jamesrobertson.eu/snippets/2015/oct/09/introducing-the-sps-pub-gem.html

simplepubsub gem
