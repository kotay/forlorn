module Gentlemen
  class SirportlyDataFrame < Gentleman

    description <<-MD
        The Sirportly Data Frame Gentleman allows you to fetch additional information about a ticket before POSTING to a location of your choosing.
            For example you may want to forward on custom fields from a Sirportly ticket to example.com

              {
                :post_uri => "example.com",
                :token => "My Sirportly API token",
                :secret   => "My Sirportly API secret"
                :sirportly_domain => "https://api.sirportly.com"
                :key => "shared key"
              }

          `data` can be specified which needs to be an array of hash keys to forward (as documented by the Sirportly Ticket API)
    MD

    event_description <<-MD
          { :post_url=>"http://myurl.com"}
    MD

    default_schedule "11pm"

    def validate_options
    end

    def working?
      (event = event_created_within(1.days)) && event.payload.present?
    end

    def default_options
      {
        :post_uri => "http://testdial9.p45.eu/",
        :token => "dev",
        :secret => "dev",
        :sirportly_domain => "https://api.sirportly.com",
        :key => "secret"
      }
    end

    cannot_receive_events!
    cannot_be_scheduled!

    def receive_webhook(params)
      if options[:key] != params[:secret]
        [{status: "bad key"}, 200]
      else
        #LIVE: 
        #@sirportly = Sirportly::Client.new('a4d710d2-477f-9238-66b4-14baeccd9856', 'jnhqo8ei2s6uftoqnfp7ky6jc7lhkdeak3vjevr3gbq9ekxanu')
        Sirportly.domain = options[:sirportly_domain]
        @sirportly = Sirportly::Client.new(options[:token], options[:secret])
        ticket = ""
        begin
          ticket = @sirportly.ticket(params["ticket"])
        rescue Sirportly::Errors::NotFound
          ticket = {}
        end
        forward_ticket(params,ticket)
        create_event :payload => { :content => ticket, :time => Time.now.to_i }
        [{status: "successfully_forwarded", custom_fields: ticket.attributes["custom_fields"], ticket_ref: ticket.attributes["reference"]}, 200]
      end
      #[{status: "successfully_forwarde", params:"#{params}"}, 200]
    end

    def forward_ticket(params,ticket)
      uri = URI options[:post_uri]
      req = Net::HTTP::Post.new(uri.request_uri)
      req.form_data = {:ticket => ticket.attributes[:subject].to_json}
      Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == "https") { |http| http.request(req) }
    end

    def trigger_webhook(params)
      receive_webhook(params).tap do
        self.last_webhook_at = Time.now
        save!
      end
    end


    def check
      if memory[:filter_counts] && memory[:filter_counts].length > 0
        memory[:filter_counts].each do |filter, count|
          create_event :payload => { :filter => filter.to_s, :count => count, :time => Time.now.to_i }
        end
        memory[:filter_counts] = {}
        save!
      end
    end
  end
end