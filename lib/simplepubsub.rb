#!/usr/bin/env ruby

# file: simplepubsub.rb

require 'websocket-eventmachine-server'
require 'websocket-eventmachine-client'
require 'xml-registry'


module SimplePubSub

  class Server

    def self.start(host: '0.0.0.0', port: 59000)


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

              topic = a.last.rstrip.gsub('+','*')\
                                              .gsub('#','*//').gsub('or','|')
              subscribers[topic] ||= []
              subscribers[topic] << ws

              # affix the topic to the subscriber's websocket
              def ws.subscriber_topic=(topic)  @topic = topic     end
              def ws.subscriber_topic()  @topic                   end

              ws.subscriber_topic = topic

            elsif a.length > 1

              puts "publish this %s: %s" % a
              current_topic, message = a

              reg = XMLRegistry.new
              reg[current_topic] = message

              subscribers.each do |topic,conns|

                node = reg.doc.root.xpath topic.gsub(/\S\b/,'\0/text()')

                if node.any? then                  
                  conns.each {|x| x.send current_topic + ': ' + message}
                end

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

      def get(topic, &get_proc)

        @topic = 'subscribe to topic'
        @proc, @message = get_proc, topic
      end

      def publish(*args)

        topic, message = args.length > 1 ? args : args.first.split(':',2)

        @topic, @message = topic, message
        @proc = ->(_,_){}
      end
    end
    
    def self.connect(hostname, port: '59000', &connect_blk)

      pubsub = PubSub.new
      connect_blk.call(pubsub)

      blk = lambda do |ws, pubsub, em_already_running|

        ws.onopen do
          puts "Connected"
        end

        ws.onmessage do |msg, type|

          a = msg.split(/\s*:\s*/,2)
          topic, message = a
          EM.defer {pubsub.proc.call topic, message}

        end

        ws.onclose do
          puts "Disconnected"

          # reconnect within a minute
          seconds = rand(60)

          seconds.downto(1) do |i| 
            s = "reconnecting in %s seconds" % i; 
            print s 
            sleep 1
            print "\b" * s.length
          end
          puts


          self.connect hostname, port: port, &connect_blk
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

        ws = c.connect(params, &connect_blk)
        blk.call ws, pubsub, em_already_running = true
      rescue

        thread = Thread.new do
          EM.run do 

            ws = c.connect(params, &connect_blk)
            blk.call(ws, pubsub, em_already_running = false)
          end
        end
        thread.join
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