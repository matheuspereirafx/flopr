class User < ApplicationRecord
  attr_accessor :terms
  has_many :clubs, foreign_key: :owner_id, dependent: :destroy

  validates :terms,
            acceptance: {
              message: "Aceite os Termos de Serviço e a Política de Privacidade."
            }

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
