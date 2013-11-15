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

            def ws.subscriber?() 
              false
            end
           
            if a.first == 'subscribe to topic' then

              topic = a.last.rstrip
              subscribers[topic] ||= []
              subscribers[topic] << ws

              def ws.subscriber_topic=(topic)  @topic = topic     end
              def ws.subscriber_topic()  @topic                   end

              ws.subscriber_topic = topic

            elsif a.length > 1

              puts "publish this %s: %s" % a
              topic, message = a

              if subscribers[topic] then
                subscribers[topic].each {|c| c.send topic + ': ' + message }
              end

              if subscribers['#'] then
                subscribers['#'].each {|c| c.send topic + ': ' + message }
              end

              #ws.send msg, :type => type

            end

          end

          ws.onclose do
            puts "Client disconnected"
            if ws.respond_to? :subscriber_topic then
              subscribers[ws.subscriber_topic].delete ws 
            end
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

      blk = lambda do |ws, pubsub, em_already_running|

        ws.onopen do
          puts "Connected"
        end

        ws.onmessage do |msg, type|

          a = msg.split(/\s*:\s*/,2)
          topic, message = a
          r = pubsub.proc.call topic, message
          (ws.close; EM.stop) if r == :stop and em_already_running == false
        end

        ws.onclose do
          puts "Disconnected"
        end

        EventMachine.next_tick do
          ws.send pubsub.topic + ': ' + pubsub.message
        end

      end

      address = hostname + ':' + port
      params = {uri: 'ws://' + address}
      c = WebSocket::EventMachine::Client

      begin

        # attempt to run a websocket assuming the EventMachine is 
        #   already running
        ws = c.connect(params)
        blk.call ws, pubsub, em_already_running = true
      rescue

        EM.run do 
          ws = c.connect(params)
          blk.call(ws, pubsub, em_already_running = false)
        end
      end

    end    
  end
end

if __FILE__ == $0 then

  # Server example
  SimplePubSub::Server.new.start

=begin

  # Subscribe example
  SimplePubSub::Client.connect('localhost') do |client|
    client.get('test') do |topic, message|
      puts "#{topic}: #{message}"
    end 
  end

  # Publish example
  SimplePubSub::Client.connect('localhost') do |client|
    client.publish('test', Time.now.to_s)
  end

=end
end