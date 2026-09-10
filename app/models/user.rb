class User < ApplicationRecord
  attribute :terms, :boolean, default: false

  has_many :club_memberships, dependent: :destroy
  has_many :tournament_registrations, dependent: :destroy

  has_many :recorded_registration_payments,
           class_name: "RegistrationPayment",
           foreign_key: :recorded_by_id,
           dependent: :restrict_with_exception

  has_many :clubs,
           through: :club_memberships

  has_many :owner_club_memberships,
           -> { where(role: "owner") },
           class_name: "ClubMembership"

  has_many :owned_clubs,
           through: :owner_club_memberships,
           source: :club

  validates :username, presence: true, on: :create, unless: :profile_incomplete?
  validates :name, :username, presence: true, if: :google_profile_completed?
  validates :username,
            format: { with: /\A[a-zA-Z0-9_.]+\z/, allow_nil: true },
            uniqueness: { allow_nil: true }
  validate :cpf_must_be_valid, if: -> { cpf.present? }
  validates :cpf, uniqueness: true, allow_blank: true

  before_validation :normalize_cpf

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  def profile_incomplete?
    provider == "google_oauth2" && profile_completed_at.nil?
  end

  class << self
    def from_google_oauth!(auth)
      provider = auth.fetch("provider")
      uid = auth.fetch("uid")
      email = auth.dig("info", "email").to_s.downcase

      validate_google_auth!(auth, email)

      find_by(provider: provider, uid: uid) || transaction do
        find_or_create_from_google_auth!(provider:, uid:, email:)
      end
    end

    private

    def validate_google_auth!(auth, email)
      raise ArgumentError, "O Google não retornou um e-mail válido." if email.blank?
      raise ArgumentError, "O e-mail do Google precisa ser verificado." unless google_email_verified?(auth)
    end

    def find_or_create_from_google_auth!(provider:, uid:, email:)
      user = find_by(email: email)
      return create!(email:, provider:, uid:, password: Devise.friendly_token.first(32)) unless user

      raise ArgumentError, "Esta conta já está vinculada a outro login Google." if user.provider.present?

      user.update!(provider:, uid:)
      user
    end

    def google_email_verified?(auth)
      auth.dig("extra", "raw_info", "email_verified") == true ||
        auth.dig("info", "email_verified") == true
    end
  end

  private

  def google_profile_completed?
    provider == "google_oauth2" && profile_completed_at.present?
  end

  def normalize_cpf
    self.cpf = cpf.to_s.gsub(/\D/, "") if cpf.present?
  end

  def cpf_must_be_valid
    digits = cpf.to_s
    invalid = digits.length != 11 || digits.chars.uniq.one?
    invalid ||= cpf_digit(digits.first(9)) != digits[9].to_i
    invalid ||= cpf_digit(digits.first(10)) != digits[10].to_i
    errors.add(:cpf, "não é válido") if invalid
  end

  def cpf_digit(digits)
    factor = digits.length + 1
    remainder = digits.chars.sum { |digit| digit.to_i * factor.tap { factor -= 1 } } % 11
    remainder < 2 ? 0 : 11 - remainder
  end
end
