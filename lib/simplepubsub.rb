#!/usr/bin/env ruby

# file: simplepubsub.rb

require 'open-uri'
require 'drb'
require 'dws-registry'
require 'socket'


USER_AGENT = 'SimplePbSub client 0.5'

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

      def initialize(hostname)
        @hostname = hostname
      end

      def get(topic, &get_proc)

        DRb.start_service nil, Echo.new(&get_proc)
         
        obj = DRbObject.new nil, "druby://#{@hostname}:59000"
        obj.subscribe(topic, DRb.uri)
        DRb.thread.join        

      end

      def publish(topic, message)

        DRb.start_service
        obj = DRbObject.new nil, "druby://#{@hostname}:59000"
        obj.deliver topic, message
      end
    end

    attr_reader :remote_obj

    # generally used by the web server
    #
    def initialize(hostname)
      
      DRb.start_service
      # attach to the DRb server via a URI given on the command line
      @remote_obj = DRbObject.new nil, "druby://#{hostname}:59000"      
    end
    
    def self.connect(base_url)
      yield(PubSub.new base_url)
    end
  end
  
  class Server
      
    attr_reader :subscribers, :bridges
    
    def initialize(raw_reg='simplepubsub.xml')


      h = {DWSRegistry: ->{raw_reg}, String: ->{DWSRegistry.new raw_reg},:'RSC::Package' => ->{raw_reg}}

      @reg = h[raw_reg.class.to_s.to_sym].call
      
      doc = Rexle.new(@reg.xml('hkey_apps/simplepubsub'))

      root = doc.root
      # try to read the subscribers
      topics = root.xpath 'subscription_topics/*'

      @hostname = Socket.gethostname
      @subscribers, @bridges = {'#' => []}, {'#' => {}}     
            
      topics.each do |topic_element|
        topic = topic_element.name
        @subscribers[topic] ||= []
        @subscribers[topic] = topic_element.xpath 'subscribers/*/text()'
      end

      @subscribers['#'] = root.xpath 'subscription_all_topics' + \
          '/subscribers/*/text()'                            

      root.xpath('bridge_topics/*').each do |topic_element|
        topic = topic_element.name
        @bridges[topic] = topic_element.elements[0].elements.inject({}) do |r,x|
          r.merge({x.name.to_s => x.text('address')})
        end
      end


      @bridges['#'] = root.xpath('bridge_all_topics/subscribers/*')
          .inject({}) do |r,x|
        r.merge({x.name.to_s => x.text('address')})
      end

      'done'
    end

    def start()
      
      # start up the DRb service
      DRb.start_service 'druby://:59000', self

      # wait for the DRb service to finish before exiting
      DRb.thread.join

      'done'
    end
    
    def subscribe(topic, uri)
      
      topic.sub!('/','_')
      @subscribers[topic] ||= []
      @subscribers[topic] << uri      
      
      # e.g. 'hkey_apps/simplepubsub/subscription_topics/magic/subscribers/niko', 
      #         'druby://niko:353524'
      if topic == '#' then
        key = "hkey_apps/simplepubsub/subscription_all_topics/subscribers/%s" % \
          [uri[/[^\/]+$/].sub(':','')]
      else
        key = "hkey_apps/simplepubsub/subscription_topics/%s/subscribers/%s" % \
          [topic, uri[/[^\/]+$/].sub(':','')]        
      end
      
      @reg.set_key key, uri
    end   
    
    def deliver(topic, msg)
      
      topic.sub!('/','_')
      
      if not @subscribers.include?(topic) and \
          not @subscribers.include?('#') then
        return 'no topic subscribers' 
      end
                 

      DRb.start_service

      topic_subscribers = @subscribers[topic]
      
      if topic_subscribers then
      
        topic_subscribers.each do |uri|

          next if @subscribers['#'].include? uri
          
          Thread.new {
            begin          
              
              echo = DRbObject.new nil, uri            
              echo.message topic, msg
              
            rescue DRb::DRbConnError => e             
              
              @subscribers[topic].delete uri
              
              if @subscribers[topic].empty? then
                @subscribers.delete topic 
                key = "hkey_apps/simplepubsub/subscription_topics/%s" % [topic]
              else
                key = "hkey_apps/simplepubsub/subscription_topics/%s/subscribers/%s" % \
                    [topic, uri[/[^\/]+$/].sub(':','')]              
              end
              
              @reg.delete_key key
            end          
          }
          
        end
      end            

      @subscribers['#'].each do |uri|
        Thread.new {
          
          begin
            echo = DRbObject.new nil, uri        
            echo.message topic, msg
          rescue DRb::DRbConnError => e
            
            @subscribers['#'].delete uri
            key = "hkey_apps/simplepubsub/subscription_all_topics/subscribers/%s" % \
                  [uri[/[^\/]+$/].sub(':','')]         
            @reg.delete_key key          
          end          
        }

      end
    end
    
    def add_bridge(topic, hostname, address)
      
      if topic == '#' then

        key = "hkey_apps/simplepubsub/bridge_all_topics/webserver/%s/address" % \
            [hostname]        
      else
        topic.sub!('/','_')
        @bridges[topic] ||= {}

        key = "hkey_apps/simplepubsub/bridge_topics/%s/webserver/%s/address" % \
            [topic, hostname]
      end
      
      @bridges[topic].merge!(hostname => address)      
      @reg.set_key key, address    
    end
    
    def delete_bridge(topic, hostname)
      
      @bridges[topic].delete hostname
      
      if @bridges[topic].empty? and topic != '#' then        
        @bridges.delete_key(topic)
        key = "hkey_apps/simplepubsub/bridge_topics/%s" % [topic]
      else
        key = "hkey_apps/simplepubsub/bridge_topics/%s/webserver/%s/address" % \
            [topic, hostname]                
      end
      
      @reg.delete_key key      
    end
    
    def bridge_deliver(topic, message, excluded_host=nil)
      
      return 'no matching topic' unless @bridges.has_key? topic
      
      if excluded_host  then
        bridges = @bridges[topic].select{|x| x != excluded_host}
      else
        bridges = @bridges[topic]
      end
      
      bridges.values.each do |address|
        url = "http://%s/do/simplepubsub/bridgepub?topic=%s&hostname=%s&message=%s" % \
            [address, URI.escape(topic), @hostname, URI.escape(message)]
        r = open(url, 'UserAgent' => USER_AGENT)
      end
      'bridge delivered'
    end
    
  end
  
end
