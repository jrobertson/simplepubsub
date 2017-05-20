#!/usr/bin/env ruby

# file: simplepubsub.rb

require "socket"
require 'sps-pub'
require 'xml-registry'
require 'websocket-eventmachine-server'



module SimplePubSub

  class Broker
    

    def self.start(host: '0.0.0.0', port: 59000, brokers: [])


      EM.run do

        subscribers = {}

        WebSocket::EventMachine::Server.start(host: host, port: port) do |ws|

          ws.onopen do
            #puts "Client connected"
          end

          ws.onmessage do |msg, type|

            msg = '' if not msg[0][/[\w:]/]
            a = msg.lstrip.split(/\s*:\s/,2)

            def ws.subscriber?() 
              false
            end
            
           
            if a.first == 'subscribe to topic' then

              topic = a.last.rstrip.gsub('+','*')\
                                              .gsub('#','*//').gsub(/\bor/,'|')
              subscribers[topic] ||= []
              subscribers[topic] << ws

              # affix the topic to the subscriber's websocket
              def ws.subscriber_topic=(topic)  @topic = topic     end
              def ws.subscriber_topic()  @topic                   end

              ws.subscriber_topic = topic

            elsif a.length > 1 and a.first != ''

              current_topic, message = a
              
              # is the message from another SPS broker?
              
              if current_topic[0] == ':' then
                
                # strip of the broker ID
                current_topic.sub!(/:\w+\//,'')
                
              elsif brokers.any?                                
                
                brokers.each do |broker|
                
                  hostx, portx = broker.split(':',2)
                  portx ||= port

                  
                  #puts 'address: ' + address.inspect
                  fqm = ":%s/%s: %s" % [Socket.gethostname, current_topic, message]

                  begin
                    SPSPub.notice fqm, host: hostx, port: portx
                  rescue
                    puts "warning couldn\'t send to %s:%s" % [hostx, portx]
                  end
                  #sleep 0.5 
                end
              end
              
              if not current_topic[0] == '/' and \
                                not current_topic =~ /[^a-zA-Z0-9\/_ ]$/ then                
                begin
                  
                  reg = XMLRegistry.new
                  reg[current_topic] = message
                
                rescue
                  puts 'simplepubsub.rb warning: ' + ($!).inspect
                end                

                subscribers.each do |topic,conns|
                  
                  xpath = topic.split('/')\
                      .map {|x| x.to_i.to_s == x ? x.prepend('x') : x}\
                      .join('/')

                  node = reg.doc.root.xpath xpath.sub(/\S\b$/,'\0/text()')

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
