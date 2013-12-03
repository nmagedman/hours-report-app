class User < ActiveRecord::Base

  has_many :timesheets
  has_many :reports, :through => :timesheets

  scope :active_users, -> { where(status: "active") }

  after_create :join_current_report, :if => "current_report"

  validates_uniqueness_of :uid, scope: :provider

  def self.from_auth(auth)
    where(provider: auth["provider"], uid: auth["uid"]).first
  end

  def self.create_from_auth(auth)
    new({
      uid:           auth["uid"],
      provider:      auth["provider"],
      refresh_token: auth["credentials"]["refresh_token"],
      access_token:  auth["credentials"]["token"],
      expires:       auth["credentials"]["expires_at"],
      first_name:    auth["info"]["first_name"],
      last_name:     auth["info"]["last_name"],
      image:         auth["info"]["image"],
      email:         auth["info"]["email"]
    })
  end

  def name
    "#{first_name} #{last_name}"
  end

  def current_timesheet
    current_report.timesheets.find_by(:user_id => id) if current_report
  end

  private

  def join_current_report
    current_report.add_new_user(self)
  end

  def current_report
    Report.current_report
  end
end
