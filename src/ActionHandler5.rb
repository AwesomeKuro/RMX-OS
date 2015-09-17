#==========================================================================
# ActionHandler
#--------------------------------------------------------------------------
# Handles guild related actions.
#==========================================================================

class ActionHandler
	
	#----------------------------------------------------------------------
	# Changes the guild password.
	#  oldpass - old encrypted password
	#  newpass - new encrypted password
	# Returns: Action result of this action.
	#----------------------------------------------------------------------
	def prepare_guild_password_change(oldpass, newpass)
		@args = {}
		check = RMXOS.server.sql.query("SELECT guild_id, password FROM guilds WHERE guildname = '#{RMXOS.sql_string(@client.player.guildname)}'")
		hash = check.fetch_hash
		# password check
		return RMXOS::Result::PASSWORD_INCORRECT if oldpass != hash['password']
		# if password is the same
		return RMXOS::Result::PASSWORD_SAME if oldpass == newpass
		# prepare yes/no action
		messages = Action::MessagePack.new(RMXOS::Data::PasswordChanging, RMXOS::Data::PasswordChanged, RMXOS::Data::PasswordNoChange, @args)
		self.create_action(Action::TYPE_GUILD_PASSWORD_CHANGE, [hash['guild_id'].to_i, @client.player.guildname, newpass], messages)
		return RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Disbands the guild.
	#  password - guild password
	# Returns: Action result of this action.
	#----------------------------------------------------------------------
	def prepare_guild_disband(password)
		@args = {'GUILD' => @client.player.guildname}
		check = RMXOS.server.sql.query("SELECT guild_id, password FROM guilds WHERE guildname = '#{RMXOS.sql_string(@client.player.guildname)}'")
		hash = check.fetch_hash
		# password check
		return RMXOS::Result::PASSWORD_INCORRECT if password != hash['password']
		# prepare yes/no action
		messages = Action::MessagePack.new(RMXOS::Data::GuildDisbanding_GUILD, '', RMXOS::Data::GuildNoDisband_GUILD, @args)
		self.create_action(Action::TYPE_GUILD_DISBAND, hash['guild_id'].to_i, messages)
		return RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Transfers leadership of the guild.
	#  username - username of the new leader
	#  password - guild password
	# Returns: Action result of this action.
	#----------------------------------------------------------------------
	def prepare_guild_transfer(username, password)
		@args = {'PLAYER' => username, 'GUILD' => @client.player.guildname}
		check = RMXOS.server.sql.query("SELECT password FROM guilds WHERE guildname = '#{RMXOS.sql_string(@client.player.guildname)}'")
		hash = check.fetch_hash
		# password check
		return RMXOS::Result::PASSWORD_INCORRECT if password != hash['password']
		check = RMXOS.server.sql.query("SELECT COUNT(*) AS count FROM users WHERE username = '#{RMXOS.sql_string(username)}'")
		hash = check.fetch_hash
		# player doesn't exist
		return RMXOS::Result::PLAYER_NOT_EXIST if hash['count'].to_i == 0
		# find the player if he's online
		client = RMXOS.clients.get_by_name(username)
		# not online
		return RMXOS::Result::PLAYER_NOT_ONLINE if client == nil
		# not on the same map
		return RMXOS::Result::PLAYER_NOT_ON_MAP if client.player.map_id != @client.player.map_id
		# prepare transfer
		sender_messages = Action::MessagePack.new(RMXOS::Data::GuildTransferring_GUILD_PLAYER,
			'', RMXOS::Data::GuildNoTransfer_PLAYER, @args)
		receiver_messages = Action::MessagePack.new(self.make_accept_message(RMXOS::Data::GuildTransfer_PLAYER),
			RMXOS::Data::GuildLeader_GUILD, RMXOS::Data::GuildNoTransfer, {'PLAYER' => @client.player.username, 'GUILD' => @client.player.guildname})
		self.create_interaction(Action::TYPE_GUILD_TRANSFER, sender_messages, [client], nil, receiver_messages)
		return RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Invites a player to the guild.
	#  username - username of the player to be invited
	# Returns: Action result of this action.
	#----------------------------------------------------------------------
	def prepare_guild_invite(username)
		@args = {'PLAYER' => username, 'GUILD' => @client.player.guildname}
		check = RMXOS.server.sql.query("SELECT COUNT(*) AS count FROM users WHERE username = '#{RMXOS.sql_string(username)}'")
		hash = check.fetch_hash
		# player doesn't exist
		return RMXOS::Result::PLAYER_NOT_EXIST if hash['count'].to_i == 0
		# find the player if he's online
		client = RMXOS.clients.get_by_name(username)
		# not online
		return RMXOS::Result::PLAYER_NOT_ONLINE if client == nil
		# not on the same map
		return RMXOS::Result::PLAYER_NOT_ON_MAP if client.player.map_id != @client.player.map_id
		# guild check
		check = RMXOS.server.sql.query("SELECT guild_id FROM user_data WHERE user_id = #{client.player.user_id}")
		hash = check.fetch_hash
		return RMXOS::Result::PLAYER_ALREADY_IN_GUILD if hash['guild_id'] != nil
		# prepare invitation
		sender_messages = Action::MessagePack.new(RMXOS::Data::GuildInvited_PLAYER,
			'', RMXOS::Data::GuildNoJoin_PLAYER, @args)
		receiver_messages = Action::MessagePack.new(self.make_accept_message(RMXOS::Data::GuildInvitation_GUILD),
			RMXOS::Data::GuildJoined_GUILD, RMXOS::Data::GuildNoJoin, {'GUILD' => @client.player.guildname})
		self.create_interaction(Action::TYPE_GUILD_JOIN, sender_messages, [client], @client.player.guildname, receiver_messages)
		return RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Leaves a guild.
	#  password - user password
	# Returns: Action result of this action.
	#----------------------------------------------------------------------
	def prepare_guild_leave(password)
		@args = {'GUILD' => @client.player.guildname}
		# password check
		check = RMXOS.server.sql.query("SELECT password FROM users WHERE user_id = #{@client.player.user_id}")
		hash = check.fetch_hash
		return RMXOS::Result::PASSWORD_INCORRECT if password != hash['password']
		# prepare yes/no action
		messages = Action::MessagePack.new(RMXOS::Data::GuildLeaving_GUILD, RMXOS::Data::GuildRemoved_GUILD, RMXOS::Data::GuildNoLeave_GUILD, @args)
		self.create_action(Action::TYPE_GUILD_LEAVE, nil, messages)
		return RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Removes a player from the guild.
	#  username - username of the player to be removed
	#  password - guild password
	# Returns: Action result of this action.
	#----------------------------------------------------------------------
	def prepare_guild_remove_member(username, password)
		@args = {'PLAYER' => username, 'GUILD' => @client.player.guildname}
		check = RMXOS.server.sql.query("SELECT password FROM guilds WHERE guildname = '#{RMXOS.sql_string(@client.player.guildname)}'")
		hash = check.fetch_hash
		# password check
		return RMXOS::Result::PASSWORD_INCORRECT if password != hash['password']
		# prepare yes/no action
		check = RMXOS.server.sql.query("SELECT user_id FROM users WHERE username = '#{RMXOS.sql_string(username)}'")
		hash = check.fetch_hash
		# prepare yes/no action
		messages = Action::MessagePack.new(RMXOS::Data::GuildRemoving_PLAYER, RMXOS::Data::GuildRemoved_PLAYER, RMXOS::Data::GuildNoRemove_PLAYER, @args)
		self.create_action(Action::TYPE_GUILD_REMOVE, [hash['user_id'].to_i, username], messages)
		return RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Executes a guild password change.
	#----------------------------------------------------------------------
	def execute_guild_password_change(action)
		# change password
		guild_id, guildname, password = action.data
		RMXOS.server.sql.query("UPDATE guilds SET password = '#{RMXOS.sql_string(password)}' WHERE guild_id = #{guild_id}")
		# log this action if action log is turned on
		if RMXOS.server.options.log_actions
			RMXOS.log(@client.player, 'Action', "guild password change: #{guild_id} (#{guildname})")
		end
		return RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Executes the disbanding of the guild.
	#----------------------------------------------------------------------
	def execute_guild_disband(action)
		# get guild ID
		guild_id = action.data
		# delete the guild
		RMXOS.server.sql.query("DELETE FROM guilds WHERE guild_id = #{guild_id}")
		# notify all guild members
		message = RMXOS::Data.args(RMXOS::Data::GuildDisbanded_GUILD, {'GUILD' => @client.player.guildname})
		# first remove all remaining actions
		types = [Action::TYPE_GUILD_PASSWORD_CHANGE, Action::TYPE_GUILD_TRANSFER, Action::TYPE_GUILD_JOIN, Action::TYPE_GUILD_REMOVE]
		types.each {|type|
			actions = @sent.find_all {|action| action.type == type}
			actions.each {|action| self._cancel_sent_action(action, false)}
			actions = @pending.find_all {|action| action.type == type}
			actions.each {|action| self._cancel_pending_action(action, false)}
		}
		# notify online members
		offline_members = @client.player.guildmembers.clone
		RMXOS.clients.get_in_guild(@client, true).each {|client|
			# first remove pending actions
			actions = client.action.pending.find_all {|action| action.type == Action::TYPE_GUILD_LEAVE}
			actions.each {|action| client.action._cancel_pending_action(action, false)}
			# notify all guild members that the guild has been disbanded
			client.send('GRM')
			client.player.reset_guild
			offline_members.delete(client.player.username)
			client.send_chat(RMXOS::Data::ColorInfo, message)
			# send new data to all clients
			client.sender.send_to_clients(RMXOS.clients.get(client), RMXOS.make_message('PLA', client.player.get_player_data))
		}
		# send PM to all offline members
		offline_members.each {|username| @client.action.try_pm_send(username, message, RMXOS::Data::Server)}
		self.clear_data
		return RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Executes guild leadership transfer.
	#----------------------------------------------------------------------
	def execute_guild_transfer(action)
		# new leader
		RMXOS.server.sql.query("UPDATE guilds SET leader_id = #{@client.player.user_id} WHERE guildname = '#{RMXOS.sql_string(@client.player.guildname)}'")
		# set new leader data
		@client.player.guildleader = @client.player.username
		# notify player
		leader_message = RMXOS.make_message('GLE', @client.player.username)
		@client.send(leader_message)
		# notify all guild members
		message = RMXOS::Data.args(RMXOS::Data::GuildLeader_PLAYER, {'GUILD' => @client.player.guildname, 'PLAYER' => @client.player.username})
		message = RMXOS.make_message('CHT', RMXOS::Data::ColorOk, 0, message)
		RMXOS.clients.get_in_guild(@client).each {|client|
			# notify all guild members of the new leader
			client.player.guildleader = @client.player.guildleader
			client.send(leader_message)
			client.send(message)
		}
		return RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Executes joining a guild.
	#----------------------------------------------------------------------
	def execute_guild_join(action)
		guildname = action.data
		# get guild data
		check = RMXOS.server.sql.query("SELECT guild_id FROM guilds WHERE guildname = '#{RMXOS.sql_string(guildname)}'")
		hash = check.fetch_hash
		guild_id = hash['guild_id'].to_i
		RMXOS.server.sql.query("UPDATE user_data SET guild_id = #{guild_id} WHERE user_id = #{@client.player.user_id}")
		# set all guild related data
		@client.player.setup_guild_data(guild_id)
		# send guild data to player
		@client.send('GIN', @client.player.get_guild_data)
		# notify players that this player has joined the guild
		message = RMXOS::Data.args(RMXOS::Data::GuildJoined_PLAYER, {'PLAYER' => @client.player.username})
		joinMessage = RMXOS.make_message('GJO', @client.player.username)
		message = RMXOS.make_message('CHT', RMXOS::Data::ColorOk, 0, message)
		RMXOS.clients.get_in_guild(@client).each {|client|
			# send and set up all necessary data
			client.send(joinMessage)
			client.send(message)
			client.player.guildmembers.push(@client.player.username)
		}
		# send new data to all clients
		@client.sender.send_to_clients(RMXOS.clients.get(@client), RMXOS.make_message('PLA', @client.player.get_player_data))
		return RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Executes leaving the guild.
	#----------------------------------------------------------------------
	def execute_guild_leave(action)
		# leave guild
		RMXOS.server.sql.query("UPDATE user_data SET guild_id = NULL WHERE user_id = #{@client.player.user_id}")
		@client.send('GRM')
		# notify all guild members that this player is not a guild member anymore
		@client.sender.send_to_guild(RMXOS.make_message('GRE', @client.player.username))
		message = RMXOS::Data.args(RMXOS::Data::GuildRemoved_PLAYER, {'PLAYER' => @client.player.username, 'GUILD' => @client.player.guildname})
		@client.sender.send_to_guild(RMXOS.make_message('CHT', RMXOS::Data::ColorInfo, 0, message))
		@client.player.reset_guild
		# send new data to all clients
		@client.sender.send_to_clients(RMXOS.clients.get(@client), RMXOS.make_message('PLA', @client.player.get_player_data))
		return RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Executes removing a member from the guild.
	#----------------------------------------------------------------------
	def execute_guild_remove_member(action)
		user_id, username = action.data
		# remove member from guild
		RMXOS.server.sql.query("UPDATE user_data SET guild_id = NULL WHERE user_id = #{user_id}")
		# find the player if he's online
		client = RMXOS.clients.get_by_id(user_id)
		# if client is online
		if client != nil
			actions = client.action.pending.find_all {|action| action.type == Action::TYPE_GUILD_LEAVE}
			actions.each {|action| client.action._cancel_pending_action(action, false)}
			client.send('GRM')
			# send message to player leaving guild
			client.send_chat(RMXOS::Data::ColorInfo, RMXOS::Data.args(RMXOS::Data::GuildRemoved_GUILD, {'GUILD' => @client.player.guildname}))
			# reset all guild related data
			client.player.reset_guild
			# send new data to all clients
			client.sender.send_to_clients(RMXOS.clients.get(client), RMXOS.make_message('PLA', client.player.get_player_data))
		else
			# leave a message in the player's inbox
			message = RMXOS::Data.args(RMXOS::Data::GuildRemoved_GUILD, {'GUILD' => @client.player.guildname})
			@client.action.try_pm_send(username, message, RMXOS::Data::Server)
			self.clear_data
		end
		# notify all guild members that this player is not a guild member anymore
		@client.sender.send_to_guild(RMXOS.make_message('GRE', username), true)
		message = RMXOS::Data.args(RMXOS::Data::GuildRemoved_PLAYER, {'PLAYER' => username, 'GUILD' => @client.player.guildname})
		@client.sender.send_to_guild(RMXOS.make_message('CHT', RMXOS::Data::ColorInfo, 0, message))
		return RMXOS::Result::SUCCESS
	end

end
