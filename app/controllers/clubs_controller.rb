class ClubsController < ApplicationController
  before_action :set_club, only: %i[show edit update destroy]


  def index
    @clubs = current_user.clubs
  end

  def create
    @club = current_user.clubs.build(club_params)

    if @club.save
      redirect_to @club
    else
      render :new, status: unprocessable_entity
    end
  end

  def show
  end

  def new
    @club = Club.new
  end


  def edit
    @club = current_user.clubs.find(params[:id])
  end

  def update
    @club = current_user.clubs.find(params[:id])

    if @club.update(club_params)
      redirect_to @club, notice: "Clube atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
  end


  private

  def club_params
    params.require(:club).permit(
      :name,
      :whatsapp_contact_number,
      :logo
    )
  end

  def set_club
    @club = Club.find(params[:id])
  end

end
