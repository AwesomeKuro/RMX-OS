#==========================================================================
# module RMXOS
#--------------------------------------------------------------------------
# This is the container for all RMXOS classes.
#==========================================================================

module RMXOS
	
	#======================================================================
	# RMXOS::Server
	#----------------------------------------------------------------------
	# Serves as main processing server for RMX-OS.
	#======================================================================

	class Server
		
		# setting all accessible variables
		attr_reader   :running
		attr_reader   :options
		attr_reader   :tcp
		attr_reader   :sql
		attr_reader   :prompt_thread
		
		#------------------------------------------------------------------
		# Initialization.
		#------------------------------------------------------------------
		def initialize
			# restarting server
			@running = true
			@options = RMXOS::Options.new
			@options.ip = HOST
			@options.port = PORT
			@options.sql_hostname = SQL_HOSTNAME
			@options.sql_username = SQL_USERNAME
			@options.sql_password = SQL_PASSWORD
			@options.sql_database = SQL_DATABASE
			@options.log_messages = LOG_MESSAGES
			@options.log_errors = LOG_ERRORS
			@options.log_actions = LOG_ACTIONS
			@tcp = nil
			@sql = nil
			@prompt_thread = nil
			@simple_thread_mutex = Mutex.new
		end
		#------------------------------------------------------------------
		# Starts the server and sets up all connections
		#------------------------------------------------------------------
		def start
			RMXOS.log(RMXOS::Debug::MainThread, 'Debug', RMXOS::Debug::ServerStarting)
			puts RMXOS::Data::Delimiter
			@prompt_thread = nil
			# server startup message
			self.start_socket
			# SQL server connection
			self.connect_to_database
			# main thread for server self-maintenance and zombie client handling
			self.run_thread_maintenance
			# run thread for extension update
			self.run_thread_extensions
			# show startup messages
			puts RMXOS::Data::Delimiter
			puts RMXOS::Data.args(RMXOS::Data::ServerStart_TIME, {'TIME' => Time.now.getutc.to_s})
			puts "#{RMXOS::Data::Host}: #{@options.ip}:#{@options.port}"
			puts RMXOS::Data::CTRLC
			# ruby prompt thread if Ruby prompt optionis on
			self.run_thread_ruby_prompt if RUBY_PROMPT
			RMXOS.log(RMXOS::Debug::MainThread, 'Debug', RMXOS::Debug::ServerStarted)
		end
		#------------------------------------------------------------------
		# Starts the TCP socket server.
		#------------------------------------------------------------------
		def start_socket
			puts RMXOS::Data.args(RMXOS::Data::SocketStarting_IP_PORT, {'IP' => @options.ip, 'PORT' => @options.port.to_s})
			@tcp = TCPServer.new(@options.ip, @options.port)
		end
		#------------------------------------------------------------------
		# Connects to the SQL database.
		#------------------------------------------------------------------
		def connect_to_database
			puts RMXOS::Data.args(RMXOS::Data::MySQLConnecting_DATABASE, {'DATABASE' => @options.sql_database})
			@sql = RMXOS::SQL.new(@options)
		end
		#------------------------------------------------------------------
		# Runs the thread that disconnects zombie clients.
		#------------------------------------------------------------------
		def run_thread_maintenance
			time = Time.now
			# deletion of clients with closed connection
			t = Thread.start {
				i = 0
				while @running
					if i % 10 == 0 # check every second
						# for every unknown client
						RMXOS.clients.get_unknown.each {|client|
							client.login_timeout -= Time.now - time
							# terminate connect if timeout has expired
							if client.login_timeout < 0
								client.terminate('DCL')
							elsif i % 50 == 0 # check every 5 seconds
								# attempt a simple ping
								begin
									client.sender.send_unsafe('PNG')
								rescue
									RMXOS.log(client, 'Debug', RMXOS::Debug::PingFailed)
									# client disconnected somehow without giving notice to server, remove zombie client from server
									client.terminate('DCL')
								end
							end
						}
						time = Time.now
					end
					if i % 50 == 0 # check every 5 seconds
						# for every logged in client
						RMXOS.clients.get.each {|client|
							# attempt a simple ping
							begin
								client.sender.send_unsafe('PNG')
							rescue
								RMXOS.log(client, 'Debug', RMXOS::Debug::PingFailed)
								# client disconnected somehow without giving notice to server, remove zombie client from server
								client.disconnect
							end
						}
					end
					i = (i + 1) % 50
					sleep(0.1)
				end
			}
			t.priority = -10
		end
		#------------------------------------------------------------------
		# Runs the thread that handles Ruby prompt.
		#------------------------------------------------------------------
		def run_thread_ruby_prompt
			puts RMXOS::Data::CommandPrompt
			@prompt_thread = Thread.start {
				@lines = []
				while @running
					# start prompt
					print RMXOS::Data::CommandPromptSign
					script = gets.gsub("\n", '')
					break if !@running
					begin
						# attempt to combine multiple lines
						@lines.push(script)
						if script == '' || @lines.size == 1
							@lines.delete('')
							# execute script
							if EXTENDED_THREADING
								eval(@lines.join("\n"))
							else
								@simple_thread_mutex.synchronize {
									eval(@lines.join("\n"))
								}
							end
							@lines.clear
							puts ''
						end
					rescue SyntaxError
						# single/multiple line syntax error
						if script == ''
							puts RMXOS::Data::InvalidSyntax
							puts $!.message
							puts @lines.join("\n")
							@lines.clear
						end
					rescue
						puts $!.message
						@lines.clear
					end
				end
			}
			@prompt_thread.priority = -10
		end
		#------------------------------------------------------------------
		# Runs the thread that handles extension update.
		#------------------------------------------------------------------
		def run_thread_extensions
			# for each extension
			RMXOS.extensions.each_value {|extension|
				# if server thread needs to be running
				if extension::SERVER_THREAD
					# run it
					Thread.start(extension) {|ext|
						begin
							ext.main
						rescue
							# unexpected extension error
							name = RMXOS.extensions.key?(ext)
							RMXOS.log(name, 'Debug', RMXOS::Debug::ExtensionFailed)
							message = RMXOS::Data.args(RMXOS::Error::ExtensionRunError_FILE, {'FILE' => name}) + "\n"
							message += RMXOS.get_error
							puts message
							RMXOS.log(name, 'Extension', message) if @options.log_errors
							# shut down server, extension crash must not allow server to continue
							RMXOS.server.shutdown
						end
					}
				end
			}
		end
		#------------------------------------------------------------------
		# Runs the server and handles connections.
		#------------------------------------------------------------------
		def run
			# while the server is running
			while @running
				# accept connection
				begin
					connection = @tcp.accept_nonblock
				rescue
					# no connection in this iteration
					sleep(0.1)
					next # don't use retry, because that wouldn't check for @running again
				end
				RMXOS.log(RMXOS::Debug::MainThread, 'Debug', RMXOS::Debug::ConnectionReceived)
				# start a thread for new client
				Thread.start(connection) {|socket|
					RMXOS.log(Thread.current.inspect, 'Debug', RMXOS::Debug::ThreadStart)
					# create new client for this socket connection
					client = Client.new(socket)
					RMXOS.log(client, 'Debug', RMXOS::Debug::ClientConnect + ' ' + socket.inspect)
					# store the client
					RMXOS.clients.add(client)
					begin
						buffer = ''
						# as long as the server keeps receiving messages from this client
						while @running && client.connected?
							begin
								buffer += client.socket.recv(0xFFFF)
							rescue
								# socket read failed somehow, log debug
								RMXOS.log(client.player.user_id > 0 ? client.player : client, 'Debug', RMXOS.get_error)
								break
							end
							# split by newline
							messages = buffer.split("\n", -1)
							# possibly incomplete chunk will be processed the next time
							buffer = messages.pop
							# for each message
							messages.each {|message|
								# log this message if message log is turned on
								if @options.log_messages && !message.start_with?("SAV\t", "LOA\t")
									RMXOS.log(client.player, 'Incoming Message', message)
								end
								if EXTENDED_THREADING
									# let the client handle the received message
									if !client.handle(message)
										RMXOS.log(client, 'Error', RMXOS::Data.args(RMXOS::Error::MessageNotHandled_MESSAGE, {'MESSAGE' => message}))
									end
								else
									@simple_thread_mutex.synchronize {
										# let the client handle the received message
										if !client.handle(message)
											RMXOS.log(client, 'Error', RMXOS::Data.args(RMXOS::Error::MessageNotHandled_MESSAGE, {'MESSAGE' => message}))
										end
									}
								end
							}
						end
					rescue
						begin
							RMXOS.log(client, 'Debug', RMXOS::Debug::ClientFailed + ' ' + socket.inspect)
							# something went wrong
							error_message = RMXOS.get_error
							# if client has actually logged in
							if client.player.user_id > 0
								# log this client's error message if error log is turned on
								RMXOS.log(client.player, 'Error', error_message) if @options.log_errors
								# show the error message
								message = RMXOS::Data.args(RMXOS::Error::ClientCrash_ID_NAME_TIME,
									{'ID' => client.player.user_id.to_s, 'NAME' => client.player.username, 'TIME' => Time.now.getutc.to_s})
								# this client has been disconnected, everybody else needs to know
								client.disconnect
							else
								# an unknown client has caused an error
								message = RMXOS::Data.args(RMXOS::Error::UnknownClientCrash_TIME, {'TIME' => Time.now.getutc.to_s})
							end
							# RMX-OS error message
							puts message
							# show internal Ruby error message
							puts error_message
						rescue
							# something went TERRIBLY wrong and indicates a bug in RMX-OS
							puts RMXOS.get_error
						end
					end
					# in case something went horribly wrong, just close this connection and remove the client
					client.socket.close rescue nil
					RMXOS.clients.delete(client)
					RMXOS.log(Thread.current.inspect, 'Debug', RMXOS::Debug::ThreadStop)
				}
			end
			# execute soft shutdown
			self.execute_shutdown
		end
		#------------------------------------------------------------------
		# Executes a soft shut down of the server.
		#------------------------------------------------------------------
		def execute_shutdown
			RMXOS.log(RMXOS::Debug::MainThread, 'Debug', RMXOS::Debug::ServerStopping)
			# shutting down message
			puts "\n" + RMXOS::Data::ShuttingDown
			# terminate every client connection
			RMXOS.clients.get_all.each {|client| client.terminate}
			# wait for all threads to finish, should be immediately since all connections were terminated
			@prompt_thread.kill if @prompt_thread != nil
			(Thread.list - [Thread.current, @prompt_thread]).each {|thread| thread.join}
			# close TCP server connection
			@tcp.close rescue nil
			@tcp = nil
			# close SQL database connection
			@sql.close
			@sql = nil
			# done
			puts RMXOS::Data::Shutdown
			RMXOS.log(RMXOS::Debug::MainThread, 'Debug', RMXOS::Debug::ServerStopped)
		end
		#------------------------------------------------------------------
		# Executes a hard shut down of the server.
		#------------------------------------------------------------------
		def force_shutdown
			RMXOS.log(RMXOS::Debug::MainThread, 'Debug', RMXOS::Debug::ServerForceStopping)
			# shutting down message
			puts "\n" + RMXOS::Data::ShuttingDownForced
			# terminate every client connection
			RMXOS.clients.get_all.each {|client| client.terminate}
			# terminate all other threads
			(Thread.list - [Thread.current]).each {|thread| thread.kill}
			# close TCP server connection
			@tcp.close rescue nil
			@tcp = nil
			# close SQL database connection
			@sql.close
			@sql = nil
			# done
			puts RMXOS::Data::ShutdownForced
			RMXOS.log(RMXOS::Debug::MainThread, 'Debug', RMXOS::Debug::ServerForceStopped)
		end
		#------------------------------------------------------------------
		# Prepares the server for a soft shut down.
		#------------------------------------------------------------------
		def shutdown
			@running = false
		end
		
	end
	
end
