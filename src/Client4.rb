#==========================================================================
# Client
#--------------------------------------------------------------------------
# Serves as server side connection for clients.
# Processes all commands that use the result subsystem.
#==========================================================================

class Client
	
	#----------------------------------------------------------------------
	# Processes an action result.
	#  code - result code
	#  confirmation - whether a "Are you sure?" message is appended
	#----------------------------------------------------------------------
	def _process_result(code, confirmation = false)
		# if not special ignore result
		if code != RMXOS::Result::IGNORE
			# get the appropriate message and color for the result
			result = RMXOS::Result.process(code, @action.message, @action.args, confirmation)
			# send message
			self.send_chat(result.color, result.message)
		end
	end
	#----------------------------------------------------------------------
	# Processes an action result for failed actions only.
	#  code - result code
	#  confirmation - whether a "Are you sure?" message is appended
	#----------------------------------------------------------------------
	def _process_fail_result(code, confirmation = false)
		self._process_result(code, confirmation) if code != RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Answers YES to a certain action.
	#  action_id - ID of the action
	#----------------------------------------------------------------------
	def _yes(action_id)
		self._process_fail_result(@action.execute_yes(action_id))
	end
	#----------------------------------------------------------------------
	# Answers NO to a certain action.
	#  action_id - ID of the action
	#----------------------------------------------------------------------
	def _no(action_id)
		self._process_fail_result(@action.execute_no(action_id))
	end
	#----------------------------------------------------------------------
	# Cancels a sent action.
	#  action_id - ID of the action
	#----------------------------------------------------------------------
	def _cancel(action_id)
		self._process_fail_result(@action.try_cancel_sent_action(action_id))
	end
	#----------------------------------------------------------------------
	# Kicks all players from the server.
	#----------------------------------------------------------------------
	def _kick_all
		# try to kick all players
		code = @action.try_kick_all
		# log this action if action log is turned on
		self._log_action(code, 'kick all')
		# process result
		self._process_result(code)
	end
	#----------------------------------------------------------------------
	# Forcibly changes the password of another
	# user.
	#  username - username of the player who's password will be changed
	#  password - new password
	#----------------------------------------------------------------------
	def _change_player_password(username, password)
		# prepare everything for password change
		code = @action.prepare_forced_password_change(username, password)
		# log this action if action log is turned on
		self._log_action(code, "password change player: #{username}")
		# try to change the password
		self._process_result(code, true)
	end
	#----------------------------------------------------------------------
	# Forcibly changes the password of a guild.
	#  guildname - name of the guild which's password will be changed
	#  password - new password
	#----------------------------------------------------------------------
	def _change_guild_password(guildname, password)
		# prepare everything for guild password change
		code = @action.prepare_forced_guild_password_change(guildname, password)
		# log this action if action log is turned on
		self._log_action(code, "password change guild: #{guildname}")
		# try to change the password
		self._process_result(code, true)
	end
	#----------------------------------------------------------------------
	# Changes a player's usergroup.
	#  username  - username
	#  usergroup - new usergroup
	#----------------------------------------------------------------------
	def _change_player_usergroup(username, usergroup)
		# try to change user group of player
		code = @action.try_group_change(username, usergroup)
		# log this action if action log is turned on
		self._log_action(code, "change usergroup: #{username}")
		# process result
		self._process_result(code)
	end
	#----------------------------------------------------------------------
	# Sends a script for evaluation to all clients.
	#  script - the Ruby script
	#----------------------------------------------------------------------
	def _global_eval(script)
		# try to send script
		code = @action.try_global_eval(script)
		# log this action if action log is turned on
		self._log_action(code, "global eval: #{script}")
		# process result
		self._process_fail_result(code)
	end
	#----------------------------------------------------------------------
	# Evaluates a Ruby script on the server.
	#  script - the Ruby script
	#----------------------------------------------------------------------
	def _server_eval(script)
		# try to execute Ruby script
		code = @action.try_server_eval(script)
		# log this action if action log is turned on
		self._log_action(code, "server eval: #{script}")
		# process result
		self._process_result(code)
	end
	#----------------------------------------------------------------------
	# Evaluates a SQL script on the server.
	#  script - the SQL script
	#----------------------------------------------------------------------
	def _sql(script)
		# try to execute SQL script
		code = @action.try_sql(script)
		# log this action if action log is turned on
		self._log_action(code, "server SQL: #{script}")
		# process result
		self._process_result(code)
	end
	#----------------------------------------------------------------------
	# Kicks a certain player.
	#  username - username
	#----------------------------------------------------------------------
	def _kick_player(username)
		# try to kick the player
		code = @action.try_kick(username)
		# log this action if action log is turned on
		self._log_action(code, "kick: #{username}")
		# process result
		self._process_result(code)
	end
	#----------------------------------------------------------------------
	# Bans a player.
	#  username - username
	#----------------------------------------------------------------------
	def _ban_player(username)
		# try to ban
		code = @action.try_ban(username)
		# log this action if action log is turned on
		self._log_action(code, "ban: #{username}")
		# process result
		self._process_result(code)
	end
	#----------------------------------------------------------------------
	# Unbans a player.
	#  username - username
	#----------------------------------------------------------------------
	def _unban_player(username)
		# try to unban
		code = @action.try_unban(username)
		# log this action if action log is turned on
		self._log_action(code, "unban: #{username}")
		# process result
		self._process_result(code)
	end
	#----------------------------------------------------------------------
	# Sends a global chat message.
	#  message - the chat message
	#----------------------------------------------------------------------
	def _global_chat(message)
		# try to send global chat message
		code = @action.try_global_chat(message)
		# log this action if action log is turned on
		self._log_action(code, "global message: #{message}")
		# process result
		self._process_fail_result(code)
	end
	#----------------------------------------------------------------------
	# Sends a whisper message.
	#  username - username of the sending player
	#  color    - color of the chat message
	#  user_id  - user ID of the player that will receive the message
	#  message  - chat message
	#----------------------------------------------------------------------
	def _whisper(username, color, user_id, message)
		self._process_fail_result(@action.try_whisper_chat(username, RMXOS.make_message('CHT', color, user_id, message)))
	end
	#----------------------------------------------------------------------
	# Changes the password.
	#  oldpass - old password used for confirmation
	#  newpass - new password
	#----------------------------------------------------------------------
	def _change_password(oldpass, newpass)
		self._process_result(@action.prepare_password_change(oldpass, newpass), true)
	end
	#----------------------------------------------------------------------
	# Adds a player to one's buddy list.
	#  username - username of the player to add
	#----------------------------------------------------------------------
	def _buddy_add(username)
		self._process_result(@action.prepare_buddy_add(username))
	end
	#----------------------------------------------------------------------
	# Removes a player from one's buddy list.
	#  username - username of the player to remove
	#----------------------------------------------------------------------
	def _buddy_remove(username)
		self._process_result(@action.prepare_buddy_remove(username), true)
	end
	#----------------------------------------------------------------------
	# Sends a PM.
	#  username - username of the player who will receive the message
	#  message - personal message
	#----------------------------------------------------------------------
	def _pm_send(username, message)
		self._process_result(@action.try_pm_send(username, message))
	end
	#----------------------------------------------------------------------
	# Deletes a PM.
	#  pm_id - ID of the PM
	#----------------------------------------------------------------------
	def _pm_delete(pm_id)
		self._process_result(@action.prepare_pm_delete(pm_id), true)
	end
	#----------------------------------------------------------------------
	# Delete all PMs.
	#----------------------------------------------------------------------
	def _pm_delete_all
		self._process_result(@action.prepare_pm_delete_all, true)
	end
	#----------------------------------------------------------------------
	# Sends a trade request to another player.
	#  username - username of the player requested te trade
	#----------------------------------------------------------------------
	def _trade_request(username)
		self._process_result(@action.prepare_trade_request(username))
	end
	#----------------------------------------------------------------------
	# Creates a guild.
	#  guildname - guild name
	#  password - guild password of the guild
	#----------------------------------------------------------------------
	def _guild_create(guildname, password)
		self._process_result(@action.try_guild_create(guildname, password))
	end
	#----------------------------------------------------------------------
	# Changes a guild password.
	#  oldpass - old guild password used for confirmation
	#  newpass - new guild password
	#----------------------------------------------------------------------
	def _guild_change_password(oldpass, newpass)
		self._process_result(@action.prepare_guild_password_change(oldpass, newpass), true)
	end
	#----------------------------------------------------------------------
	# Disbands one's build.
	#  password - guild password used for confirmation
	#----------------------------------------------------------------------
	def _guild_disband(password)
		self._process_result(@action.prepare_guild_disband(password), true)
	end
	#----------------------------------------------------------------------
	# Transfers guild ownership to another player.
	#  username - username of the new guild leader
	#  password - guild password used for confirmation
	# Note: Before transferring a guild to another player, it might be a
	#       good idea to change the password to something neutral.
	#----------------------------------------------------------------------
	def _guild_transfer(username, password)
		self._process_result(@action.prepare_guild_transfer(username, password))
	end
	#----------------------------------------------------------------------
	# Invites a player into one's guild.
	#  username - username of the new member
	#----------------------------------------------------------------------
	def _guild_invite(username)
		self._process_result(@action.prepare_guild_invite(username))
	end
	#----------------------------------------------------------------------
	# Removes a member from the guild.
	#  username - username of the player to be removed
	#  password - guild password used for confirmation
	#----------------------------------------------------------------------
	def _guild_remove_member(username, password)
		self._process_result(@action.prepare_guild_remove_member(username, password))
	end
	#----------------------------------------------------------------------
	# Leaves current guild.
	#  password - player password used for confirmation
	#----------------------------------------------------------------------
	def _guild_leave(password)
		self._process_result(@action.prepare_guild_leave(password), true)
	end

end
