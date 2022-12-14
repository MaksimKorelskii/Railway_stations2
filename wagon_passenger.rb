class WagonPassenger < Wagon
  attr_reader :type

  def initialize(number, company, total_space)
    super(number, company, total_space)
    @type = :passenger
  end

  def take_space
    raise 'В вагоне нет свободных мест' if free_space.zero?

    self.occupied_space += 1
  end
end
