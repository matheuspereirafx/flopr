require "test_helper"

class AsaasCustomerTest < ActiveSupport::TestCase
  class GatewayStub
    attr_reader :calls

    def initialize(response)
      @response = response
      @calls = []
    end

    def create_customer(user)
      @calls << user
      @response
    end
  end

  test "reuses the Asaas customer already linked to the user" do
    user = build_user(cpf: "52998224725", asaas_customer_id: "cus_existing")
    gateway = GatewayStub.new({})

    customer = AsaasCustomer.find_or_create_for(user, gateway: gateway)

    assert_equal "cus_existing", customer[:id]
    assert_empty gateway.calls
  end

  test "creates and returns an Asaas customer when the user has no link" do
    user = build_user(cpf: "52998224725")
    gateway = GatewayStub.new(id: "cus_new")

    customer = AsaasCustomer.find_or_create_for(user, gateway: gateway)

    assert_equal "cus_new", customer[:id]
    assert_equal "cus_new", user.asaas_customer_id
    assert_equal [user], gateway.calls
  end

  test "does not create an Asaas customer without a valid CPF" do
    user = build_user(cpf: "12345678900")

    assert_raises(AsaasCustomer::InvalidCustomer) do
      AsaasCustomer.find_or_create_for(user, gateway: GatewayStub.new({}))
    end
  end

  private

  def build_user(**attributes)
    User.new(
      {
        username: "asaas.customer",
        name: "Asaas Customer",
        email: "asaas-customer@example.com",
        password: "password123"
      }.merge(attributes)
    )
  end
end
