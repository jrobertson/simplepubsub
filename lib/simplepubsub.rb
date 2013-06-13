#!/usr/bin/env ruby

# file: simplepubsub.rb

require 'open-uri'
require 'drb'


USER_AGENT = 'SimplePubSub client 0.1'

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
        "subscribe?topic=#{topic}&uri=" + \
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
end
