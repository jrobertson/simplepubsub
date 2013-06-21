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

## Requirements

To try an example similar to the one above you will need a web server which accepts publish and subscribe requests.

## Examples

Here's examples of requests which are used with my web server (a2.jamesrobertson.eu):

### starting the service
/do/simplepubsub/start *used by the web server to initialize the SimplePubSub::Server object*

### adding a remote web server (bridging)
/do/simplepubsub/add-bridge?topic=magic&hostname=rosa&address=da2.j--r.info:3000 *used by the SimplePubSub::Server to add a remote web server to create a bridge*

### publishing from a remote web server
/do/simplepubsub/bridgepub?topic=magic&hostname=rosa&msg=more%20testing *used by the SimplePubSub::Server to publish a message from a remote web server*

### publishing 
/do/simplepubsub/publish?topic=magic&msg=testing%20the%20message *used by the SimplePubSub::Client to publish a message*

### subscribing
/do/simplepubsub/subscribe?topic=test&uri=druby://fortina:36400 *used by the SimplePubSub::Client to subscribed to a topic*

### resetting the service
/do/simplepubsub/reset *initializes the SimplePubSub gem and removes all subscribers, and bridges*

### debugging
/do/simplepubsub/subscribers *returns a list of DRb addresses subscribed to each topic*
/do/simplepubsub/bridges *returns a list of remote web servers subscribed to each topic*

Here's the Ruby Scripting file I used:

    <package>
      <job id='start'>
        <script>
          require 'simplepubsub'
          require 'socket'
          
          @sps = SimplePubSub::Server.new Socket.gethostname      
          'reset'
        </script>
      </job>     
      <job id='reset'>
        <script>
          require 'simplepubsub'    
          require "socket"
          
          @sps = SimplePubSub::Server.new Socket.gethostname      
          'reset'
        </script>
      </job>     
      <job id='subscribers'>
        <script>

          @sps.subscribers.inspect

        </script>
      </job>
      
      <job id='bridges'>
        <script>

          @sps.bridges.inspect

        </script>
      </job>       
      <job id='subscribe'>
        <script>

          topic = URI.unescape(params[:topic])
          uri = params[:uri]
                
          @sps.subscribe(topic, uri)
          
          'subscribed' + uri.inspect

        </script>
      </job>  
      <job id='add-bridge'>
        <script>

          topic = URI.unescape(params[:topic])
          hostname = params[:hostname]
          address = params[:address]
          
          @sps.add_bridge(topic, hostname, address)
        
          'bridged' 

        </script>
      </job>    
      <job id='publish'>
        <script>
          
          topic = URI.unescape(params[:topic])
          msg = URI.unescape(params[:msg] || params[:message])
          
          @sps.deliver topic, msg
          @sps.bridge_deliver topic, msg

          'published'
          
        </script>
      </job>
      <job id='bridgepub'>
        <script>

          topic = URI.unescape(params[:topic])
          msg = URI.unescape(params[:msg] || params[:message])
          hostname = params[:hostname]
          
          @sps.deliver topic, msg
          @sps.bridge_deliver topic, msg, hostname
          
          'bridge published '
          
        </script>
      </job>  
    </package>

## Resources

* [Introducing the MQTT gem](http://www.jamesrobertson.eu/snippets/2013/mar/08/introducing-the-mqtt-gem.html)
* [A message setup similar to MQTT using DRb and a Rack web server](http://www.jamesrobertson.eu/svg/2013/jun/11/mqtt-replacement-a-simple-m2m-message-system-similar-to-mqtt-using.svg)
* [Introducing the Rack-Rscript gem](http://www.jamesrobertson.eu/snippets/2012/02/26/1711hrs.html)
* [SimplePubSub bridging](http://www.jamesrobertson.eu/svg/2013/jun/16/simplepubsub-bridge.svg)

simplepubsub gem mqtt messaging m2m
