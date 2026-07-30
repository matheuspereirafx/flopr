class ClubsController < ApplicationController
  before_action :set_owned_club, only: %i[edit update destroy]


  def index
    @clubs = current_user.owned_clubs
  end

  def create
    @club = current_user.owned_clubs.build(club_params)

    if create_club_with_owner_membership
      redirect_to clubs_path, notice: "Clube criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def new
    @club = Club.new
  end


 def edit
  end

  def update
    if @club.update(club_params)
      redirect_to clubs_path, notice: "Clube atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @club.destroy

    redirect_to clubs_path,
                notice: "Clube excluído com sucesso.",
                status: :see_other
  end

  private

  def set_owned_club
    @club = current_user.owned_clubs.find(params[:id])
  end

  def club_params
    params.require(:club).permit(
      :name,
      :whatsapp_contact_number
    )
  end

  def set_club
    @club = Club.find(params[:id])
  end

  def create_club_with_owner_membership
  ActiveRecord::Base.transaction do
    @club.save!

    @club.club_memberships.create!(
      user: current_user,
      role: :owner
    )
  end

  true
  rescue ActiveRecord::RecordInvalid
    false
  end


end
