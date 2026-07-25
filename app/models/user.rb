class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  attr_accessor :terms

  validates :terms,
            acceptance: {
              message: "Aceite os Termos de Serviço e a Política de Privacidade."
            }

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
