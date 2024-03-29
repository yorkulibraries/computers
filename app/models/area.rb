class Area < ActiveRecord::Base
  # FIELDS: name, department, specia_access, map, notes, floor_id, location_id

  ## UPLOADER
  mount_uploader :map, MapUploader

  ## RELATIONS
  belongs_to :location
  belongs_to :floor
  has_many :computers

  ## VALIDATIONS
  validates :name, :location, :floor, presence: true

  ## SCOPES
  default_scope { where(deleted: false) } # only active areas
  scope :deleted, -> { unscoped.where(deleted: true) }

  ## METHODS

  # Attaches computers to this area by going throw a list of IPs (each ip on new line)
  def attach_computers(ip_list)
    return if ip_list == nil

    # detach computers from area first
    Computer.detach_from_area(self[:id])

    sanitized_list = ip_list.lines.collect { |ip| ip.rstrip }

    sanitized_list.each do |h|
      logger.info "Attaching hostname: #{h} to area #{self[:id]}"
      c = Computer.find_by_hostname(h)
      if c == nil
        c = Computer.where(ip: h).first_or_create(ip: h, hostname: h)
      end
      c.area = self
      c.location = self.location
      c.floor = self.floor
      c.save(validate: false)
    end
  end

end
