#==========================================================================
# ActionHandler
#--------------------------------------------------------------------------
# Handles administrative actions.
#==========================================================================

class ActionHandler
	
	#----------------------------------------------------------------------
	# Prepares the change another player's password.
	#  username - username of the other player
	#  password - new encrypted password
	# Returns: Action result of this action.
	#----------------------------------------------------------------------
	def prepare_forced_password_change(username, password)
		@args = {'ENTITY' => username, 'PLAYER' => username, 'ACTION' => 'change password of'}
		return RMXOS::Result::DENIED if !@client.player.can_use_command?('pass')
		check = RMXOS.server.sql.query("SELECT user_id FROM users WHERE username = '#{RMXOS.sql_string(username)}'")
		# player does not exist
		return RMXOS::Result::PLAYER_NOT_EXIST if check.num_rows == 0
		# prepare yes/no action
		hash = check.fetch_hash
		messages = Action::MessagePack.new(RMXOS::Data::PasswordForcing_ENTITY, RMXOS::Data::PasswordChanged, RMXOS::Data::PasswordNoChange, @args)
		self.create_action(Action::TYPE_FORCED_PASSWORD_CHANGE, [hash['user_id'].to_i, username, password], messages)
		return RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Prepares the change a guild's password.
	#  guildname - name of the guild
	#  password  - new encrypted password
	# Returns: Action result of this action.
	#----------------------------------------------------------------------
	def prepare_forced_guild_password_change(guildname, password)
		@args = {'ENTITY' => guildname, 'GUILD' => guildname, 'ACTION' => 'change password of'}
		return RMXOS::Result::DENIED if !@client.player.can_use_command?('gpass')
		check = RMXOS.server.sql.query("SELECT guild_id FROM guilds WHERE guildname = '#{RMXOS.sql_string(guildname)}'")
		# guild does not exist
		return RMXOS::Result::GUILD_NOT_EXIST if check.num_rows == 0
		# prepare yes/no action
		hash = check.fetch_hash
		messages = Action::MessagePack.new(RMXOS::Data::PasswordForcing_ENTITY, RMXOS::Data::PasswordChanged, RMXOS::Data::PasswordNoChange, @args)
		self.create_action(Action::TYPE_FORCED_GUILD_PASSWORD_CHANGE, [hash['guild_id'].to_i, guildname, password], messages)
		return RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Executes a password change.
	#  action - the action object for this action
	#----------------------------------------------------------------------
	def execute_forced_password_change(action)
		# change password
		user_id, username, password = action.data
		RMXOS.server.sql.query("UPDATE users SET password = '#{RMXOS.sql_string(password)}' WHERE user_id = #{user_id}")
		# log this action if action log is turned on
		if RMXOS.server.options.log_actions
			RMXOS.log(@client.player, 'Action', "user password change: #{user_id} (#{username})")
		end
		return RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Executes a guild password change.
	#  action - the action object for this action
	#----------------------------------------------------------------------
	def execute_forced_guild_password_change(action)
		# change password
		guild_id, guildname, password = action.data
		RMXOS.server.sql.query("UPDATE guilds SET password = '#{RMXOS.sql_string(password)}' WHERE guild_id = #{guild_id}")
		# log this action if action log is turned on
		if RMXOS.server.options.log_actions
			RMXOS.log(@client.player, 'Action', "guild password change: #{guild_id} (#{guildname})")
		end
		return RMXOS::Result::SUCCESS
	end

end
