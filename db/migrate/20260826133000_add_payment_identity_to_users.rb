class AddPaymentIdentityToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :cpf, :string
    add_column :users, :asaas_customer_id, :string

    add_index :users, :cpf, unique: true, where: "cpf IS NOT NULL"
    add_index :users, :asaas_customer_id, unique: true, where: "asaas_customer_id IS NOT NULL"
  end
end
