class TournamentPrizePoolsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_member_club
  before_action :authorize_configuration!
  before_action :set_tournament
  before_action :set_prize_pool, only: %i[edit update]

  def new
    @prize_pool = @tournament.build_prize_pool
    @prize_pool.prize_positions.build(position: 1)
  end

  def create
    @prize_pool = @tournament.build_prize_pool(prize_pool_params)

    if @prize_pool.save
      redirect_to club_tournament_path(@club, @tournament), notice: "Premiação do torneio salva com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @prize_pool.update(prize_pool_params)
      redirect_to club_tournament_path(@club, @tournament), notice: "Premiação do torneio atualizada com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_member_club
    @club = current_user.clubs.find(params[:club_id])
    @current_membership = @club.club_memberships.find_by!(user: current_user)
  rescue ActiveRecord::RecordNotFound
    render plain: "Not found", status: :not_found
  end

  def authorize_configuration!
    return if performed?
    return if @current_membership.owner? || @current_membership.admin?

    render plain: "Forbidden", status: :forbidden
  end

  def set_tournament
    return if performed?
    @tournament = @club.tournaments.find(params[:tournament_id])
  rescue ActiveRecord::RecordNotFound
    render plain: "Not found", status: :not_found
  end

  def set_prize_pool
    return if performed?
    @prize_pool = @tournament.prize_pool
    return if @prize_pool.present?

    redirect_to new_club_tournament_prize_pool_path(@club, @tournament)
  end

  def prize_pool_params
    params.require(:prize_pool).permit(
      :total_amount,
      prize_positions_attributes: %i[id position percentage _destroy]
    )
  end
end
