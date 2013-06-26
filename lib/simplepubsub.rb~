#!/usr/bin/env ruby

# file: simplepubsub.rb

require 'open-uri'
require 'drb'


USER_AGENT = 'SimplePubSub client 0.2'

module SimplePubSub

  class Client
    class PubSub

      class Echo

        def initialize(&get_proc)
          @get_proc = get_proc
        end

        def message(topic, message)
          @get_proc.call topic, message
        end
      end

      def initialize(base_url)
        @base_url = base_url
      end

      def get(topic, &get_proc)

        DRb.start_service nil, Echo.new(&get_proc)
        r = open("http://#{@base_url}/do/simplepubsub/" + \
        "subscribe?topic=#{URI.escape(topic)}&uri=" + \
          DRb.uri, 'UserAgent' => USER_AGENT){|x| x.read}
        DRb.thread.join

      end

      def publish(topic, message)

        params = "/do/simplepubsub/publish?topic=%s&message=%s" % \
         [URI.escape(topic),URI.escape(message)]
        open('http://' + @base_url + params, 'UserAgent' => USER_AGENT)\
          {|x| x.read}
      end
    end

    def self.connect(base_url)
      yield(PubSub.new base_url)
    end
  end
  
  class Server
      
    attr_reader :subscribers, :bridges
    
    def initialize(hostname)
      @hostname = hostname
      @subscribers = {'#' => []}
      @bridges = {'#' => []}
    end
    
    def subscribe(topic, uri)
      @subscribers[topic] ||= []
      @subscribers[topic] << uri      
    end   
    
    def deliver(topic, msg)
      
      if not @subscribers.include?(topic) and \
          not @subscribers.include?('#') then
        return 'no topic subscribers' 
      end
                 

      DRb.start_service

      topic_subscribers = @subscribers[topic]
      
      if topic_subscribers then
      
        topic_subscribers.each do |uri|
        
          next if @subscribers['#'].include? uri              
          echo = DRbObject.new nil, uri
          
          begin
            echo.message topic, msg
          rescue DRb::DRbConnError => e             
            @subscribers[topic].delete uri
          end          
          
        end
      end            

      @subscribers['#'].each do |uri|
      
        echo = DRbObject.new nil, uri
        
        begin
          echo.message topic, msg
        rescue DRb::DRbConnError => e             
          @subscribers['#'].delete uri
        end          

      end
    end
    
    def add_bridge(topic, hostname, address)
      @bridges[topic] ||= {}
      @bridges[topic].merge!(hostname => address)
    end
    
    def bridge_deliver(topic, message, excluded_host=nil)
      
      return 'no matching topic' unless @bridges.has_key? topic
      
      if excluded_host  then
        bridges = @bridges[topic].select{|x| x != excluded_host}
      else
        bridges = @bridges[topic]
      end
      
      bridges.values.each do |address|
        url = "http://%s/do/simplepubsub/bridgepub?topic=%s&hostname=%s&message=%s" % [address, topic, @hostname, URI.escape(message)]
        r = open(url, 'UserAgent' => USER_AGENT)
      end
      'bridge delivered'
    end
    
  end
  
end
