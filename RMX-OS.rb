RMXOS_VERSION = 2.05

begin
	load 'src/Data.rb'
	load 'src/Debug.rb'
	load 'src/Error.rb'
	load 'src/Result.rb'
	load 'src/Misc.rb'
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

# in case somebody messed up the config of extensions
EXTENSIONS.compact!

RUBY_VERSION =~ /(\d+.\d+)/
version = $1
# following errors can happen even before RMX-OS was initialized properly
if !File.directory?("./bin/#{version}") # Ruby version unsupported
	puts RMXOS::Data.args(RMXOS::Error::WrongRubyVersion_VERSION, {'VERSION' => RUBY_VERSION})
	gets
	exit
end
if NAME == nil || NAME == '' # game name not defined
	puts RMXOS::Error::GameUndefined
	gets
	exit
end

# loading classes
begin
	load 'src/Action.rb'
	load 'src/ActionPending.rb'
	load 'src/ActionSent.rb'
	load 'src/ActionHandler1.rb'
	load 'src/ActionHandler2.rb'
	load 'src/ActionHandler3.rb'
	load 'src/ActionHandler4.rb'
	load 'src/ActionHandler5.rb'
	load 'src/ActionHandler6.rb'
	load 'src/ClientHandler.rb'
	load 'src/Client1.rb'
	load 'src/Client2.rb'
	load 'src/Client3.rb'
	load 'src/Client4.rb'
	load 'src/Options.rb'
	load 'src/Player.rb'
	load 'src/Sender.rb'
	load 'src/Server.rb'
	load 'src/SQL.rb'
rescue SyntaxError
	puts $!.message
	gets
	exit
end

# loading Ruby's libraries
require 'socket'
# loading external libraries
require "./bin/#{version}/mysql_api"

#==========================================================================
# module RMXOS
#--------------------------------------------------------------------------
# This is the container for RMXOS.
#==========================================================================

