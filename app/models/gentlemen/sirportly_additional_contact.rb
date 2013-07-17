module Gentlemen
  class SirportlyAdditionalContact < Gentleman

    description <<-MD
        The Sirportly Additional Contacts Gentleman simply responds to a Ticket Macro and adds additional contacts
              {
                :token => "My Sirportly API token",
                :secret   => "My Sirportly API secret",
                :sirportly_domain => "https://api.sirportly.com",
                :key => "shared key",
                :additional_contacts => "a@example.com,b@example.com",
              }

        Ensure that you use the URL and enable data to be sent.
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
        :token => "dev",
        :secret => "dev",
        :sirportly_domain => "https://api.sirportly.com",
        :key => "secret",
        :additional_contacts => "test@example.com"
      }
    end

    cannot_receive_events!
    cannot_be_scheduled!

    def receive_macro(params)
      if options[:key] != params[:secret]
        [{status: "wrong secret key"}, 200]
      else
        fork do 
          begin
            Sirportly.domain  = options[:sirportly_domain]
            sirportly         = Sirportly::Client.new(options[:token], options[:secret])
            payload           = JSON.parse(params["ticket"])
            ticket            = sirportly.ticket(payload["reference"])
            ticket.update(:additional_contact_methods => options[:additional_contacts])
            create_event :payload => { :contact_methods_added => options[:additional_contacts], :time => Time.now.to_i }
            [{status: "success"}, 200]
          rescue Sirportly::Errors
            [{status: "failed"}, 200]
          end
        end
      end
    end

    def trigger_webhook(params)
      receive_macro(params).tap do
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