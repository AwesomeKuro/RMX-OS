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

# create server instance
server = RMXOS::Server.new
# optimize the database
server.connect_to_database
server.sql.optimize_database
server.sql.close

puts 'Press ENTER to continue.'
gets
puts 'Please wait...'
