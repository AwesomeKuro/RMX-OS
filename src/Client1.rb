#==========================================================================
# Client
#--------------------------------------------------------------------------
# Serves as server side connection for clients.
# Processes all messages and contains all basic information.
#==========================================================================

class Client
	
	# special mutexes
	@@login_mutex = nil
	@@register_mutex = nil
	@@trade_mutex = nil
	def self.reset
		@@login_mutex = Mutex.new
		@@register_mutex = Mutex.new
		@@trade_mutex = Mutex.new
	end
	
	# setting all accessible variables
	attr_accessor :message
	attr_accessor :login_timeout
	attr_reader   :socket
	attr_reader   :sender
	attr_reader   :action
	attr_reader   :player
	
	#----------------------------------------------------------------------
	# Initialization.
	#----------------------------------------------------------------------
	def initialize(socket)
		# received message
		@message = ''
		# socket connection
		@socket = socket
		@mutex = Mutex.new
		# utility classes
		@sender = Sender.new(self)
		@action = ActionHandler.new(self)
		@player = Player.new(self)
		# login timeout
		@login_timeout = LOGIN_TIMEOUT
		# saving queries since the saving is executed as one transaction for consistency
		self._clear_saving_queries
	end
	#----------------------------------------------------------------------
	# Gets all saving queries.
	# Returns: All saving queries.
	#----------------------------------------------------------------------
	def saving_queries
		@mutex.synchronize {
			return @saving_queries.clone
		}
	end
	#----------------------------------------------------------------------
	# Resets all saving queries to their initial empty state.
	#----------------------------------------------------------------------
	def clear_saving_queries
		@mutex.synchronize {
			self._clear_saving_queries
		}
	end
	def _clear_saving_queries
		@saving_queries = ['START TRANSACTION']
	end
	#----------------------------------------------------------------------
	# Disconnects the client and broadcasts the message to all other
	# clients.
	#  message - disconnection message to be sent
	#----------------------------------------------------------------------
	def disconnect(message = 'DCS')
		@mutex.synchronize {
			@sender.send(message)
			@sender.send_to_all(RMXOS.make_message('DCT', @player.user_id)) if @player.user_id > 0
			@socket.close rescue nil
			RMXOS.clients.delete(self)
		}
	end
	#----------------------------------------------------------------------
	# Terminates the connection without telling anyone about it, because
	# it's not necessary (e.g. client hasn't even logged in).
	#  message - disconnection message to be sent
	#----------------------------------------------------------------------
	def terminate(message = 'DCS')
		@mutex.synchronize {
			@sender.send(message)
			@socket.close rescue nil
			RMXOS.clients.delete(self)
		}
	end
	#----------------------------------------------------------------------
	# Broadcasts disconnection of this client by kicking.
	#----------------------------------------------------------------------
	def execute_kick
		self.disconnect('KCK')
	end
	#----------------------------------------------------------------------
	# Checks if the client is connected.
	# Returns: True if the client is connected.
	#----------------------------------------------------------------------
	def connected?
		return !@socket.closed?
	end
	#----------------------------------------------------------------------
	# Attempts a client login.
	#  username - username
	#  password - password's hash value
	# Returns: Success result.
	#----------------------------------------------------------------------
	def try_login(username, password)
		@@login_mutex.synchronize {
			# find this user
			check = RMXOS.server.sql.query("SELECT user_id, usergroup, banned, password FROM users WHERE username = '#{RMXOS.sql_string(username)}'")
			# either username or password is incorrect
			return RMXOS::Result::PLAYER_NOT_EXIST if check.num_rows == 0
			hash = check.fetch_hash
			# password incorred
			return RMXOS::Result::PASSWORD_INCORRECT if hash['password'] != password
			# this user is banned
			return RMXOS::Result::DENIED if hash['banned'] != '0'
			user_id = hash['user_id'].to_i
			# get client's IP address
			ip = @socket.peeraddr[3]
			# if using IP banning
			if USE_IP_BANNING
				# match against recorded IPs
				check = RMXOS.server.sql.query("SELECT DISTINCT users.user_id FROM users JOIN ips ON users.user_id = ips.user_id " +
					"WHERE banned = 1 AND ips.ip = '#{ip}'")
				# IP matches with IP of a banned user
				return RMXOS::Result::DENIED if check.num_rows > 0
			end
			# if user is already logged in
			client = RMXOS.clients.get_by_id(user_id)
			# disconnect old client
			client.disconnect if client != nil
			# get user main data
			@player.set_user_data(user_id, username, hash['usergroup'].to_i)
			# log last login time
			RMXOS.server.sql.query("UPDATE user_data SET lastlogin = '#{RMXOS.get_sqltime(Time.now.getutc)}' WHERE user_id = #{@player.user_id}")
			# record IP
			RMXOS.server.sql.query("REPLACE INTO ips(user_id, ip) VALUES (#{user_id}, '#{ip}')")
			# find all buddies
			@player.setup_buddies
			# get other user data
			check = RMXOS.server.sql.query("SELECT guild_id FROM user_data WHERE user_id = #{user_id}")
			hash = check.fetch_hash
			# set all guild related data if player is in a guild
			@player.setup_guild_data(hash['guild_id'].to_i) if hash['guild_id'] != nil
			# mark as logged in
			RMXOS.clients.login(self)
			# notify if new PMs in the inbox
			check = RMXOS.server.sql.query("SELECT COUNT(*) AS count FROM inbox WHERE recipient_id = #{@player.user_id} AND unread = 1")
			hash = check.fetch_hash
			self.send_chat(RMXOS::Data::ColorInfo, RMXOS::Data::NewPMs) if hash['count'].to_i > 0
			# notify if inbox is full
			check = RMXOS.server.sql.query("SELECT COUNT(*) AS count FROM inbox WHERE recipient_id = #{@player.user_id}")
			hash = check.fetch_hash
			self.send_chat(RMXOS::Data::ColorInfo, RMXOS::Error::PMInboxFull) if hash['count'].to_i >= INBOX_SIZE
			return RMXOS::Result::SUCCESS
		}
	end
	#----------------------------------------------------------------------
	# Attempts registering a new account.
	#  username - username
	#  password - password's hash value
	# Returns: Success result of the register try.
	#----------------------------------------------------------------------
	def try_register(username, password)
		@@register_mutex.synchronize {
			# try to find user
			check = RMXOS.server.sql.query("SELECT COUNT(*) AS count FROM users WHERE username = '#{RMXOS.sql_string(username)}'")
			hash = check.fetch_hash
			# user already exists
			return RMXOS::Result::ACCOUNT_ALREADY_EXIST if hash['count'].to_i > 0
			# get user count
			check = RMXOS.server.sql.query("SELECT COUNT(*) AS count FROM users")
			hash = check.fetch_hash
			RMXOS.server.sql.query("START TRANSACTION")
			# first registered user becomes admin
			group = (hash['count'].to_i == 0 ? RMXOS::GROUP_ADMIN : RMXOS::GROUP_PLAYER)
			# register new user
			RMXOS.server.sql.query("INSERT INTO users (username, password, usergroup) VALUES ('#{RMXOS.sql_string(username)}', '#{RMXOS.sql_string(password)}', #{group})")
			# get new user ID
			check = RMXOS.server.sql.query("SELECT user_id FROM users WHERE username = '#{RMXOS.sql_string(username)}'")
			hash = check.fetch_hash
			user_id = hash['user_id'].to_i
			RMXOS.server.sql.query("INSERT INTO user_data (user_id, lastlogin) VALUES (#{user_id}, '#{RMXOS.get_sqltime(Time.now.getutc)}')")
			# get client's IP address
			ip = @socket.peeraddr[3]
			# record IP
			RMXOS.server.sql.query("REPLACE INTO ips(user_id, ip) VALUES (#{user_id}, '#{RMXOS.sql_string(ip)}')")
			RMXOS.server.sql.query("COMMIT")
			return RMXOS::Result::SUCCESS
		}
	end
	#----------------------------------------------------------------------
	# Logs action execution/attempt.
	#  code - result code
	#  action - name of the action
	#----------------------------------------------------------------------
	def _log_action(code, action)
		# log this action if action log is turned on
		if RMXOS.server.options.log_actions
			case code
			when RMXOS::Result::SUCCESS then RMXOS.log(@player, 'Action', action)
			when RMXOS::Result::DENIED then RMXOS.log(@player, 'Action', 'DENIED ' + action)
			end
		end
	end
	#----------------------------------------------------------------------
	# Sends a server chat message to the actual connected client.
	#  color   - text color to be used
	#  message - message that will be sent
	#----------------------------------------------------------------------
	def send_chat(color, message)
		@sender.send(RMXOS.make_message('CHT', color, 0, message))
	end
	#----------------------------------------------------------------------
	# Sends a message to the actual connected client.
	#  args - message arguments that will be sent
	#----------------------------------------------------------------------
	def send(*args)
		@sender.send(RMXOS.make_message(*args))
	end
	#----------------------------------------------------------------------
	# Handles received messages for this client.
	#  message - received message
	#----------------------------------------------------------------------
	def handle(message)
		@message = message
		# update all loaded extensions with this client if they are active
		abort = false
		RMXOS.extensions.each_value {|extension|
			extension.mutex.synchronize {
				abort |= extension.client_update(self)
			}
		}
		return true if abort
		# default message handle
		return true if self.check_game
		return true if self.check_connection
		return true if self.check_admin_commands
		return true if self.check_mod_commands
		return true if self.check_normal_commands
		return true if self.check_buddy_commands
		return true if self.check_pm_commands
		return true if self.check_trade_commands
		return true if self.check_guild_commands
		return true if self.check_save
		return true if self.check_load
		return false
	end
	#----------------------------------------------------------------------
	# Checks messages related to ingame procedures.
	# Returns: True or false whether to stop checking this message.
	#----------------------------------------------------------------------
	def check_game
		case @message
		when /\AHAI\Z/			then											return true
		when /\APNG\Z/			then											return true
		when /\ADCT\Z/			then self.disconnect;							return true
		when /\ACHT\t(.+)/		then self._chat;								return true
		when /\ACHA\t(.+)/		then self._chat_action;							return true
		when /\AENT\Z/			then self._server_entry;						return true
		when /\AMEN\t(.+)/		then self._map_entry($1.to_i);					return true
		when /\AMEX\Z/			then self._map_exit;							return true
		when /\AMEV\t(.+)/		then self._map_exchange_variables(eval($1));	return true
		when /\AYES\t(.+)/		then self._yes($1.hex);							return true
		when /\ANOO\t(.+)/		then self._no($1.hex);							return true
		when /\ACAN\t(.+)/		then self._cancel($1.hex);						return true
		when /\AREQ\Z/			then self._req;									return true
		end
		return false
	end
	#----------------------------------------------------------------------
	# Checks connection related messages.
	# Returns: True or false whether to stop checking this message.
	#----------------------------------------------------------------------
	def check_connection
		case @message
		when /\ACON\t(.+)\t(.+)/	then self._connection_request($1.to_f, $2.to_f);	return true
		when /\ALIN\t(.+)\t(.+)/	then self._connection_login($1, $2);				return true
		when /\AREG\t(.+)\t(.+)/	then self._connection_register($1, $2);				return true
		end
		return false
	end
	#----------------------------------------------------------------------
	# Checks messages for transmitted admin chat commands.
	# Returns: True or false whether to stop checking this message.
	#----------------------------------------------------------------------
	def check_admin_commands
		case @message
		when /\AAKA\Z/				then self._kick_all;								return true
		when /\AAPA\t(.+)\t(.+)/	then self._change_player_password($1, $2);			return true
		when /\AAGP\t(.+)\t(.+)/	then self._change_guild_password($1, $2);			return true
		when /\AGRC\t(.+)\t(.+)/	then self._change_player_usergroup($1, $2.to_i);	return true
		when /\AAEV\t(.+)/			then self._global_eval($1);							return true
		when /\AASE\t(.+)/			then self._server_eval($1);							return true
		when /\AASQ\t(.+)/			then self._sql($1);									return true
		end
		return false
	end
	#----------------------------------------------------------------------
	# Checks messages for transmitted mod chat commands.
	# Returns: True or false whether to stop checking this message.
	#----------------------------------------------------------------------
	def check_mod_commands
		case @message
		when /\AMKI\t(.+)/	then self._kick_player($1);		return true
		when /\AMBA\t(.+)/	then self._ban_player($1);		return true
		when /\AMUB\t(.+)/	then self._unban_player($1);	return true
		when /\AMGM\t(.+)/	then self._global_chat($1);		return true
		end
		return false
	end
	#----------------------------------------------------------------------
	# Checks messages for transmitted normal chat commands.
	# Returns: True or false whether to stop checking this message.
	#----------------------------------------------------------------------
	def check_normal_commands
		case @message
		when /\AWCH\t(.+)\t(.{6})\t(.+)\t(.+)/	then self._whisper($1, $2, $3.to_i, $4);	return true
		when /\ANPS\t(.+)\t(.+)/				then self._change_password($1, $2);	return true
		when /\ATRQ\t(.+)/						then self._trade_request($1);		return true
		end
		return false
	end
	#----------------------------------------------------------------------
	# Checks messages for transmitted pm chat commands.
	# Returns: True or false whether to stop checking this message.
	#----------------------------------------------------------------------
	def check_buddy_commands
		case @message
		when /\ABAD\t(.+)/	then self._buddy_add($1);		return true
		when /\ABRE\t(.+)/	then self._buddy_remove($1);	return true
		end
		return false
	end
	#----------------------------------------------------------------------
	# Checks messages for transmitted pm chat commands.
	# Returns: True or false whether to stop checking this message.
	#----------------------------------------------------------------------
	def check_pm_commands
		case @message
		when /\APMM\t(.+)\t(.+)/	then self._pm_send($1, $2);		return true
		when /\APMA\Z/				then self._pm_get_all;			return true
		when /\APMU\Z/				then self._pm_get_unread;		return true
		when /\APMO\t(.+)/			then self._pm_open($1.to_i);	return true
		when /\APMD\t(.+)/			then self._pm_delete($1.to_i);	return true
		when /\APMC\Z/				then self._pm_delete_all;		return true
		when /\APMS\Z/				then self._pm_inbox_status;		return true
		end
		return false
	end
	#----------------------------------------------------------------------
	# Checks messages for transmitted trade commands.
	# Returns: True or false whether to stop checking this message.
	#----------------------------------------------------------------------
	def check_trade_commands
		case @message
		when /\ATCO\t(.+)/			then self._trade_confirm($1.to_i);			return true
		when /\ATCA\t(.+)/			then self._trade_complete_abort($1.to_i);	return true
		when /\ATRI\t(.+)\t(.*)/	then self._trade_items($1.to_i, $2);		return true
		when /\ATRC\t(.+)/			then self._trade_cancel($1.to_i);			return true
		when /\ATCC\t(.+)/			then self._trade_confirm_cancel($1.to_i);	return true
		when /\ATRX\t(.+)/			then self._trade_execute($1.to_i);			return true
		end
		return false
	end
	#----------------------------------------------------------------------
	# Checks messages for transmitted guild chat commands.
	# Returns: True or false whether to stop checking this message.
	#----------------------------------------------------------------------
	def check_guild_commands
		case @message
		when /\AGCR\t(.+)\t(.+)/	then self._guild_create($1, $2);			return true
		when /\AGPS\t(.+)\t(.+)/	then self._guild_change_password($1, $2);	return true
		when /\AGDI\t(.+)/			then self._guild_disband($1);				return true
		when /\AGTR\t(.+)\t(.+)/	then self._guild_transfer($1, $2);			return true
		when /\AGIN\t(.+)/ 			then self._guild_invite($1);				return true
		when /\AGRE\t(.+)\t(.+)/	then self._guild_remove_member($1, $2);		return true
		when /\AGLE\t(.+)/			then self._guild_leave($1);					return true
		when /\AGME\t(.+)/			then self._guild_chat($1);					return true
		end
		return false
	end
	#----------------------------------------------------------------------
	# Checks messages during the saving process.
	# Returns: True or false whether to stop checking this message.
	#----------------------------------------------------------------------
	def check_save
		case @message
		when /\ASCL\Z/				then self._save_clear;			return true
		when /\ASAV\t(.+)\t(.+)/	then self._save_data($1, $2);	return true
		when /\ASEN\Z/				then self._save_end;			return true
		end
		return false
	end
	#----------------------------------------------------------------------
	# Checks messages for loading.
	# Returns: True or false whether to stop checking this message.
	#----------------------------------------------------------------------
	def check_load
		case @message
		when /\ALRQ\Z/	then self._load_request;	return true
		end
		return false
	end

end
