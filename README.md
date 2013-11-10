# simplepubsub

The SimplePubSub gem uses a messaging system similar to MQTT.

## Example

    require 'simplepubsub'

    # Subscribe example
    SimplePubSub::Client.connect('a2.jamesrobertson.eu') do |client|
      client.get('magic') do |topic, message|
        puts "#{topic}: #{message}"
      end 
    end

    # Publish example
    SimplePubSub::Client.connect('a2.jamesrobertson.eu') do |client|
      client.publish('magic', Time.now.to_s)
    end

