# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

[
  {
    name: "Free",
    description: "Para quem joga casualmente com amigos no fim de semana.",
    price: 0,
    billing_period: :monthly
  },
  {
    name: "Iniciante",
    description: "Para organizadores frequentes e clubes de poker locais.",
    price: 190,
    billing_period: :monthly
  },
  {
    name: "Profissional",
    description: "Para grandes etapas de circuitos, ligas regionais e clubes federados.",
    price: 290,
    billing_period: :monthly
  }
].each do |attributes|
  plan = Plan.find_or_initialize_by(name: attributes[:name])
  plan.assign_attributes(attributes.merge(active: true))
  plan.save!
end
