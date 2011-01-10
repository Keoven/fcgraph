# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

nations_directory = Dir.open(File.join(RAILS_ROOT, 'db', 'resources', 'nations'))
file_path = String.new

begin
  nations_directory.each do |file_name|
    file_path = File.join(nations_directory.path, file_name)
    next unless File.file?(file_path)

    content = File.open(file_path).read
    nation_name = content.slice(/name(\s)*=(\s)?\_\(".*"\)/).
                  slice(/".*"/).gsub('"', '')

    output = "Creating #{nation_name} Record... "
    print output

    nation = Nation.create(:name => nation_name)
    content.slice(/leader(\s)?=.*leader_sex(\s)?=/m).split(/\n/).each do |leader_name|
      next if leader_name.match(/(leader(\s)?=|leader_sex(\s)?=)/) ||
              leader_name.strip.blank? ||
              leader_name.start_with?(';')

      leader_name.gsub!(/[",(;.*)]/,'').strip!
      Leader.create(:name => leader_name, :nation => nation)
    end
    printf "%#{50 - output.length}s\n", 'DONE'
  end
rescue Exception => msg
  puts
  puts "Error Parsing #{file_path}"
  puts msg
end