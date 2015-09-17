#==========================================================================
# ActionHandler
#--------------------------------------------------------------------------
# Defines general structure.
#==========================================================================

class ActionHandler
	
	# mutex
	@@mutex = nil
	def self.reset
		@@mutex = Mutex.new
	end
	@@action_id = 0
	
	# setting all accessible variables
	attr_reader   :pending
	attr_reader   :sent
	
	#----------------------------------------------------------------------
	# Initialization.
	#----------------------------------------------------------------------
	def initialize(client)
		@client = client
		@pending = []
		@sent = []
		@message = nil
		@args = nil
	end
	#----------------------------------------------------------------------
	# Generates a new action ID.
	# Returns: New action ID.
	#----------------------------------------------------------------------
	def _generate_id
		@@action_id += 1
		return @@action_id
	end
	#----------------------------------------------------------------------
	# Gets all currently active actions
	# Returns: All currently active actions.
	#----------------------------------------------------------------------
	def get_actions
		@@mutex.synchronize {
			return (@sent + @pending)
		}
	end
	#----------------------------------------------------------------------
	# Gets the last success action message.
	# Returns: Last success action message.
	#----------------------------------------------------------------------
	def message
		message = @message
		@message = nil
		return (message != nil ? message : '')
	end
	#----------------------------------------------------------------------
	# Gets the message action arguments.
	# Returns: Message action arguments.
	#----------------------------------------------------------------------
	def args
		args = @args
		@args = nil
		return (args != nil ? args : {})
	end
	#----------------------------------------------------------------------
	# Gets the message action arguments.
	#  message - default success message
	#  args - the arguments for the message
	#----------------------------------------------------------------------
	def set_data(message, args)
		@message = RMXOS::Data.args(message, args)
		@args = args
	end
	#----------------------------------------------------------------------
	# Clears the message action arguments.
	#----------------------------------------------------------------------
	def clear_data
		@message = nil
		@args = nil
	end
	#----------------------------------------------------------------------
	# Creates a pending action for this player.
	#  type - type of the action
	#  data - special data required by the action
	#  messages - MessagePack object with result messages
	#----------------------------------------------------------------------
	def create_action(type, data, messages)
		@@mutex.synchronize {
			self._create_action(type, data, messages)
		}
	end
	def _create_action(type, data, messages)
		id = self._generate_id
		messages.display = "(ID: #{sprintf("%X", id)}) " + messages.display if messages.display != ''
		@message = messages.display
		action = ActionPending.new(id, type, messages, data, @client.player.user_id)
		old_action = @pending.find {|a| a.type == action.type}
		@pending.push(action)
		self._cancel_pending_action(old_action, false) if old_action != nil
	end
	#----------------------------------------------------------------------
	# Creates a sent action for this player and pending actions for all
	# other players involved in this interactive action.
	#  type - type of the action
	#  sender_messages - MessagePack object with result messages for the
	#                    sender
	#  clients - all other clients
	#  data - special data required by the action for the other client
	#  messages - MessagePack object with result messages for the other
	#             client
	#----------------------------------------------------------------------
	def create_interaction(type, sender_messages, clients, data, messages)
		@@mutex.synchronize {
			self._create_interaction(type, sender_messages, clients, data, messages)
		}
	end
	def _create_interaction(type, sender_messages, clients, data, messages)
		id = self._generate_id
		id_text = "(ID: #{sprintf("%X", id)}) "
		# sender messages
		sender_messages.display = id_text + sender_messages.display if sender_messages.display != ''
		# create sent action
		action = ActionSent.new(id, type, sender_messages, clients.map {|client| client = client.player.user_id})
		self._replace_sent_action(action)
		# receiver messages
		messages.display = id_text + messages.display if messages.display != ''
		# create and send necessary messages
		clients.each {|client|
			action = ActionPending.new(id, type, messages, data, @client.player.user_id)
			client.action._add_pending_action(action)
			client.send_chat(RMXOS::Data::ColorInfo, messages.display)
		}
		# store variables for after processing
		@message = sender_messages.display
	end
	#----------------------------------------------------------------------
	# Finds the corresponding sent action if it exists.
	#  action_id - the action_id
	# Returns: Found sent action or nil.
	#----------------------------------------------------------------------
	def find_sent_action(action_id)
		@@mutex.synchronize {
			return self._find_sent_action(action_id)
		}
	end
	def _find_sent_action(action_id)
		return @sent.find {|a| a.action_id == action_id}
	end
	#----------------------------------------------------------------------
	# Finds the corresponding pending action if it exists.
	#  action_id - the action_id
	# Returns: Found pending action or nil.
	#----------------------------------------------------------------------
	def find_pending_action(action_id)
		@@mutex.synchronize {
			return self._find_pending_action(action_id)
		}
	end
	def _find_pending_action(action_id)
		return @pending.find {|a| a.action_id == action_id}
	end
	#----------------------------------------------------------------------
	# Replaces a sent action of the same type if it exists.
	#  action - the sent action
	# Returns: True if previous action existed.
	#----------------------------------------------------------------------
	def replace_sent_action(action)
		@@mutex.synchronize {
			return self._replace_sent_action(action)
		}
	end
	def _replace_sent_action(action)
		old_action = @sent.find {|a| a.type == action.type}
		@sent.push(action)
		if old_action != nil
			self._cancel_sent_action(old_action, false)
			return true
		end
		return false
	end
	#----------------------------------------------------------------------
	# Adds a pending action.
	#  action - the pending action
	#----------------------------------------------------------------------
	def add_pending_action(action)
		@@mutex.synchronize {
			self._add_pending_action(action)
		}
	end
	def _add_pending_action(action)
		@pending.push(action)
	end
	#----------------------------------------------------------------------
	# Finishes an action and removes all related data from the server.
	#  action - the processed pending action
	#----------------------------------------------------------------------
	def finish_pending_action(action)
		@@mutex.synchronize {
			self._finish_pending_action(action)
		}
	end
	def _finish_pending_action(action)
		client = RMXOS.clients.get_by_id(action.sender_id)
		if client != nil && client != @client
			client.action._remove_sent_action(client.action._find_sent_action(action.action_id))
		end
		self._remove_pending_action(action)
	end
	#----------------------------------------------------------------------
	# Removes an action from the queue.
	#  action - the action
	# Note: Usually used in conjuction with other processing.
	#----------------------------------------------------------------------
	def remove_sent_action(action)
		@@mutex.synchronize {
			self._remove_sent_action(action)
		}
	end
	def _remove_sent_action(action)
		@sent.delete(action) if action != nil && @sent.include?(action)
	end
	#----------------------------------------------------------------------
	# Removes an action from the queue.
	#  action - the action
	# Note: Usually used in conjuction with other processing.
	#----------------------------------------------------------------------
	def remove_pending_action(action)
		@@mutex.synchronize {
			self._remove_pending_action(action)
		}
	end
	def _remove_pending_action(action)
		@pending.delete(action) if action != nil && @pending.include?(action)
	end
	#----------------------------------------------------------------------
	# Cancels a sent action.
	#  action - the action
	#  notify - whether to notify the player
	#----------------------------------------------------------------------
	def cancel_sent_action(action, notify = true)
		@@mutex.synchronize {
			self._cancel_sent_action(action, notify)
		}
	end
	def _cancel_sent_action(action, notify = true)
		self._remove_sent_action(action)
		clients = RMXOS.clients.get.find_all {|client| action.user_ids.include?(client.player.user_id)}
		clients.each {|client|
			other_action = client.action._find_pending_action(action.action_id)
			client.action._cancel_pending_action(other_action) if other_action != nil
		}
		if notify
			@client.send_chat(RMXOS::Data::ColorNo, RMXOS::Data.args(RMXOS::Data::ActionCanceled_ACTION,
				{'ACTION' => action.messages.display}))
		end
	end
	#----------------------------------------------------------------------
	# Cancels a pending action.
	#  action - the action
	#  notify - whether to notify the player
	#----------------------------------------------------------------------
	def cancel_pending_action(action, notify = true)
		@@mutex.synchronize {
			self._cancel_pending_action(action, notify)
		}
	end
	def _cancel_pending_action(action, notify = true)
		self._remove_pending_action(action)
		if notify
			@client.send_chat(RMXOS::Data::ColorNo, RMXOS::Data.args(RMXOS::Data::ActionCanceled_ACTION,
				{'ACTION' => action.messages.display}))
		end
	end
	#----------------------------------------------------------------------
	# Executes YES on the last action.
	#----------------------------------------------------------------------
	def make_accept_message(message, args = {})
		return "#{RMXOS::Data.args(message, args)} #{RMXOS::Data::DoYouAccept}"
	end
	#----------------------------------------------------------------------
	# Tries to send a YES message if it exists
	#  action - action of the YES message
	#----------------------------------------------------------------------
	def try_send_yes(action)
		if action.messages.yes != nil && action.messages.yes != ''
			@client.send_chat(RMXOS::Data::ColorOk, action.messages.yes)
		end
	end
	#----------------------------------------------------------------------
	# Tries to send a NO message if it exists
	#  action - action of the NO message
	#----------------------------------------------------------------------
	def try_send_no(action)
		if action.messages.no != nil && action.messages.no != ''
			@client.send_chat(RMXOS::Data::ColorNo, action.messages.no)
		end
	end
	#----------------------------------------------------------------------
	# Executes YES on the last action.
	#  action_id - ID of the action
	# Returns: Action result of this action.
	#----------------------------------------------------------------------
	def execute_yes(action_id)
		@@mutex.synchronize {
			return self._execute_yes(action_id)
		}
	end
	def _execute_yes(action_id)
		@args = {'ACTIONID' => sprintf('%X', action_id)}
		action = self._find_pending_action(action_id)
		return RMXOS::Result::NO_ACTION_ID if action == nil
		# process action based on type
		code = case action.type
		when Action::TYPE_FORCED_PASSWORD_CHANGE		then self.execute_forced_password_change(action)
		when Action::TYPE_FORCED_GUILD_PASSWORD_CHANGE	then self.execute_forced_guild_password_change(action)
		when Action::TYPE_PASSWORD_CHANGE				then self.execute_password_change(action)
		when Action::TYPE_BUDDY_ADD						then self.execute_buddy_add(action)
		when Action::TYPE_BUDDY_REMOVE					then self.execute_buddy_remove(action)
		when Action::TYPE_PM_DELETE						then self.execute_pm_delete(action)
		when Action::TYPE_PM_DELETE_ALL					then self.execute_pm_delete_all(action)
		when Action::TYPE_TRADE_REQUEST					then self.execute_trade_request(action)
		when Action::TYPE_GUILD_PASSWORD_CHANGE			then self.execute_guild_password_change(action)
		when Action::TYPE_GUILD_DISBAND					then self.execute_guild_disband(action)
		when Action::TYPE_GUILD_TRANSFER				then self.execute_guild_transfer(action)
		when Action::TYPE_GUILD_JOIN					then self.execute_guild_join(action)
		when Action::TYPE_GUILD_LEAVE					then self.execute_guild_leave(action)
		when Action::TYPE_GUILD_REMOVE					then self.execute_guild_remove_member(action)
		else
			# execute a custom response
			self.execute_custom_yes(action)
		end
		# try to send a YES message for this action
		self.try_send_yes(action)
		client = RMXOS.clients.get_by_id(action.sender_id)
		if client != nil
			sender_action = client.action._find_sent_action(action.action_id)
			client.action.try_send_yes(sender_action) if sender_action != nil
		end
		# finish action depending on success code
		case code
		when RMXOS::Result::SUCCESS
			self._finish_pending_action(action)
		when RMXOS::Result::NO_ACTION
			self._remove_pending_action(action)
		when RMXOS::Result::WAIT_ACTION
			self._remove_pending_action(action)
			code = RMXOS::Result::SUCCESS
		end
		return code
	end
	#----------------------------------------------------------------------
	# Executes NO on the last action.
	#  action_id - ID of the action
	# Returns: Action result of this action.
	#----------------------------------------------------------------------
	def execute_no(action_id)
		@@mutex.synchronize {
			return self._execute_no(action_id)
		}
	end
	def _execute_no(action_id)
		@args = {'ACTIONID' => sprintf('%X', action_id)}
		action = self._find_pending_action(action_id)
		return RMXOS::Result::NO_ACTION_ID if action == nil
		code = RMXOS::Result::SUCCESS
		# determine type validity of action
		case action.type
		when Action::TYPE_FORCED_PASSWORD_CHANGE
		when Action::TYPE_FORCED_GUILD_PASSWORD_CHANGE
		when Action::TYPE_PASSWORD_CHANGE
		when Action::TYPE_BUDDY_ADD
		when Action::TYPE_BUDDY_REMOVE
		when Action::TYPE_PM_DELETE
		when Action::TYPE_PM_DELETE_ALL
		when Action::TYPE_TRADE_REQUEST
		when Action::TYPE_GUILD_PASSWORD_CHANGE
		when Action::TYPE_GUILD_DISBAND
		when Action::TYPE_GUILD_TRANSFER
		when Action::TYPE_GUILD_JOIN
		when Action::TYPE_GUILD_LEAVE
		when Action::TYPE_GUILD_REMOVE
		else
			# execute a custom response
			code = self.execute_custom_no(action)
		end
		# try to send a NO message for this action
		self.try_send_no(action)
		client = RMXOS.clients.get_by_id(action.sender_id)
		if client != nil
			sender_action = client.action._find_sent_action(action.action_id)
			client.action.try_send_no(sender_action) if sender_action != nil
		end
		# process action depending on success code
		case code
		when RMXOS::Result::SUCCESS
			self._finish_pending_action(action)
		when RMXOS::Result::NO_ACTION
			self._remove_pending_action(action)
		when RMXOS::Result::WAIT_ACTION
			self._remove_pending_action(action)
			code = RMXOS::Result::SUCCESS
		end
		return code
	end
	#----------------------------------------------------------------------
	# Executes a custom YES respons on an action.
	#  action - the action
	# Returns: Action result of this action.
	# Note: This is the method you should alias when creating an server
	#       extension that handles custom actions.
	#----------------------------------------------------------------------
	def execute_custom_yes(action)
		return RMXOS::Result::NO_ACTION
	end
	#----------------------------------------------------------------------
	# Executes a custom NO respons on an action.
	#  action - the action
	# Returns: Action result of this action.
	# Note: This is the method you should alias when creating an server
	#       extension that handles custom actions.
	#----------------------------------------------------------------------
	def execute_custom_no(action)
		return RMXOS::Result::NO_ACTION
	end

end
