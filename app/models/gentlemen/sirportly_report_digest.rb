module Gentlemen
  class SirportlyReportDigest < Gentleman
    attr_accessor :sirportly
    MAIN_KEYS = %w[title message text main value].map(&:to_sym)
    default_schedule "5am"

    description <<-MD
      The Sirportly Report Digest Gentleman collates a minimalistic report of Sirportly Tickets and sends them all via email when run.
      The email will be sent to your account's address and will have a `subject` and an optional `headline` before
      listing the Events.
    MD

    def default_options
      {
          :subject => "You have some notifications!",
          :headline => "Your notifications:",
          :expected_receive_period_in_days => "2"
      }
    end

    def working?
      (event = event_created_within(2.days)) && event.payload.present?
    end

    def validate_options
      errors.add(:base, "subject and expected_receive_period_in_days are required") unless options[:subject].present? && options[:expected_receive_period_in_days].present?
    end

    cannot_receive_events!

    #  can we send an email on Monday showing all tickets raised last week, closed last week & all tickets still outstanding?

    def check
      @sirportly = Sirportly::Client.new('a4d710d2-477f-9238-66b4-14baeccd9856', 'jnhqo8ei2s6uftoqnfp7ky6jc7lhkdeak3vjevr3gbq9ekxanu')
      content = prepare_reports
      puts "Sending mail to #{user.email}..." unless Rails.env.test?
      SystemMailer.delay.send_message(:to => "ben@atechmedia.com", :subject => options[:subject], :headline => options[:headline], :content => content)
      create_event :payload => { :report => content, :time => Time.now.to_i }
    end

    def prepare_reports
      "Tickets Raised last week: #{tickets_raised_last_week} \n" +
      "Tickets Still Open #{tickets_still_open} \n" +
      "Tickets Closed last week #{tickets_closed_last_week}"
    end

    def tickets_raised_last_week
      @sirportly.spql("SELECT COUNT FROM tickets WHERE submitted_at > 1.week.ago AND submitted_at < Time.now").results[0].first
    end

    def tickets_still_open
      @sirportly.spql("SELECT COUNT FROM tickets WHERE submitted_at > 1.week.ago AND submitted_at < Time.now AND status.name != 'Resolved' ").results[0].first
    end

    def tickets_closed_last_week
      @sirportly.spql("SELECT count FROM tickets WHERE last_update_posted_at > 1.week.ago AND status_type = 2").results[0].first
    end

  end
end