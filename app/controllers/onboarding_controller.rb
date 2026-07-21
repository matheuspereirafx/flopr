class OnboardingController < ApplicationController
  skip_before_action :authenticate_user!, only: [:access]
  def access
  end
end
