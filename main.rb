require_relative 'accessors'
require_relative 'validation'
require_relative 'instance_counter'
require_relative 'company'
require_relative 'wagon'
require_relative 'train'
require_relative 'route'
require_relative 'train_passenger'
require_relative 'train_cargo'
require_relative 'wagon_cargo'
require_relative 'wagon_passenger'
require_relative 'station'

class Main
  MENU = [
    { id: 0, title: 'выйти из приложения', action: :exit },
    { id: 1, title: 'создать станцию', action: :new_station },
    { id: 2, title: 'создать поезд', action: :new_train },
    { id: 3, title: 'создать маршрут', action: :new_route },
    { id: 4, title: 'добавить станцию  в маршрут', action: :add_station },
    { id: 5, title: 'удалить станцию из маршрута', action: :delete_station },
    { id: 6, title: 'назначить маршрут поезду', action: :set_route },
    { id: 7, title: 'прицепить вагон к поезду', action: :add_wagon },
    { id: 8, title: 'отцепить вагон от поезда', action: :delete_wagon },
    { id: 9, title: 'переместить поезд вперед', action: :move_forward },
    { id: 10, title: 'переместить поезд назад', action: :move_back },
    { id: 11, title: 'показать станции на маршруте', action: :list_stations },
    { id: 12, title: 'показать список поездов на станции', action: :list_trains_on_station },
    { id: 13, title: 'показать список вагонов у поезда', action: :wagons_list },
    { id: 14, title: 'занять место/объём в вагоне', action: :take_spaces }
  ].freeze

  def initialize
    @stations = []
    @trains = []
    @routes = []
  end

  def start_menu
    puts
    puts 'МЕНЮ:'
    MENU.each do |item|
      puts "#{item[:id]} - #{item[:title]}"
    end
  end

  def program
    loop do
      start_menu
      puts
      print 'Выберите действие и введите соответствующую цифру: '
      choice = gets.chomp.to_i
      break if choice.zero?

      puts
      send(MENU[choice][:action])
    end
  end

  # создавать станции
  def new_station
    name = ask('Введите название станции')
    @stations << Station.new(name)
    puts "Станция #{name} успешно создана."
  rescue RuntimeError => e
    puts e.message
    retry
  end

  # создавать поезда
  def new_train
    id = ask('Введите номер поезда, согласно формату ххх-хх')
    type = ask_symbol('Введите тип поезда: passenger или cargo')
    company = ask('Введите название производителя поезда')
    @trains << if type == :passenger
                 TrainPassenger.new(id, type, company)
               else
                 TrainCargo.new(id, type, company) # любой некорретный тип уходит сюда
               end
    puts "#{type.capitalize} поезд #{id} успешно создан. Производитель: #{company}."
  rescue RuntimeError => e
    puts e.message
    retry
  end

  # создавать маршруты и управлять станциями в нем (добавлять, удалять)
  def new_route
    start_station = ask('Введите начало маршрута')
    finish_station = ask('Введите конец маршрута')
    @routes << Route.new(find_station(start_station), find_station(finish_station))
    puts "Маршрут с начальной станцией #{start_station} и конечной станцией #{finish_station} успешно создан."
  rescue RuntimeError => e
    puts e.message
    retry
  end

  def add_station
    station = ask('Введите название станции')
    start_station = ask('Введите начало маршрута')
    finish_station = ask('Введите конец маршрута')
    route(start_station, finish_station).add_new_station(find_station(station))
  end

  def delete_station
    station = ask('Введите название станции')
    start_station = ask('Введите начало маршрута')
    finish_station = ask('Введите конец маршрута')
    route(start_station, finish_station).delete_station(find_station(station))
  end

  # назначать маршрут поезду
  def set_route
    start_station = ask('Введите начало маршрута')
    finish_station = ask('Введите конец маршрута')
    id = ask('Введите номер поезда')
    train(id).take_route(route(start_station, finish_station))
    find_station(start_station).take_train(train(id))
  end

  # добавлять вагоны к поезду
  def add_wagon
    number = ask('Введите номер вагона')
    wagon_type = ask_symbol('Введите тип вагона: passenger или cargo')
    company = ask('Введите название производителя вагона')
    case wagon_type
    when :passenger
      total_space = ask_integer('Введите количество мест в вагоне')
      wagon = WagonPassenger.new(number, company, total_space)
    when :cargo
      total_space = ask_integer('Введите объём грузового вагона')
      wagon = WagonCargo.new(number, company, total_space)
    end
    id = ask('Введите номер поезда, к которому нужно прицепить вагон')
    train(id).add_wagon(wagon)
    puts "#{wagon_type.capitalize} вагон #{number}, производителя #{company} успешно создан. " \
         "Вагон прицеплён к поезду #{id}."
  rescue RuntimeError => e
    puts e.message
    retry
  end

  # отцеплять вагоны от поезда
  def delete_wagon
    number = ask('Введите номер вагона')
    id = ask('Введите номер поезда, от которого нужно отцепить вагон')
    train(id).delete_wagon(wagon_of_train(id, number))
  end

  # перемещать поезд по маршруту вперед и назад
  def move_forward
    id = ask('Введите номер поезда')
    train(id).forward
    train(id).current_station.take_train(train(id))
    train(id).previous_station.send_train(train(id))
  end

  def move_back
    id = ask('Введите номер поезда')
    train(id).back
    train(id).current_station.take_train(train(id))
    train(id).previous_station.send_train(train(id))
  end

  # просматривать список станций
  def list_stations
    start_station = ask('Введите начало маршрута')
    finish_station = ask('Введите конец маршрута')
    route(start_station, finish_station).show_route
  end

  def list_trains_on_station
    station_name = ask('Введите название станции')
    find_station(station_name).trains_on_station do |train|
      puts "#{train.type.capitalize} поезд #{train.id}, количество вагонов: #{train.amount_of_wagons}"
    end
  end

  # показать список вагонов у поезда
  def wagons_list
    id = ask('Введите номер поезда')
    train(id).wagons_of_train do |wagon|
      if wagon.type == :passenger
        puts "#{wagon.type.capitalize} вагон #{wagon.number}, " \
             "количество свободных мест: #{wagon.free_space}, " \
             "количество занятых мест: #{wagon.occupied_space}."
      else
        puts "#{wagon.type.capitalize} вагон #{wagon.number}, " \
             "количество свободного объёма: #{wagon.free_space}, " \
             "количество занятого объёма: #{wagon.occupied_space}."
      end
    end
  end

  def take_spaces
    id = ask('Введите номер поезда')
    number = ask('Введите номер вагона')
    if train(id).type == :passenger
      wagon_of_train(id, number).take_space
      puts "Вы заняли одно место в вагоне #{number} поезда #{id}. " \
           "Всего мест #{wagon_of_train(id, number).total_space}, " \
           "свободно #{wagon_of_train(id, number).free_space}."
    else
      puts "Объём вагона: #{wagon_of_train(id, number).total_space}, " \
           "свободно: #{wagon_of_train(id, number).free_space}."
      volume = ask_integer('Введите объём загрузки')
      wagon_of_train(id, number).take_space(volume)
      puts "Вы загрузили #{volume} в вагон #{number} поезда #{id}."
    end
  rescue RuntimeError => e
    puts e.message
    retry
  end

  private

  def ask(question)
    puts question
    gets.chomp
  end

  def ask_symbol(question)
    puts question
    gets.chomp.to_sym
  end

  def ask_integer(question)
    puts question
    gets.chomp.to_i
  end

  def find_station(station)
    @stations.find { |item| item.name == station }
  end

  def route(start_station, finish_station)
    @routes.find { |route| route.first_station.name == start_station && route.last_station.name == finish_station }
  end

  # поиск поезда по его номеру
  def train(id)
    @trains.find { |train| train.id == id }
  end

  def wagon_of_train(id, number)
    train(id).wagons.find { |wagon| wagon.number == number }
  end
end

Main.new.program
