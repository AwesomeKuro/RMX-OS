Dir.chdir('..')

begin
	load 'src/Data.rb'
	load 'src/Debug.rb'
	load 'src/Error.rb'
rescue SyntaxError
	puts $!.message
	gets
	exit
end

# loading settings
begin
	load './cfg.ini'
rescue SyntaxError
	puts RMXOS::Error::ConfigFile
	puts RMXOS::Data::PressEnter
	gets
	exit
end

RUBY_VERSION =~ /(\d+.\d+)/
version = $1
# following errors can happen even before RMX-OS was initialized properly
if !File.directory?("./bin/#{version}") # Ruby version unsupported
	puts RMXOS::Data.args(RMXOS::Error::WrongRubyVersion_VERSION, {'VERSION' => RUBY_VERSION})
	gets
	exit
end

# loading classes
begin
	load 'src/Options.rb'
	load 'src/Server.rb'
	load 'src/SQL.rb'
rescue SyntaxError
	puts $!.message
	gets
	exit
end

# loading external libraries
require "./bin/#{version}/mysql_api"

server = RMXOS::Server.new
server.connect_to_database

puts '> Extracting IPs...'
check = server.sql.query("SELECT users.username AS 'username', ips.ip AS 'ip' FROM users JOIN ips ON users.user_id = ips.user_id")
matches = {}
ips = {}
check.num_rows.times {
	hash = check.fetch_hash
	username = hash['username']
	ip = hash['ip']
	ips[username] = [] if !ips.has_key?(username)
	matches[ip] = [] if !matches.has_key?(ip)
	ips[username].push(ip)
	matches[ip].push(username)
}
puts '> Closing database connection...'
server.sql.close

# remove duplicate entries
ips.each_key {|key| ips[key] |= ips[key]}
matches.each_key {|key| matches[key] |= matches[key]}
puts ''

keys = ips.keys.sort
keys.each_index {|i|
	# show 10 users "per page"
	if i % 10 == 0 && i != 0
		puts 'Press ENTER for the next 10 users.'
		gets
	end
	username = keys[i]
	puts "- #{username}"
	puts "    used IP addresses:"
	matching = []
	ips[username].each {|ip|
		matching += matches[ip]
		puts "      #{ip}"
	}
	matching |= matching
	matching.delete(username)
	if matching.size > 0
		puts "    other users with same IP:"
		matching.each {|name| puts "      #{name}"}
	end
	2.times {puts ''}
}

puts 'Press ENTER to continue.'
gets
puts 'Please wait...'
