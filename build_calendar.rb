require 'date'

class SportsCalendar
  TIMES = ["12:00", "15:00", "18:00"]
  PLAY_DAYS = [5, 6, 0]
  MAX_SIMULTANEOUS_GAMES = 2

  def initialize(teams_path, start_str, end_str, output_path)
    @teams_path = teams_path
    @start_date = parse_date(start_str)
    @end_date = parse_date(end_str)
    @output_path = output_path
    @teams = []
  end

  def generate!
    validate_files
    load_teams
    
    matches = generate_round_robin
    slots = calculate_available_slots(matches.size)
    
    schedule = distribute_matches(matches, slots)
    save_calendar(schedule)
    
    puts "Готово! Составлено матчей: #{matches.size}"
    puts "Результат в файле: #{@output_path}"
  end

  private

  def parse_date(str)
    Date.strptime(str, '%d.%m.%Y')
  rescue ArgumentError, TypeError
    abort "Ошибка: Неверный формат даты '#{str}'. Ожидается ДД.ММ.ГГГГ"
  end

  def validate_files
    abort "Ошибка: Файл #{@teams_path} не найден" unless File.exist?(@teams_path)
    abort "Ошибка: Дата начала должна быть раньше даты конца" if @start_date >= @end_date
  end

  def load_teams
    # регулярка: "1. Название — Город"
    File.readlines(@teams_path, chomp: true).each do |line|
      next if line.strip.empty?
      if line =~ /^\d+\.\s*(.+?)\s*[—-]\s*(.+)$/
        @teams << { name: $1.strip, city: $2.strip }
      end
    end
    
    if @teams.size < 2
      abort "Ошибка: Не удалось распознать команды. Проверьте формат файла."
    end
  end

  def generate_round_robin
    @teams.combination(2).to_a.shuffle
  end

  def calculate_available_slots(needed_count)
    all_slots = []
    (@start_date..@end_date).each do |date|
      if PLAY_DAYS.include?(date.wday)
        TIMES.each do |time|
          MAX_SIMULTANEOUS_GAMES.times { all_slots << { date: date, time: time } }
        end
      end
    end

    if all_slots.size < needed_count
      abort "Ошибка: Недостаточно дней в периоде. Нужно #{needed_count} слотов, доступно #{all_slots.size}."
    end
    all_slots
  end

  def distribute_matches(matches, slots)
    step = slots.size.to_f / matches.size
    final_schedule = []

    matches.each_with_index do |match, i|
      slot_idx = (i * step).to_i
      slot = slots[slot_idx]
      final_schedule << {
        date: slot[:date],
        time: slot[:time],
        t1: match[0],
        t2: match[1]
      }
    end
    final_schedule.sort_by { |item| [item[:date], item[:time]] }
  end

  def save_calendar(schedule)
    File.open(@output_path, 'w:UTF-8') do |f|
      f.puts "КАЛЕНДАРЬ СПОРТИВНЫХ СОБЫТИЙ (Сезон 2026-2027)"
      f.puts "=" * 85
      f.puts sprintf("%-12s | %-6s | %-30s | %-30s", "Дата", "Время", "Хозяева (Город)", "Гости (Город)")
      f.puts "-" * 85

      schedule.each do |g|
        f.puts sprintf("%-12s | %-6s | %-30s | %-30s",
          g[:date].strftime("%d.%m.%Y"),
          g[:time],
          "#{g[:t1][:name]} (#{g[:t1][:city]})",
          "#{g[:t2][:name]} (#{g[:t2][:city]})"
        )
      end
    end
  end
end

if ARGV.size == 4
  SportsCalendar.new(ARGV[0], ARGV[1], ARGV[2], ARGV[3]).generate!
else
  puts "Запуск: ruby build_calendar.rb teams.txt 01.08.2026 01.06.2027 calendar.txt"
end