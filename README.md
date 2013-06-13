# simplepubsub

The SimplePubSub gem uses a messaging system similar to MQTT.

## Example

    require 'simplepubsub'

    # Subscribe example
    SimplePubSub::Client.connect('a2.jamesrobertson.eu') do |client|
      client.get('test') do |topic, message|
        puts "#{topic}: #{message}"
      end 
    end

    # Publish example
    SimplePubSub::Client.connect('a2.jamesrobertson.eu') do |client|
      client.publish('test', Time.now.to_s)
    end

## Requirements

To try an example similar to the one above you will need a web server which accepts publish and subscribe requests.

Here's examples of requests which are used with my web server (a2.jamesrobertson.eu):

* /do/simplepubsub/debug
* /do/simplepubsub/reset
* /do/simplepubsub/publish?topic=test&message=13-jun-2013%2020:00
* /do/simplepubsub/subscribe?topic=test?uri=druby://fortina:36400

Here's the Ruby Scripting file I used:

    <package>
      <job id='reset'>
        <script>
        <![CDATA[

          @simplepubsub = {}
          'reset'

        ]]>
        </script>
      </job>   
      <job id='debug'>
        <script>
        <![CDATA[

          @simplepubsub.inspect

        ]]>
        </script>
      </job>     
      <job id='subscribe'>
        <script>
        <![CDATA[

          topic = params[:topic]
          uri = params[:uri]
          address = uri[/druby:\/\/([^:]+)/,1]
                
          @simplepubsub[topic] ||= {}
          @simplepubsub[topic].merge!({address => uri})
          
          'subscribed' + uri.inspect

        ]]>
        </script>
      </job>  
      <job id='publish'>
        <script>
        <![CDATA[ 

          require 'drb'    
          
          return 'no topic subscribers' unless @simplepubsub.include? params[:topic]
          topic = URI.unescape(params[:topic])
          msg = URI.unescape(params[:msg] || params[:message])
          

          DRb.start_service

          @simplepubsub[topic].values.each do |uri|
            echo = DRbObject.new nil, uri
            echo.message topic, msg
          end
          'published'
          
        ]]>
        </script>
      </job>
    </package>

## Resources

* [Introducing the MQTT gem](http://www.jamesrobertson.eu/snippets/2013/mar/08/introducing-the-mqtt-gem.html)
* [A message setup similar to MQTT using DRb and a Rack web server](http://www.jamesrobertson.eu/svg/2013/jun/11/mqtt-replacement-a-simple-m2m-message-system-similar-to-mqtt-using.svg)
* [Introducing the Rack-Rscript gem](http://www.jamesrobertson.eu/snippets/2012/02/26/1711hrs.html)

simplepubsub gem mqtt messaging m2m