module RMXOS
	
	# Logging files
	Logs = {}
	Logs['Error'] = 'logs/errors.log'
	Logs['Incoming Message'] = 'logs/messages.log'
	Logs['Outgoing Message'] = 'logs/messages.log'
	Logs['Action'] = 'logs/actions.log'
	Logs['Extension'] = 'logs/extension_errors.log'
	Logs['Debug'] = 'logs/debug.log'
	# misc variables
	@log_mutex = nil
	@clients = nil
	#----------------------------------------------------------------------
	# RMX-OS Main Loop.
	#----------------------------------------------------------------------
	def self.main
		while true
			# clear clients
			@clients = ClientHandler.new
			@log_mutex = Mutex.new
			Client.reset
			ActionHandler.reset
			Sender.reset
			begin
				# try to create a server
				@server = Server.new
				# try to start it
				@server.start
				# try to keep it running
				@server.run
			rescue Interrupt
				@server.shutdown rescue nil
				@server.execute_shutdown rescue nil
				return
			rescue
				# error during server start or while running
				puts RMXOS::Error::UnexpectedError
				puts RMXOS.get_error
			end
			@server.shutdown rescue nil
			@server.force_shutdown rescue nil
			# stop everything if no auto-restart
			break if !AUTO_RESTART
			# wait for N seconds
			print RMXOS::Data::Restart
			(0...RESTART_TIME).each {|i|
				print " #{RESTART_TIME - i}"
				sleep(1)
			}
			puts "\n\n"
			@extensions.each_value {|ext| ext.initialize}
		end
	end
	#----------------------------------------------------------------------
	# Gets all extensions.
	#----------------------------------------------------------------------
	def self.extensions
		return @extensions
	end
	#----------------------------------------------------------------------
	# Gets the currently running Server instance.
	# Returns: Server Instance.
	#----------------------------------------------------------------------
	def self.server
		return @server
	end
	#----------------------------------------------------------------------
	# Gets the current client handler instance.
	# Returns: ClientHandler Instance.
	#----------------------------------------------------------------------
	def self.clients
		return @clients
	end
	#----------------------------------------------------------------------
	# Loads all extensions.
	#----------------------------------------------------------------------
	def self.load_extensions
		@extensions = {}
		puts RMXOS::Data::ExtensionsLoading
		# if there are any extensions defined
		if EXTENSIONS.size > 0
			# for every extension filename
			EXTENSIONS.each {|file|
				file += '.rb' if file[file.size - 3, 3] != '.rb'
				filepath = "./Extensions/#{file}"
				begin
					# try to load the file
					require filepath
					# try to load the actual extension
					extension = self.load_current_extension
					# if version is ok
					if RMXOS_VERSION >= extension::RMXOS_VERSION
						# try to activate it
						extension.initialize
						# try to load the actual extension
						@extensions[file] = extension
						puts RMXOS::Data.args(RMXOS::Data::ExtensionLoaded_FILE_VERSION, {'FILE' => file, 'VERSION' => @extensions[file]::VERSION.to_s})
					else
						# version error
						puts RMXOS::Data.args(RMXOS::Error::ExtensionVersionError_FILE_VERSION, {'FILE' => file, 'VERSION' => extension::RMXOS_VERSION.to_s})
					end
				rescue SyntaxError
					puts RMXOS::Data.args(RMXOS::Error::ExtensionLoadError_FILE, {'FILE' => file})
					puts $!.message
				rescue Errno::ENOENT
					puts RMXOS::Data.args(RMXOS::Error::ExtensionFileNotFound_FILE, {'FILE' => file})
				rescue
					puts RMXOS::Data.args(RMXOS::Error::ExtensionInitError_FILE, {'FILE' => file})
					puts RMXOS.get_error
				end
			}
		else
			puts RMXOS::Data::NoExtensions
		end
	end
	#----------------------------------------------------------------------
	# Gets a string representing the time for SQL queries.
	#  time - Time instance
	# Returns: String in SQL time format.
	#----------------------------------------------------------------------
	def self.get_sqltime(time)
		return time.strftime('%Y-%m-%d %H-%M-%S')
	end
	#----------------------------------------------------------------------
	# Gets a string of numbers that can be used to instantiate a Time object.
	#  time - SQL time string
	# Returns: Time string separated by commas.
	#----------------------------------------------------------------------
	def self.get_rubytime(time)
		return time.gsub('-', ',').gsub(':', ',').gsub(' ', ',').gsub(/,0(\d)/) {",#{$1}"}
	end
	#----------------------------------------------------------------------
	# Fixes strings for SQL queries and eval expressions.
	#  string - string to be converted
	# Returns: Converted string.
	#----------------------------------------------------------------------
	def self.sql_string(string)
		return @server.sql.escape_string(string)
	end
	#----------------------------------------------------------------------
	# Fixes strings for SQL queries and eval expressions.
	#  string - string to be converted
	# Returns: Converted string.
	#----------------------------------------------------------------------
	def self.make_message(*args)
		return args.map {|arg| arg = arg.to_s}.join("\t")
	end
	#----------------------------------------------------------------------
	# Gets error message with stack trace.
	# Returns: Error message with stack trace.
	#----------------------------------------------------------------------
	def self.get_error
		return ($!.message + "\n" + $!.backtrace.join("\n").sub(Dir.getwd, '.'))
	end
	#----------------------------------------------------------------------
	# Logs a message into a file.
	#  data - the data that created this log
	#  type - what kind of log
	#  message - message to be logged
	#----------------------------------------------------------------------
	def self.log(data, type, message)
		@log_mutex.synchronize {
			return if type == 'Debug' && !DEBUG_MODE
			return if !RMXOS::Logs.has_key?(type)
			# use user ID and username if data is player
			data = "#{data.user_id} (#{data.username})" if data.is_a?(Player)
			begin
				# open log file in append mode
				file = File.open(RMXOS::Logs[type], 'a+')
				# write time, data type and message
				file.write("#{Time.now.getutc.to_s}; #{data} - #{type}:\n#{message}\n") rescue nil
				file.close()
			rescue
			end
		}
	end
	
end

puts RMXOS::Data::Header
puts RMXOS::Data.args(RMXOS::Data::Version, {'VERSION' => RMXOS_VERSION.to_s, 'RUBY_VERSION' => RUBY_VERSION})
puts RMXOS::Data.args(RMXOS::Data::GameVersion, {'NAME' => NAME.to_s, 'VERSION' => GAME_VERSION.to_s})
puts RMXOS::Data::Header
begin
	# load extensions
	RMXOS.load_extensions
	# RMX-OS main
	RMXOS.main
rescue Interrupt # CTRL + C
end
begin
	# last message
	puts ''
	puts RMXOS::Data::PressEnter
	gets if RMXOS.server.prompt_thread == nil
rescue Interrupt # CTRL + C
end
