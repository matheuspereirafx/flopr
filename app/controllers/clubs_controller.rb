class ClubsController < ApplicationController
  before_action :set_member_club, only: :show
  before_action :set_owned_club, only: %i[edit update destroy]

  def index
    @clubs = current_user.owned_clubs
  end

  def show
    @tournaments = @club.tournaments.includes(:charge_options).order(starts_at: :asc)
    @confirmed_registrations_by_tournament = confirmed_registrations_by_tournament
  end

  def new
    @club = Club.new
  end

  def create
    @club = Club.new(club_params)

    if create_club_with_owner_membership
      redirect_to clubs_path, notice: "Clube criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
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

  def set_member_club
    @club = current_user.clubs.find(params[:id])
    @current_membership = @club.club_memberships.find_by!(user: current_user)
  end

  def set_owned_club
    @club = current_user.owned_clubs.find(params[:id])
  end

  def club_params
    params.require(:club).permit(
      :name,
      :whatsapp_contact_number
    )
  end

  def create_club_with_owner_membership
    ActiveRecord::Base.transaction do
      @club.save!
      # Esta criando o membership com id do club, id user e passando ja um role .
      @club.club_memberships.create!(
        user: current_user,
        role: :owner
      )
    end

    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def confirmed_registrations_by_tournament
    TournamentRegistration.confirmed
                          .where(tournament_id: @tournaments.select(:id))
                          .group(:tournament_id)
                          .count
  end
end
