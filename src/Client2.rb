#==========================================================================
# Client
#--------------------------------------------------------------------------
# Serves as server side connection for clients.
# Processes all simple and non-interactive messages.
#==========================================================================

class Client
	
	#----------------------------------------------------------------------
	# Sends chat message.
	# Note: Action chat message is basically the same so it's just aliased.
	#----------------------------------------------------------------------
	def _chat
		@sender.send_to_map(@message, true)
	end
	alias _chat_action _chat
	#----------------------------------------------------------------------
	# Enters server.
	#----------------------------------------------------------------------
	def _server_entry
		# from all clients
		clients = RMXOS.clients.get(self)
		# send their data to current client
		clients.each {|client| self.send('PLA', client.player.get_player_data)}
		# send server entry message
		@sender.send_to_clients(clients, RMXOS.make_message('ENT', @player.get_player_data))
	end
	#----------------------------------------------------------------------
	# Enters map.
	#  map_id - ID of the map where you enter
	#----------------------------------------------------------------------
	def _map_entry(map_id)
		# get new map ID
		@player.map_id = map_id
		# to all clients on the same map
		clients = RMXOS.clients.get_on_map(self)
		# send their data to current client
		clients.each {|client| self.send('MEN', client.player.get_all_data)}
		# send server entry message
		@sender.send_to_clients(clients, RMXOS.make_message('MEN', @player.get_all_data))
		# finish map entry
		self.send('MEF')
	end
	#----------------------------------------------------------------------
	# Exits map.
	#----------------------------------------------------------------------
	def _map_exit
		# broadcast map leaving to everybody on the same map
		@sender.send_to_map(RMXOS.make_message('MEX', @player.user_id))
		# map currently unassigned
		@player.map_id = 0
	end
	#----------------------------------------------------------------------
	# Exchanges player variables used for map representation.
	#  variables - hash with all variable values that changed
	#----------------------------------------------------------------------
	def _map_exchange_variables(variables)
		# store the exchange variables
		@player.evaluate(variables)
		# send the new data to everybody on the same map if being on an actual map
		@sender.send_to_map(RMXOS.make_message('MEV', @player.get_player_data, variables.inspect)) if @player.map_id != 0
	end
	#----------------------------------------------------------------------
	# Gets a list of all PMs.
	#----------------------------------------------------------------------
	def _pm_get_all
		check = RMXOS.server.sql.query("SELECT pm_id, sendername, senddate FROM inbox WHERE recipient_id = #{@player.user_id}")
		if check.num_rows > 0
			pms = []
			check.num_rows.times {
				hash = check.fetch_hash
				pms.push("#{hash['pm_id']},'#{RMXOS.sql_string(hash['sendername'])}',#{RMXOS.get_rubytime(hash['senddate'])}")
			}
			self.send_chat(RMXOS::Data::ColorInfo, RMXOS::Data::PMRequested)
			self.send('PMA', pms.join(','))
		else
			self.send_chat(RMXOS::Data::ColorInfo, RMXOS::Error::PMInboxEmpty)
		end
	end
	#----------------------------------------------------------------------
	# Gets a list of all unread PMs.
	#----------------------------------------------------------------------
	def _pm_get_unread
		check = RMXOS.server.sql.query("SELECT pm_id, sendername, senddate FROM inbox WHERE recipient_id = #{@player.user_id} AND unread = 1")
		if check.num_rows > 0
			pms = []
			check.num_rows.times {
				hash = check.fetch_hash
				pms.push("#{hash['pm_id']},'#{RMXOS.sql_string(hash['sendername'])}',#{RMXOS.get_rubytime(hash['senddate'])}")
			}
			self.send_chat(RMXOS::Data::ColorInfo, RMXOS::Data::PMRequestedUnread)
			self.send('PMA', pms.join(','))
		else
			self.send_chat(RMXOS::Data::ColorInfo, RMXOS::Error::PMNoUnread)
		end
	end
	#----------------------------------------------------------------------
	# Gets the PM inbox status.
	#----------------------------------------------------------------------
	def _pm_inbox_status
		check = RMXOS.server.sql.query("SELECT COUNT(*) AS count FROM inbox WHERE recipient_id = #{@player.user_id}")
		hash = check.fetch_hash
		message = RMXOS::Data.args(RMXOS::Data::PMInboxStatus_CURRENT_SIZE, {'NOW' => hash['count'], 'MAX' => INBOX_SIZE.to_s})
		self.send_chat(RMXOS::Data::ColorInfo, message)
	end
	#----------------------------------------------------------------------
	# Aborts the trading proces.
	#  user_id - other player's ID
	#----------------------------------------------------------------------
	def _trade_complete_abort(user_id)
		client = RMXOS.clients.get_by_id(user_id)
		if client != nil
			client.send('TCA')
			client.send_chat(RMXOS::Data::ColorInfo, RMXOS::Data::TradeCanceled)
		end
		self.send_chat(RMXOS::Data::ColorInfo, RMXOS::Data::TradeCanceled)
	end
	#----------------------------------------------------------------------
	# Sends a message to all guild members.
	#  message - chat message
	#----------------------------------------------------------------------
	def _guild_chat(message)
		@sender.send_to_guild(RMXOS.make_message('CHT', message), true)
	end
	#----------------------------------------------------------------------
	# Clears previous save data so no garbage is left afterwards.
	#----------------------------------------------------------------------
	def _save_clear
		@mutex.synchronize {
			@saving_queries.push("DELETE FROM save_data WHERE user_id = #{@player.user_id}")
		}
	end
	#----------------------------------------------------------------------
	# Save data entry.
	#  key   - key string
	#  value - data string
	#----------------------------------------------------------------------
	def _save_data(key, value)
		@mutex.synchronize {
			@saving_queries.push("REPLACE INTO save_data (user_id, data_name, data_value) VALUES (#{@player.user_id}, '#{key}', '#{value}')")
		}
	end
	#----------------------------------------------------------------------
	# Finish saving.
	#----------------------------------------------------------------------
	def _save_end
		@mutex.synchronize {
			@saving_queries.push('COMMIT')
			# execute all saving queries
			begin
				@saving_queries.each {|query| RMXOS.server.sql.query(query)}
			rescue
				RMXOS.server.sql.query('ROLLBACK') rescue nil
				puts RMXOS::Error::SaveFailed
				begin
					# internal Ruby error message
					error_message = RMXOS.get_error
					puts error_message
					# log this client's error message if error log is turned on
					RMXOS.log(client.player, 'Error', error_message) if @options.log_errors
				rescue
				end
			end
			self._clear_saving_queries
		}
	end
	#----------------------------------------------------------------------
	# Load data request.
	#----------------------------------------------------------------------
	def _load_request
		# get all data for this user
		check = RMXOS.server.sql.query("SELECT * FROM save_data WHERE user_id = #{@player.user_id}")
		self.send('LOS', check.num_rows)
		# for each entry
		check.num_rows.times {
			hash = check.fetch_hash
			# send user this data entry of his account
			self.send('LOA', hash['data_name'], hash['data_value'])
		}
		# end loading
		self.send('LEN')
	end

end
