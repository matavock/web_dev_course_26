require 'date'

begin
  teams_file, start_str, end_str, output_file = ARGV

  teams = []
  File.foreach(teams_file) do |line|
    parts = line.split('-')
    teams.push({ name: parts[0].strip, city: parts[1].strip})
  end

  start_date = Date.strptime(start_str, '%d.%m.%Y')
  end_date = Date.strptime(end_str, '%d.%m.%Y')

  matches = []
  teams.each_with_index do |team1, i|
    teams.each_with_index do |team2, j|
      matches.push({ home: team1, away: team2})
    end
  end

  slots = []
  current = start_date
  while current <= end_date
    if [5, 6, 0].include?(current.wday)
      [12, 15, 18].each do |hour|
        2.times do |slot_index|
          slots.push({ date: current, time: hour, slot_index: slot_index})
        end
      end
    end
    current += 1
  end

  calendar = []
  step = slots.length.to_f / matches.length
  matches.each_with_index do |match, index|
    idx = (index * step).to_i
    idx = slots.length - 1 if idx >= slots.length
    slot = slots[idx]
    calendar.push({ date: slot[:date], time: slot[:time], home: match[:home], away: match[:away]})
  end

  calendar.sort_by! { |g| [g[:date], g[:time]] }

  File.open(output_file, 'w') do |f|
    f.puts "Calendar"
    f.puts "-" * 40
    current_date = nil
    calendar.each do |game|
      if current_date != game[:date]
        current_date = game[:date]
        f.puts "\n#{current_date.strftime('%d.%m.%Y (%A)')}"
        f.puts "-" * 20
      end
      f.puts "#{format('%02d:00', game[:time])} | #{game[:home][:name]} (#{game[:home][:city]}) vs #{game[:away][:name]}"
    end
    f.puts "\nAmount of games: #{calendar.length}"
  end
end
