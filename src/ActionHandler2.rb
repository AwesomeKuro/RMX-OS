#==========================================================================
# ActionHandler
#--------------------------------------------------------------------------
# Handles all basic actions.
#==========================================================================

class ActionHandler
	
	#----------------------------------------------------------------------
	# Changes the user password.
	#  oldpass - old encrypted password
	#  newpass - new encrypted password
	# Returns: Action result of this action.
	#----------------------------------------------------------------------
	def prepare_password_change(oldpass, newpass)
		@args = {}
		check = RMXOS.server.sql.query("SELECT password FROM users WHERE user_id = #{@client.player.user_id}")
		hash = check.fetch_hash
		# password check
		return RMXOS::Result::PASSWORD_INCORRECT if oldpass != hash['password']
		# if password is the same
		return RMXOS::Result::PASSWORD_SAME if oldpass == newpass
		# prepare yes/no action
		messages = Action::MessagePack.new(RMXOS::Data::PasswordChanging, RMXOS::Data::PasswordChanged, RMXOS::Data::PasswordNoChange, @args)
		self.create_action(Action::TYPE_PASSWORD_CHANGE, newpass, messages)
		return RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Executes deletion of a PM.
	#  pm_id - ID of the PM to be deleted
	# Returns: Action result of this action.
	#----------------------------------------------------------------------
	def prepare_pm_delete(pm_id)
		@args = {'MESSAGEID' => pm_id.to_s}
		check = RMXOS.server.sql.query("SELECT unread FROM inbox WHERE recipient_id = #{@client.player.user_id} AND pm_id = #{pm_id}")
		# PM does not exist
		return RMXOS::Result::PM_NOT_EXIST if check.num_rows == 0
		hash = check.fetch_hash
		# prepare yes/no action
		messages = Action::MessagePack.new(RMXOS::Data::PMDeleting_MESSAGEID, RMXOS::Data::PMDeleted_MESSAGEID,
			RMXOS::Data::PMNoDeletion, @args)
		self.create_action(Action::TYPE_PM_DELETE, pm_id, messages)
		# PM is unread
		return RMXOS::Result::PM_UNREAD if hash['unread'] != '0'
		return RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Executes deletion of all PMs.
	# Returns: Action result of this action.
	#----------------------------------------------------------------------
	def prepare_pm_delete_all
		@args = {}
		check = RMXOS.server.sql.query("SELECT COUNT(*) AS count FROM inbox WHERE recipient_id = #{@client.player.user_id}")
		hash = check.fetch_hash
		# inbox already empty
		return RMXOS::Result::PM_INBOX_EMPTY if hash['count'].to_i == 0
		check = RMXOS.server.sql.query("SELECT COUNT(*) AS count FROM inbox WHERE recipient_id = #{@client.player.user_id} AND unread = 1")
		hash = check.fetch_hash
		# prepare yes/no action
		messages = Action::MessagePack.new(RMXOS::Data::PMDeletingAll, RMXOS::Data::PMDeletedAll,
			RMXOS::Data::PMNoDeletion, @args)
		self.create_action(Action::TYPE_PM_DELETE_ALL, nil, messages)
		# inbox has unread PMs
		return RMXOS::Result::PM_UNREAD_ALL if hash['count'].to_i > 0
		return RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Executes a password change.
	#  action - the action object for this action
	#----------------------------------------------------------------------
	def execute_password_change(action)
		# change password
		newpass = action.data
		RMXOS.server.sql.query("UPDATE users SET password = '#{RMXOS.sql_string(newpass)}' WHERE user_id = #{@client.player.user_id}")
		# log this action if action log is turned on
		if RMXOS.server.options.log_actions
			RMXOS.log(@client.player, 'Action', "user password change: #{@client.player.user_id} (#{@client.player.username})")
		end
		return RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Executes deletion of a PM.
	#  action - the action object for this action
	#----------------------------------------------------------------------
	def execute_pm_delete(action)
		pm_id = action.data
		RMXOS.server.sql.query("DELETE FROM inbox WHERE pm_id = #{pm_id}")
		return RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Executes deletion of all PMs.
	#  action - the action object for this action
	#----------------------------------------------------------------------
	def execute_pm_delete_all(action)
		RMXOS.server.sql.query("DELETE FROM inbox WHERE recipient_id = #{@client.player.user_id}")
		return RMXOS::Result::SUCCESS
	end

end
