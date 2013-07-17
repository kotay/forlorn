require 'serialize_and_symbolize'
require 'assignable_types'
require 'markdown_class_attributes'
require 'utils'

class Gentleman < ActiveRecord::Base
  include SerializeAndSymbolize
  include AssignableTypes
  include MarkdownClassAttributes

  serialize_and_symbolize :options, :memory
  markdown_class_attributes :description, :event_description

  load_types_in "Gentlemen"

  SCHEDULES = %w[every_2m every_5m every_10m every_30m every_1h every_2h every_5h every_12h every_1d every_2d every_7d
                 midnight 1am 2am 3am 4am 5am 6am 7am 8am 9am 10am 11am noon 1pm 2pm 3pm 4pm 5pm 6pm 7pm 8pm 9pm 10pm 11pm]

  attr_accessible :options, :memory, :name, :type, :schedule, :source_ids

  validates_presence_of :name, :user
  validate :sources_are_owned
  validate :validate_schedule

  after_initialize :set_default_schedule
  before_validation :set_default_schedule
  before_validation :unschedule_if_cannot_schedule
  before_save :unschedule_if_cannot_schedule

  belongs_to :user, :inverse_of => :gentlemen
  has_many :events, :dependent => :delete_all, :inverse_of => :gentleman, :order => "events.id desc"
  has_many :received_events, :through => :sources, :class_name => "Event", :source => :events, :order => "events.id desc"
  has_many :links_as_source, :dependent => :delete_all, :foreign_key => "source_id", :class_name => "Link", :inverse_of => :source
  has_many :links_as_receiver, :dependent => :delete_all, :foreign_key => "receiver_id", :class_name => "Link", :inverse_of => :receiver
  has_many :sources, :through => :links_as_receiver, :class_name => "Gentleman", :inverse_of => :receivers
  has_many :receivers, :through => :links_as_source, :class_name => "Gentleman", :inverse_of => :sources

  scope :of_type, lambda { |type|
    type = case type
             when String, Symbol, Class
               type.to_s
             when Gentleman
               type.class.to_s
             else
               type.to_s
           end
    where(:type => type)
  }

  def check
    # Implement me in your subclass of Gentleman.
  end

  def default_options
    # Implement me in your subclass of Gentleman.
    {}
  end

  def receive(events)
    # Implement me in your subclass of Gentleman.
  end

  # Implement me in your subclass to decide if your Gentleman is working.
  def working?
    raise "Implement me in your subclass"
  end

  def receive_webhook(params)
    ["not implemented", 404]
  end

  def trigger_webhook(params)
    receive_webhook(params).tap do
      self.last_webhook_at = Time.now
      save!
    end
  end

  def event_created_within(seconds)
    last_event = events.first
    last_event && last_event.created_at > seconds.ago && last_event
  end

  def sources_are_owned
    errors.add(:sources, "must be owned by you") unless sources.all? {|s| s.user == user }
  end

  def create_event(attrs)
    events.create!({ :user => user }.merge(attrs))
  end

  def validate_schedule
    unless cannot_be_scheduled?
      errors.add(:schedule, "is not a valid schedule") unless SCHEDULES.include?(schedule.to_s)
    end
  end

  def make_message(payload, message = options[:message])
    message.gsub(/<([^>]+)>/) { Utils.value_at(payload, $1) || "??" }
  end

  def set_default_schedule
    self.schedule = default_schedule unless schedule.present? || cannot_be_scheduled?
  end

  def unschedule_if_cannot_schedule
    self.schedule = nil if cannot_be_scheduled?
  end

  def last_event_at
    @memoized_last_event_at ||= events.select(:created_at).first.try(:created_at)
  end

  def default_schedule
    self.class.default_schedule
  end

  def cannot_be_scheduled?
    self.class.cannot_be_scheduled?
  end

  def can_be_scheduled?
    !cannot_be_scheduled?
  end

  def cannot_receive_events?
    self.class.cannot_receive_events?
  end

  def can_receive_events?
    !cannot_receive_events?
  end

  # Class Methods
  class << self
    def cannot_be_scheduled!
      @cannot_be_scheduled = true
    end

    def cannot_be_scheduled?
      !!@cannot_be_scheduled
    end

    def default_schedule(schedule = nil)
      @default_schedule = schedule unless schedule.nil?
      @default_schedule
    end

    def cannot_receive_events!
      @cannot_receive_events = true
    end

    def cannot_receive_events?
      !!@cannot_receive_events
    end

    def receive!
      sql = Gentleman.
              select("gentlemen.id AS receiver_gentleman_id, sources.id AS source_gentleman_id, events.id AS event_id").
              joins("JOIN links ON (links.receiver_id = gentlemen.id)").
              joins("JOIN gentlemen AS sources ON (links.source_id = sources.id)").
              joins("JOIN events ON (events.gentlemen_id = sources.id)").
              where("gentlemen.last_checked_event_id IS NULL OR events.id > gentlemen.last_checked_event_id").to_sql

      gentlemen_to_events = {}
      Gentleman.connection.select_rows(sql).each do |receiver_gentleman_id, source_gentleman_id, event_id|
        gentlemen_to_events[receiver_gentleman_id] ||= []
        gentlemen_to_events[receiver_gentleman_id] << event_id
      end

      event_ids = gentlemen_to_events.values.flatten.uniq.compact

      Gentleman.where(:id => gentlemen_to_events.keys).each do |gentleman|
        gentleman.update_attribute :last_checked_event_id, event_ids.max
        Gentleman.async_receive(gentleman.id, gentlemen_to_events[gentleman.id].uniq)
      end

      {
          :gentleman_count => gentlemen_to_events.keys.length,
          :event_count => event_ids.length
      }
    end

    # Given an Gentleman id and an array of Event ids, load the Gentleman, call #receive on it with the Event objects, and then
    # save it with an updated _last_receive_at_ timestamp.
    #
    # This method is tagged with _handle_asynchronously_ and will be delayed and run with delayed_job.  It accepts Gentleman
    # and Event ids instead of a literal ActiveRecord models because it is preferable to serialize delayed_jobs with ids.
    def async_receive(gentleman_id, event_ids)
      gent = Gentleman.find(gentleman_id)
      gent.receive(Event.where(:id => event_ids))
      gent.last_receive_at = Time.now
      gent.save!
    end
    handle_asynchronously :async_receive

    def run_schedule(schedule)
      types = where(:schedule => schedule).group(:type).pluck(:type)
      types.each do |type|
        type.constantize.bulk_check(schedule)
      end
    end

    # You can override this to define a custom bulk_check for your type of Gentleman.
    def bulk_check(schedule)
      raise "Call #bulk_check on the appropriate subclass of Gentleman" if self == Gentleman
      where(:schedule => schedule).pluck("gentlemen.id").each do |gentleman_id|
        async_check(gentleman_id)
      end
    end

    # Given an Gentleman id, load the Gentleman, call #check on it, and then save it with an updated _last_check_at_ timestamp.
    #
    # This method is tagged with _handle_asynchronously_ and will be delayed and run with delayed_job.  It accepts an Gentleman
    # id instead of a literal Gentleman because it is preferable to serialize delayed_jobs with ids.
    def async_check(gentleman_id)
      gent = Gentleman.find(gentleman_id)
      gent.check
      gent.last_check_at = Time.now
      gent.save!
    end
    handle_asynchronously :async_check
  end
end
