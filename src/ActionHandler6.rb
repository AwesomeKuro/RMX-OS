#==========================================================================
# ActionHandler
#--------------------------------------------------------------------------
# Handles all basic non-interactive actions.
#==========================================================================

class ActionHandler
	
	#----------------------------------------------------------------------
	# Attempts to kick all players.
	#  username - username of the player with the new usergroup
	#  group - new usergroup
	# Returns: Action result of this action.
	#----------------------------------------------------------------------
	def try_kick_all
		self.set_data(RMXOS::Data::ActionSuccess_ACTION, {'ACTION' => 'kick all'})
		# check permissions additionally
		return RMXOS::Result::DENIED_S if !@client.player.can_use_command?('kickall')
		# execute kick
		RMXOS.clients.get(@client).each {|client| client.execute_kick}
		return RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Attempts the change of the usergroup of a player.
	#  username - username of the player with the new usergroup
	#  group - new usergroup
	# Returns: Action result of this action.
	#----------------------------------------------------------------------
	def try_group_change(username, usergroup)
		self.set_data(RMXOS::Data::GroupChanged_PLAYER, {'ACTION' => 'change usergroup', 'ENTITY' => username, 'PLAYER' => username})
		# check permissions additionally
		return RMXOS::Result::DENIED if @client.player.usergroup <= usergroup
		check = RMXOS.server.sql.query("SELECT usergroup FROM users WHERE username = '#{RMXOS.sql_string(username)}'")
		# user does not exist
		return RMXOS::Result::PLAYER_NOT_EXIST if check.num_rows == 0
		hash = check.fetch_hash
		# permission group needs to be higher
		return RMXOS::Result::DENIED if @client.player.usergroup <= hash['usergroup'].to_i
		# ban the player
		RMXOS.server.sql.query("UPDATE users SET usergroup = #{usergroup} WHERE username = '#{RMXOS.sql_string(username)}'")
		# find the player if he's online
		client = RMXOS.clients.get_by_name(username)
		if client != nil
			# change player's usergroup
			client.player.usergroup = usergroup
			# send new usergroup to player himself
			client.send('UGR', client.player.usergroup)
			# send new data to all clients
			client.sender.send_to_clients(RMXOS.clients.get(client), RMXOS.make_message('PLA', client.player.get_player_data))
		end
		return RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Attempts to send a global script for execution.
	#  script - the Ruby script
	# Returns: Action result of this action.
	#----------------------------------------------------------------------
	def try_global_eval(script)
		@args = {'ACTION' => 'global eval'}
		# check permissions additionally
		return RMXOS::Result::DENIED_S if !@client.player.can_use_command?('geval')
		# send script to all other clients
		@client.sender.send_to_all(RMXOS.make_message('EVA', script))
		return RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Attempts to execute a Ruby script on the server.
	#  script - the Ruby script
	# Returns: Action result of this action.
	#----------------------------------------------------------------------
	def try_server_eval(script)
		self.set_data(RMXOS::Data::ScriptExecuted, {'ACTION' => 'server eval'})
		# check permissions additionally
		return RMXOS::Result::DENIED_S if !@client.player.can_use_command?('seval')
		# try to execute the script
		begin
			eval(script)
		rescue SyntaxError
			return RMXOS::Result::RUBY_INVALID_SYNTAX
		rescue
			@message = $!.message
			return RMXOS::Result::RUBY_SCRIPT_ERROR
		end
		return RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Attempts to execute an SQL script on the server.
	#  script - the SQL script
	# Returns: Action result of this action.
	#----------------------------------------------------------------------
	def try_sql(script)
		self.set_data(RMXOS::Data::ScriptExecuted, {'ACTION' => 'server SQL'})
		# check permissions additionally
		return RMXOS::Result::DENIED_S if !@client.player.can_use_command?('sql')
		# try to execute the script
		begin
			RMXOS.server.sql.query(script)
		rescue
			@message = $!.message
			return RMXOS::Result::SQL_SCRIPT_ERROR
		end
		return RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Kicks a player.
	#  username - username of the player to be kicked
	# Returns: Action result of this action.
	#----------------------------------------------------------------------
	def try_kick(username)
		self.set_data(RMXOS::Data::ActionSuccess_ACTION_ENTITY, {'ACTION' => 'kick', 'ENTITY' => username})
		# check permissions additionally
		return RMXOS::Result::DENIED if !@client.player.can_use_command?('kick')
		# find the player if he's online
		client = RMXOS.clients.get_by_name(username)
		return RMXOS::Result::PLAYER_NOT_EXIST if client == nil
		# permission group needs to be higher
		return RMXOS::Result::DENIED if @client.player.usergroup <= client.player.usergroup
		# kick the player
		client.execute_kick
		return RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Bans a player.
	#  username - username of the player to be banned
	# Returns: Action result of this action.
	#----------------------------------------------------------------------
	def try_ban(username)
		self.set_data(RMXOS::Data::ActionSuccess_ACTION_ENTITY, {'ACTION' => 'ban', 'ENTITY' => username})
		# check permissions additionally
		return RMXOS::Result::DENIED if !@client.player.can_use_command?('ban')
		check = RMXOS.server.sql.query("SELECT user_id, usergroup FROM users WHERE username = '#{RMXOS.sql_string(username)}'")
		# user does not exist
		return RMXOS::Result::PLAYER_NOT_EXIST if check.num_rows == 0
		hash = check.fetch_hash
		# permission group needs to be higher
		return RMXOS::Result::DENIED if @client.player.usergroup <= hash['usergroup'].to_i
		# ban the player
		RMXOS.server.sql.query("UPDATE users SET banned = 1 WHERE user_id = #{hash['user_id']}")
		# kick the player if he's online
		client = RMXOS.clients.get_by_name(username)
		client.execute_kick if client != nil
		return RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Unbans a player.
	#  username - username of the player to be unbanned
	# Returns: Action result of this action.
	#----------------------------------------------------------------------
	def try_unban(username)
		self.set_data(RMXOS::Data::ActionSuccess_ACTION_ENTITY, {'ACTION' => 'unban', 'ENTITY' => username})
		# check permissions additionally
		return RMXOS::Result::DENIED if !@client.player.can_use_command?('unban')
		check = RMXOS.server.sql.query("SELECT user_id, usergroup FROM users WHERE username = '#{RMXOS.sql_string(username)}'")
		# user does not exist
		return RMXOS::Result::PLAYER_NOT_EXIST if check.num_rows == 0
		hash = check.fetch_hash
		# permission group needs to be higher
		return RMXOS::Result::DENIED if @client.player.usergroup <= hash['usergroup'].to_i
		# ban the player
		RMXOS.server.sql.query("UPDATE users SET banned = 0 WHERE user_id = #{hash['user_id']}")
		return RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Attempts to send a chat message to all players online.
	#  message - the chat message
	# Returns: Action result of this action.
	#----------------------------------------------------------------------
	def try_global_chat(message)
		# check permissions additionally
		return RMXOS::Result::DENIED_S if !@client.player.can_use_command?('global')
		# sent message to all
		@client.sender.send_to_all(RMXOS.make_message('CHT', message), true)
		return RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Attempts to send a whisper chat message to a certain player.
	#  username - username of the player
	#  message - the chat message
	# Returns: Action result of this action.
	#----------------------------------------------------------------------
	def try_whisper_chat(username, message)
		@args = {'PLAYER' => username}
		check = RMXOS.server.sql.query("SELECT user_id FROM users WHERE username = '#{RMXOS.sql_string(username)}'")
		# user does not exist
		return RMXOS::Result::PLAYER_NOT_EXIST if check.num_rows == 0
		# find the player if he's online
		client = RMXOS.clients.get_by_name(username)
		return RMXOS::Result::PLAYER_NOT_ONLINE if client == nil
		client.sender.send(message)
		@client.sender.send(message)
		return RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Creates a guild.
	#  guildname - name of the new guild
	#  password - password for new guild
	# Returns: Action result of this action.
	#----------------------------------------------------------------------
	def try_guild_create(guildname, password)
		@@mutex.synchronize {
			self.set_data(RMXOS::Data::GuildCreated_GUILD, {'GUILD' => guildname})
			check = RMXOS.server.sql.query("SELECT COUNT(*) AS count FROM guilds WHERE guildname = '#{RMXOS.sql_string(guildname)}'")
			hash = check.fetch_hash
			# guild already exists
			return RMXOS::Result::GUILD_ALREADY_EXIST if hash['count'].to_i > 0
			# register the new guild
			RMXOS.server.sql.query("START TRANSACTION")
			RMXOS.server.sql.query("INSERT INTO guilds (guildname, password, leader_id) VALUES ('#{RMXOS.sql_string(guildname)}', '#{password}', #{@client.player.user_id})")
			check = RMXOS.server.sql.query("SELECT guild_id FROM guilds WHERE guildname = '#{RMXOS.sql_string(guildname)}'")
			hash = check.fetch_hash
			RMXOS.server.sql.query("UPDATE user_data SET guild_id = #{hash['guild_id']} WHERE user_id = #{@client.player.user_id}")
			RMXOS.server.sql.query("COMMIT")
			# setup guild data
			@client.player.set_guild_data(guildname, @client.player.username, [@client.player.username])
			# send guild data to player
			@client.send('GIN', @client.player.get_guild_data)
			# send new data to all clients
			@client.sender.send_to_clients(RMXOS.clients.get(@client), RMXOS.make_message('PLA', @client.player.get_player_data))
			return RMXOS::Result::SUCCESS
		}
	end
	#----------------------------------------------------------------------
	# Attempts to send a PM to another player.
	#  username - user ID of the recipient
	#  message - the message
	#  sender - the username of the player sending the message
	# Returns: Action result of this action.
	#----------------------------------------------------------------------
	def try_pm_send(username, message, sender = @client.player.username)
		self.set_data(RMXOS::Data::PMSent_PLAYER, {'PLAYER' => username})
		check = RMXOS.server.sql.query("SELECT user_id FROM users WHERE username = '#{RMXOS.sql_string(username)}'")
		return RMXOS::Result::PLAYER_NOT_EXISTS if check.num_rows == 0
		# get user ID
		hash = check.fetch_hash
		user_id = hash['user_id'].to_i
		# check inbox
		check = RMXOS.server.sql.query("SELECT COUNT(*) AS count FROM inbox WHERE recipient_id = #{user_id}")
		hash = check.fetch_hash
		count = hash['count'].to_i
		# if inbox is full
		if count >= INBOX_SIZE - 1
			# send message to player if he's online
			@client.sender.send_to_name(username, RMXOS.make_message('CHT', RMXOS::Data::ColorInfo, 0, RMXOS::Data::PMInboxFull))
			return RMXOS::Result::PM_INBOX_FULL
		end
		# store the PM in the inbox
		RMXOS.server.sql.query("INSERT INTO inbox (recipient_id, message, sendername, senddate) VALUES (#{user_id}, '#{RMXOS.sql_string(message)}', '#{RMXOS.sql_string(sender)}', '#{RMXOS.get_sqltime(Time.now.getutc)}')")
		# notify player of new PM if he's online
		@client.sender.send_to_name(username, RMXOS.make_message('CHT', RMXOS::Data::ColorOk, 0, RMXOS::Data::NewPMs))
		# if inbox is now full
		if count >= INBOX_SIZE - 2
			# send message to player if he's online
			@client.sender.send_to_name(username, RMXOS.make_message('CHT', RMXOS::Data::ColorInfo, 0, RMXOS::Data::PMInboxFull))
		end
		return RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Attempts to cancel a given action.
	#  action_id - the action ID
	# Note: Result code of the action.
	#----------------------------------------------------------------------
	def try_cancel_sent_action(action_id)
		self.set_data('', {'ACTIONID' => sprintf('%X', action_id)})
		@@mutex.synchronize {
			action = self._find_sent_action(action_id)
			return RMXOS::Result::NO_ACTION_ID if action == nil
			self._cancel_sent_action(action)
			return RMXOS::Result::SUCCESS
		}
	end

end
