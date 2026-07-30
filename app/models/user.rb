class User < ApplicationRecord
  attr_accessor :terms

  has_many :owned_clubs,
           class_name: "Club",
           foreign_key: :owner_id,
           inverse_of: :owner,
           dependent: :destroy

  has_many :club_memberships, dependent: :destroy


  validates :terms,
            acceptance: {
              message: "Aceite os Termos de Serviço e a Política de Privacidade."
            }

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
