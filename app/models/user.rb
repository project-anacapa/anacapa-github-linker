class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :trackable, :validatable,
         :omniauthable, :omniauth_providers => [:github]
  
  has_and_belongs_to_many :courses
  has_many :roster_students

  # install rolify
  rolify
  after_create :assign_default_role

  delegate :can?, :cannot?, :to => :ability

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.name = auth.info.name
      user.username = auth.info.nickname
      user.password = Devise.friendly_token[0,20]
      user.uid = auth.uid
      user.provider = auth.provider
      # If you are using confirmable and the provider(s) you use validate emails, 
      # uncomment the line below to skip the confirmation emails.
      # user.skip_confirmation!
    end
  end

  def assign_default_role
    # rolify uses this to initally assign user roles.
    if self.id == 1 then
      puts "This is the first user... they should be automatically made an admin..."
      self.add_role(:admin)
    end

    self.add_role(:user) if self.roles.blank?
  end

  def ability
    @ability ||= Ability.new(self)
  end


end
