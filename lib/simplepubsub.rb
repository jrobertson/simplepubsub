#!/usr/bin/env ruby

# file: simplepubsub.rb

require 'websocket-eventmachine-server'
require 'xml-registry'


module SimplePubSub

  class Broker

    def self.start(host: '0.0.0.0', port: 59000)


      EM.run do

        subscribers = {}

        WebSocket::EventMachine::Server.start(host: host, port: port) do |ws|

          ws.onopen do
            #puts "Client connected"
          end

          ws.onmessage do |msg, type|

            msg = '' if not msg[0][/\w/]
            a = msg.strip.split(/\s*:\s*/,2)

            def ws.subscriber?() 
              false
            end
            
           
            if a.first == 'subscribe to topic' then

              topic = a.last.rstrip.gsub('+','*')\
                                              .gsub('#','*//').gsub('or','|')
              subscribers[topic] ||= []
              subscribers[topic] << ws

              # affix the topic to the subscriber's websocket
              def ws.subscriber_topic=(topic)  @topic = topic     end
              def ws.subscriber_topic()  @topic                   end

              ws.subscriber_topic = topic

            elsif a.length > 1 and a.first != ''

              current_topic, message = a
              
              if not current_topic[0] == '/' and \
                                not current_topic =~ /[^a-zA-Z0-9\/_ ]$/ then
                
                reg = XMLRegistry.new
                reg[current_topic] = message

                subscribers.each do |topic,conns|

                  node = reg.doc.root.xpath topic.sub(/\S\b$/,'\0/text()')

                  if node.any? then                  
                    conns.each {|x| x.send current_topic + ': ' + message}
                  end

                end
                
                reg = nil
                
              end

            end

          end

          ws.onclose do

            if ws.respond_to? :subscriber_topic then
              subscribers[ws.subscriber_topic].delete ws 
            end
          end
        end

      end
    end
  end

end

if __FILE__ == $0 then

  SimplePubSub::Broker.start

end