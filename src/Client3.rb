#==========================================================================
# Client
#--------------------------------------------------------------------------
# Serves as server side connection for clients.
# Processes all immediately executed commands which may have expected
# alternative results.
#==========================================================================

class Client
	
	#----------------------------------------------------------------------
	# Tries to connect to the server.
	#  version - RMX-OS version of the client
	#  game_version - game version of the client
	# Note: The success result is sent back to the client.
	#----------------------------------------------------------------------
	def _connection_request(version, game_version)
		# version not high enough
		if version < RMXOS_VERSION
			result = RMXOS::Result::SERVER_VERSION_MISMATCH
		# version not high enough
		elsif game_version < GAME_VERSION
			result = RMXOS::Result::GAME_VERSION_MISMATCH
		# server is full
		elsif RMXOS.clients.get.size >= MAXIMUM_CONNECTIONS
			result = RMXOS::Result::DENIED
		# connection successful
		else
			result = RMXOS::Result::SUCCESS
		end
		self.send('CON', result, RMXOS_VERSION, GAME_VERSION)
	end
	#----------------------------------------------------------------------
	# Attempts a logging into an account.
	#  username - username of the player
	#  password - corresponding password
	#----------------------------------------------------------------------
	def _connection_login(username, password)
		# try login
		result = self.try_login(username, password)
		# if successful
		if result == RMXOS::Result::SUCCESS
			# send user data
			self.send('UID', @player.get_login_data)
			# send guild data
			if @player.guildname != ''
				self.send('GIN', @player.get_guild_data)
			end
		end
		self.send('LIN', result)
	end
	#----------------------------------------------------------------------
	# Attempts registering a new account.
	#  username - username
	#  password - corresponding password
	#----------------------------------------------------------------------
	def _connection_register(username, password)
		# try to register account
		code = self.try_register(username, password)
		# if successful
		if code == RMXOS::Result::SUCCESS
			# log in as well
			self.try_login(username, password)
			# send user data
			self.send('UID', @player.get_login_data)
			# send guild data
			if @player.guildname != ''
				self.send('GIN', @player.get_guild_data)
			end
		end
		self.send('REG', code)
	end
	#----------------------------------------------------------------------
	# Cancels a sent action.
	#  action_id - ID of the action
	#----------------------------------------------------------------------
	def _req
		actions = @action.get_actions
		if actions.size > 0
			self.send_chat(RMXOS::Data::ColorInfo, RMXOS::Data::PendingActions)
			# send a message for every request
			actions.each {|action| self.send_chat(RMXOS::Data::ColorInfo, action.messages.display)}
		else
			# let player know that there are no requests
			self.send_chat(RMXOS::Data::ColorInfo, RMXOS::Data::NoPendingAction)
		end
	end
	#----------------------------------------------------------------------
	# Gets a PM's text.
	#  pm_id - ID of the PM
	#----------------------------------------------------------------------
	def _pm_open(pm_id)
		code = RMXOS::Result::SUCCESS
		check = RMXOS.server.sql.query("SELECT sendername, senddate, message FROM inbox WHERE recipient_id = #{@player.user_id} AND pm_id = #{pm_id}")
		if check.num_rows == 0
			@action.set_data('', {'MESSAGEID' => pm_id.to_s})
			self._process_result(RMXOS::Result::PM_NOT_EXIST)
			return
		end
		hash = check.fetch_hash
		RMXOS.server.sql.query("UPDATE inbox SET unread = 0 WHERE pm_id = #{pm_id}")
		self.send('PMO', hash['sendername'], RMXOS.get_rubytime(hash['senddate']), hash['message'])
	end
	#----------------------------------------------------------------------
	# Aborts a trade because something went wrong.
	#----------------------------------------------------------------------
	def __trade_abort
		self.send('TCA')
		self.send_chat(RMXOS::Data::ColorInfo, RMXOS::Data::TradeCanceled)
	end
	#----------------------------------------------------------------------
	# Confirms a trade.
	#  user_id - user ID of the other player
	#----------------------------------------------------------------------
	def _trade_confirm(user_id)
		# abort if trade confirm message could not be delivered
		self.__trade_abort if !@sender.send_to_id(user_id, 'TCO')
	end
	#----------------------------------------------------------------------
	# Sends an item list.
	#  user_id - user ID of the other player
	#  data - compact hash with item IDs and quantities
	#----------------------------------------------------------------------
	def _trade_items(user_id, data)
		# abort if trade confirm message could not be delivered
		self.__trade_abort if !@sender.send_to_id(user_id, RMXOS.make_message('TRI', data))
	end
	#----------------------------------------------------------------------
	# Attempts to cancel a trade.
	#  user_id - user ID of the other player
	#----------------------------------------------------------------------
	def _trade_cancel(user_id)
		# abort if trade confirm message could not be delivered
		self.__trade_abort if !@sender.send_to_id(user_id, 'TRC')
	end
	#----------------------------------------------------------------------
	# Confirms a trade cancel attempt.
	#  user_id - user ID of the other player
	#----------------------------------------------------------------------
	def _trade_confirm_cancel(user_id)
		# abort if trade confirm message could not be delivered
		self.__trade_abort if !@sender.send_to_id(user_id, 'TCC')
	end
	#----------------------------------------------------------------------
	# Executes a trade.
	#  user_id - user ID of the other player
	#----------------------------------------------------------------------
	def _trade_execute(user_id)
		@@trade_mutex.synchronize {
			client = RMXOS.clients.get_by_id(user_id)
			@mutex.synchronize {
				# if client exists
				if client == nil
					# something went wrong, abort trade
					self._clear_saving_queries
					self.send('TCA')
					return true
				end
				other_saving_queries = client.saving_queries
				# if other client isn't done with the saving queries yet
				if !other_saving_queries.include?(nil)
					# mark as done
					@saving_queries.push(nil)
					return
				end
				# get the saving queries from the other client
				@saving_queries += other_saving_queries
				@saving_queries.compact!
				# clear other player's queries
				client.clear_saving_queries
				# execute all saving queries
				@saving_queries.push('COMMIT')
				@saving_queries.each {|query| RMXOS.server.sql.query(query)}
				self._clear_saving_queries
			}
			# finalize trade
			client.send('TRF')
			self.send('TRF')
			# let players know it's all cool
			client.send_chat(RMXOS::Data::ColorInfo, RMXOS::Data::TradeSuccessful)
			self.send_chat(RMXOS::Data::ColorInfo, RMXOS::Data::TradeSuccessful)
		}
	end

end
