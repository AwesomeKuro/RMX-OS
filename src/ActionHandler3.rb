#==========================================================================
# ActionHandler
#--------------------------------------------------------------------------
# Handles all extended actions.
#==========================================================================

class ActionHandler
	
	#----------------------------------------------------------------------
	# Prepares adding a buddy from the buddy list.
	#  username - username of the new buddy
	# Returns: Action result of this action.
	#----------------------------------------------------------------------
	def prepare_buddy_add(username)
		# normal processing continues
		@args = {'PLAYER' => username}
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
		@@mutex.synchronize {
			# check already existing actions first
			actions = @pending.find_all {|action| action.type == Action::TYPE_BUDDY_ADD && action.sender_id == client.player.user_id}
			if actions.size > 0 # there is already a buddy request from this player
				actions.each {|action| self._execute_yes(action.action_id)}
				self.clear_data
				return RMXOS::Result::IGNORE
			end
			# prepare invitation
			sender_messages = Action::MessagePack.new(RMXOS::Data::BuddyAdding_PLAYER,
				RMXOS::Data::BuddyAdded_PLAYER, RMXOS::Data::BuddyNoAdd_PLAYER, @args)
			messages = Action::MessagePack.new(RMXOS::Data::BuddyAdd_PLAYER,
				RMXOS::Data::BuddyAdded_PLAYER, RMXOS::Data::BuddyNoAdd, {'PLAYER' => @client.player.username})
			self._create_interaction(Action::TYPE_BUDDY_ADD, sender_messages, [client], @client.player.username, messages)
		}
		return RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Prepares removing a buddy from the buddy list.
	#  username - username of the buddy to be removed
	# Returns: Action result of this action.
	#----------------------------------------------------------------------
	def prepare_buddy_remove(username)
		@args = {'PLAYER' => username}
		# get user data
		check = RMXOS.server.sql.query("SELECT user_id FROM users WHERE username = '#{RMXOS.sql_string(username)}'")
		hash = check.fetch_hash
		# create action
		messages = Action::MessagePack.new(RMXOS::Data::BuddyRemoving_PLAYER,
			RMXOS::Data::BuddyRemove_PLAYER, RMXOS::Data::BuddyNoRemove_PLAYER, @args)
		self.create_action(Action::TYPE_BUDDY_REMOVE, [hash['user_id'].to_i, username], messages)
		# prepare yes/no action
		return RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Executes requesting a trade with a player.
	#  username - username of the other player
	# Returns: Action result of this action.
	#----------------------------------------------------------------------
	def prepare_trade_request(username)
		@args = {'PLAYER' => username}
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
		@@mutex.synchronize {
			# check already existing actions first
			actions = @pending.find_all {|action| action.type == Action::TYPE_TRADE_REQUEST && action.sender_id == client.player.user_id}
			if actions.size > 0 # there is already a buddy request from this player
				actions.each {|action| self._execute_yes(action.action_id)}
				self.clear_data
				return RMXOS::Result::IGNORE
			end
			# prepare request
			sender_messages = Action::MessagePack.new(RMXOS::Data::TradeRequested_PLAYER,
				'', RMXOS::Data::TradeNoRequest_PLAYER, @args)
			receiver_messages = Action::MessagePack.new(RMXOS::Data::TradeRequest_PLAYER,
				'', RMXOS::Data::TradeNoRequest, {'PLAYER' => @client.player.username})
			self._create_interaction(Action::TYPE_TRADE_REQUEST, sender_messages, [client], nil, receiver_messages)
		}
		return RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Executes adding a buddy from the buddy list.
	#  action - the action object for this action
	#----------------------------------------------------------------------
	def execute_buddy_add(action)
		username = action.data
		# add to buddy list
		RMXOS.server.sql.query("INSERT INTO buddy_list (user1_id, user2_id) VALUES (#{action.sender_id}, #{@client.player.user_id})")
		# notify this player
		@client.send('BAD', username)
		@client.player.buddies.push(username)
		# find the player if he's online
		client = RMXOS.clients.get_by_id(action.sender_id)
		# if client is still online
		if client != nil
			# notify other player of new buddy
			client.send('BAD', @client.player.username)
			client.player.buddies.push(@client.player.username)
		end
		return RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Executes removing a buddy from the buddy list.
	#  action - the action object for this action
	#----------------------------------------------------------------------
	def execute_buddy_remove(action)
		user_id, username = action.data
		# delete from buddy list
		RMXOS.server.sql.query("DELETE FROM buddy_list WHERE user1_id = #{@client.player.user_id} AND user2_id = #{user_id} " + 
				"OR user1_id = #{user_id} AND user2_id = #{@client.player.user_id}")
		# notify this player
		@client.send('BRE', username)
		@client.player.buddies.delete(username)
		# find the player if he's online
		client = RMXOS.clients.get_by_id(user_id)
		# if client is still online
		message = RMXOS::Data.args(RMXOS::Data::BuddyRemove_PLAYER, {'PLAYER' => @client.player.username})
		if client != nil
			# clear already existing actions first
			actions = client.action.pending.find_all {|action| action.type == Action::TYPE_BUDDY_REMOVE && action.data[0] == @client.player.user_id}
			actions.each {|action| client.action._cancel_pending_action(action, false)}
			# notify other player that he lost a buddy
			client.send('BRE', @client.player.username)
			client.player.buddies.delete(@client.player.username)
			client.send_chat(RMXOS::Data::ColorInfo, message)
		else
			@client.try_pm_send(username, message, RMXOS::Data::Server)
		end
		return RMXOS::Result::SUCCESS
	end
	#----------------------------------------------------------------------
	# Executes a trade request to start the trade.
	#  action - the action object for this action
	#----------------------------------------------------------------------
	def execute_trade_request(action)
		# cancel other trade requests
		actions = @sent.find_all {|action| action.type == Action::TYPE_TRADE_REQUEST}
		actions.each {|action| self._cancel_sent_request(action.action_id)}
		# notify this player to begin the trade
		@client.send('TRS', 0, action.sender_id)
		# notify other player to begin the trade, other player is the host
		@client.sender.send_to_id(action.sender_id, RMXOS.make_message('TRS', 1, @client.player.user_id))
		return RMXOS::Result::SUCCESS
	end

end
