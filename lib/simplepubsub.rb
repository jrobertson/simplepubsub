#!/usr/bin/env ruby

# file: simplepubsub.rb

require 'websocket-eventmachine-server'
require 'websocket-eventmachine-client'


module SimplePubSub

  class Server

    def start(options={})

      opt = {host: '0.0.0.0', port: 59000}.merge options
      host, port = opt[:host], opt[:port]

      EM.run do

        subscribers = {}

        WebSocket::EventMachine::Server.start(host: host, port: port) do |ws|

          ws.onopen do
            puts "Client connected"
          end

          ws.onmessage do |msg, type|

            puts "Received message: #{msg}"

            a = msg.split(/\s*:\s*/,2)
           
            if a.first == 'subscribe to topic' then

              topic = a.last
              subscribers[topic] ||= []
              subscribers[topic] << ws 

            elsif a.length > 1

              puts "publish this %s: %s" % a
              topic, message = a

              if subscribers[topic] and subscribers[topic].any? then

                connections = subscribers[topic]
                connections += subscribers['#'] if subscribers['#']
                connections.each {|c| c.send message }
              end

            end

            ws.send msg, :type => type
          end

          ws.onclose do
            puts "Client disconnected"
          end
        end

      end
    end
  end

  class Client

    class PubSub

      attr_reader :proc, :topic, :message

      def get(topic, options={}, &get_proc)

        @topic = 'subscribe to topic'
        @proc, @message = get_proc, topic
      end

      def publish(topic, message)

        @topic, @message = topic, message
        @proc = ->(_,_){ :stop}
      end
    end
    
    def self.connect(hostname, port='59000')

      pubsub = PubSub.new
      yield(pubsub)

      EM.run do

        address = hostname + ':' + port

        ws = WebSocket::EventMachine::Client.connect(:uri => 'ws://' + address)

        ws.onopen do
          puts "Connected"
        end

        ws.onmessage do |msg, type|

          a = msg.split(/\s*,\s*/,2)
          topic, message = a
          r = pubsub.proc.call topic, message
          (ws.close; EM.stop) if r == :stop
        end

        ws.onclose do
          puts "Disconnected"
        end

        EventMachine.next_tick do
          ws.send pubsub.topic + ': ' + pubsub.message
        end


      end
    end    
  end
end

if __FILE__ == $0 then

  # Subscribe example
  SimplePubSub::Server.new.start

end