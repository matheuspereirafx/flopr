class Tournament < ApplicationRecord
  MINIMUM_BLIND_LEVELS = 5

  attr_accessor :blind_levels_count

  belongs_to :club

  has_many :blind_levels,
           -> { order(:level) },
           dependent: :destroy

  has_many :charge_options,
           class_name: "TournamentChargeOption",
           dependent: :destroy

  accepts_nested_attributes_for :blind_levels,
                                allow_destroy: true

  enum :status, {
    draft: "draft",
    posted: "posted",
    finished: "finished"
  }

  validates :name,
            presence: true,
            uniqueness: { case_sensitive: false }
  validates :location, :max_players, :starts_at, :status, presence: true

  validate :has_minimum_blind_levels
  validate :blind_levels_are_sequential
  validate :blind_levels_have_same_duration
  validate :blind_levels_count_matches_structure
  validate :has_required_charge_options, if: :posted?
  validate :double_rebuy_requires_rebuy, if: :posted?
  validate :active_charge_options_have_valid_period, if: :posted?

  before_validation :renumber_blind_levels

  private

  def active_blind_levels
    blind_levels.reject(&:marked_for_destruction?)
  end

  def has_minimum_blind_levels
    return if active_blind_levels.size >= MINIMUM_BLIND_LEVELS

    errors.add(
      :blind_levels,
      "deve possuir no mínimo #{MINIMUM_BLIND_LEVELS} níveis"
    )
  end

  def blind_levels_are_sequential
    levels = active_blind_levels.map(&:level)

    return if levels == (1..active_blind_levels.size).to_a

    errors.add(:blind_levels, "devem estar numerados sequencialmente")
  end

  def blind_levels_have_same_duration
    durations = active_blind_levels.map(&:duration_minutes).uniq

    return if durations.size <= 1

    errors.add(:blind_levels, "devem possuir a mesma duração")
  end

  def blind_levels_count_matches_structure
    return if blind_levels_count.blank?
    return if blind_levels_count.to_i == active_blind_levels.size

    errors.add(
      :blind_levels_count,
      "deve ser igual à quantidade de níveis configurados"
    )
  end

  def renumber_blind_levels
    active_blind_levels.each_with_index do |blind_level, index|
      blind_level.level = index + 1
    end
  end

  def has_required_charge_options
    return if charge_option_for("buy_in")&.active?

    errors.add(:base, "buy-in deve estar configurado")
  end

  def double_rebuy_requires_rebuy
    double_rebuy = charge_option_for("double_rebuy")
    return unless double_rebuy&.active?
    return if charge_option_for("rebuy")&.active?

    errors.add(:base, "rebuy duplo exige o rebuy habilitado")
  end

  def active_charge_options_have_valid_period
    period_options = %w[rebuy double_rebuy fee].filter_map do |kind|
      option = charge_option_for(kind)
      option if option&.active?
    end

    period_options.each do |option|
      next if option.available_from_level == blind_levels.first &&
              option.available_until_level.present?

      errors.add(:base, "#{charge_option_label(option.kind)} deve ter um período de disponibilidade válido")
    end

    period_end_levels = period_options.map(&:available_until_level).compact.uniq
    if period_end_levels.many?
      errors.add(:base, "as recargas devem compartilhar o mesmo nível final")
    end

    addon = charge_option_for("addon")
    return unless addon&.active?
    return if addon.available_from_level.present? &&
              addon.available_until_level.blank? &&
              (period_end_levels.empty? || period_end_levels.one? && addon.available_from_level == period_end_levels.first)

    errors.add(:base, "add-on deve ter um período de liberação válido")
  end

  def charge_option_for(kind)
    charge_options.find { |option| option.kind == kind }
  end

  def charge_option_label(kind)
    {
      "buy_in" => "buy-in",
      "rebuy" => "rebuy",
      "double_rebuy" => "rebuy duplo",
      "addon" => "add-on",
      "fee" => "taxa extra"
    }.fetch(kind)
  end
end
