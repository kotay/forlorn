require 'date'

module Gentlemen
  class SirportlyAgent < Gentleman

    description <<-MD
      Receives a webhook from Sirportly
    MD

    event_description <<-MD
          {
            :url => "www.google.com"
            :phrase => "aTech"
          }
    MD

    #default_schedule "8pm"

    #cannot_be_scheduled!

    def working?
      (event = event_created_within(2.days)) && event.payload.present?
    end

    def default_options
      {
        :url => "www.google.com",
        :phrase => "aTech",
      }

    end

    def validate_options
      #errors.add(:base, "zipcode is required") unless options[:zipcode].present?
      errors.add(:base, "phrase required") unless options[:phrase].present?
    end

    def receive(events)
      memory[:queue] ||= []
      events.each do |event|
        memory[:queue] << event.payload
      end
    end

    def check
      if memory[:queue] && memory[:queue].length > 0
        hydra = Typhoeus::Hydra.new
        request = Typhoeus::Request.new(options[:url], :followlocation => true)
        request.on_complete do |response|
          #binding.pry
          doc = Nokogiri::HTML(response.body).text()
          Rails.logger.info "Storing new result for google"
          result = {}
          result[:data] = doc
          create_event :payload => result
        end
        hydra.queue request
        hydra.run
      end
    end

    def is_tomorrow?(day)
      Time.zone.at(day["date"]["epoch"].to_i).to_date == Time.zone.now.tomorrow.to_date
    end
  end
end
