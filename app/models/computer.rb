require "ipaddress"

class Computer < ActiveRecord::Base

  ## CONSTANTS
  STAY_ALIVE_INTERVAL = Rails.application.config.stay_alive_interval # 15.minutes

  PUBLIC_USE = "public"
  STAFF_USE = "staff"

  ## RELATIONS
  belongs_to :location
  belongs_to :floor
  belongs_to :area
  belongs_to :image

  has_many :activity_entries, class_name: "ComputerActivityLog"

  ## VALIDATIONS
  #validates :ip, :presence => true, :uniqueness => true, unless: :hostname
  #validate :valid_ip, unless: :hostname

  ## SCOPES

  scope :in_use, -> { where("current_username IS NOT NULL") }
  scope :not_in_use, -> { where("current_username IS NULL") }
  scope :not_staying_active, -> { where("last_user_activity < ?", Computer::STAY_ALIVE_INTERVAL.ago) }
  scope :staying_active, -> { where("last_user_activity >= ?", Computer::STAY_ALIVE_INTERVAL.ago) }
  scope :not_pinging, -> { where("last_ping < ?", Computer::STAY_ALIVE_INTERVAL.ago) }
  scope :pinging, -> { where("last_ping >= ?", Computer::STAY_ALIVE_INTERVAL.ago) }
  scope :never_ping, -> { where("last_ping IS NULL") }
  scope :never_used, -> { where("last_user_activity IS NULL") }
  scope :unavailable, -> { pinging.in_use }
  scope :available, -> { where("id NOT IN(?)", unavailable.select(:id))}
  scope :attached_to_location, -> { where("location_id IS NOT NULL AND area_id IS NOT NULL") }

  ## CALLBACKS
  after_create :add_register_activity_entry

  ## METHODS
  def add_register_activity_entry
    record_activity_log(ComputerActivityLog::ACTION_REGISTER)
  end


  def update_hostname_if_nil(h)
    if self[:hostname] == nil
      update_attribute(:hostname, h)
    end
  end

  def self.free_inactive_computers
    self.in_use.not_staying_active.each do |pc|
      Rails.logger.info("#{pc.ip} not_staying_active => logging off")
      pc.logoff
      pc.save
      pc.record_activity_log(ComputerActivityLog::ACTION_LOGOFF_INACTIVE)
    end
  end


  def logon(username)
    if self.current_username != username
      self.current_username = username
    end
    self.stay_alive
  end

  def logoff
    self.previous_username = self.current_username unless self.current_username.nil?
    self.current_username = nil
  end

  def is_in_use
    return !self.current_username.nil?
  end

  def ping
    self.last_ping = DateTime.now
  end

  def stay_alive
    self.last_user_activity = DateTime.now
  end


  ##### Records activity log entry with a specified action
  def record_activity_log(action = ComputerActivityLog::ACTION_PING)
    ip = self[:hostname] ? self[:hostname] : self[:ip] 
    e = ComputerActivityLog.new(ip: ip, activity_date: DateTime.now)
    e.action = action
    e.computer = self
    e.username = self[:current_username]
    e.save
  end

  def self.detach_from_area(area_id)
    Computer.transaction do
      Computer.where(area_id: area_id).each do |c|
        c.location = nil
        c.area = nil
        c.floor = nil
        c.save(validate: false)
      end
    end
  end

  def self.detach_from_image(image_id)
    Computer.transaction do
      Computer.where(image_id: image_id).each do |c|
        c.image = nil
        c.save(validate: false)
      end
    end
  end

  ## PRIVATE
  private

  def valid_ip
    unless IPAddress.valid?(ip)
      errors.add(:ip, "Invalid IP address")
    end
  end


end
