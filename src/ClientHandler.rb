#======================================================================
# ClientHandler
#----------------------------------------------------------------------
# Provides an interface for client access
#======================================================================

class ClientHandler
	
	#----------------------------------------------------------------------
	# Initialization.
	#----------------------------------------------------------------------
	def initialize
		@mutex = Mutex.new
		self.clear
	end
	#----------------------------------------------------------------------
	# Clears client data.
	#----------------------------------------------------------------------
	def clear
		@mutex.synchronize {
			@clients = []
			@unknown_clients = []
		}
	end
	#----------------------------------------------------------------------
	# Adds a client to the list.
	#  client - the client
	#----------------------------------------------------------------------
	def add(client)
		@mutex.synchronize {
			@unknown_clients.push(client)
		}
	end
	#----------------------------------------------------------------------
	# Deletes a client from the list.
	#  client - the client
	#----------------------------------------------------------------------
	def delete(client)
		@mutex.synchronize {
			index = @unknown_clients.index(client)
			if index != nil
				@unknown_clients.delete_at(index)
				RMXOS.log(client, 'Debug', RMXOS::Debug::ClientDisconnect)
				return
			end
			index = @clients.index(client)
			if index != nil
				@clients.delete_at(index)
				RMXOS.log(client, 'Debug', RMXOS::Data.args(RMXOS::Debug::ClientDisconnect_CLIENTS_MAXIMUM,
					{'CLIENTS' => @clients.size.to_s, 'MAXIMUM' => MAXIMUM_CONNECTIONS.to_s}))
			end
		}
	end
	#----------------------------------------------------------------------
	# Marks a client as logged in.
	#  client - the client
	#----------------------------------------------------------------------
	def login(client)
		@mutex.synchronize {
			@unknown_clients.delete(client)
			@clients.push(client)
			RMXOS.log(client, 'Debug', RMXOS::Data.args(RMXOS::Debug::ClientLogin_CLIENTS_MAXIMUM,
				{'CLIENTS' => @clients.size.to_s, 'MAXIMUM' => MAXIMUM_CONNECTIONS.to_s}))
		}
	end
	#----------------------------------------------------------------------
	# Gets all clients.
	#  current - current client if need to be excluded
	# Returns: An array copy of all clients.
	#----------------------------------------------------------------------
	def get(current = nil)
		@mutex.synchronize {
			clients = @clients.clone
			clients.delete(current) if current != nil
			return clients
		}
	end
	#----------------------------------------------------------------------
	# Gets all clients, even the non-logged in ones.
	#  current - current client if need to be excluded
	# Returns: An array copy of all clients, even the non-logged in ones.
	#----------------------------------------------------------------------
	def get_all(current = nil)
		@mutex.synchronize {
			clients = @unknown_clients + @clients
			clients.delete(current) if current != nil
			return clients
		}
	end
	#----------------------------------------------------------------------
	# Gets all non-logged in clients.
	#  current - current client if need to be excluded
	# Returns: An array copy of all non-logged in clients.
	#----------------------------------------------------------------------
	def get_unknown
		@mutex.synchronize {
			return @unknown_clients.clone
		}
	end
	#----------------------------------------------------------------------
	# Gets all clients on the same map including or excluding self.
	#  current - current client if it needs to be excluded
	#  including - whether to include or exclude this client
	# Returns: Clients on the same map.
	#----------------------------------------------------------------------
	def get_on_map(current, including = false)
		@mutex.synchronize {
			clients = @clients.find_all {|client| client.player.map_id == current.player.map_id}
			clients.delete(current) if !including
			return clients
		}
	end
	#----------------------------------------------------------------------
	# Gets all clients on the same map including or excluding self.
	#  current - current client if it needs to be excluded
	#  including - whether to include or exclude this client
	# Returns: Clients in the same guild.
	#----------------------------------------------------------------------
	def get_in_guild(current, including = false)
		@mutex.synchronize {
			clients = @clients.find_all {|client| client.player.guildname == current.player.guildname}
			clients.delete(current) if !including
			return clients
		}
	end
	#----------------------------------------------------------------------
	# Finds the client with a specific username.
	#  username - username of the connected client
	# Returns: Either the client or nil if not found.
	#----------------------------------------------------------------------
	def get_by_name(username)
		@mutex.synchronize {
			@clients.each {|client| return client if client.player.username.downcase == username.downcase}
			return nil
		}
	end
	#----------------------------------------------------------------------
	# Finds the client with a specific user ID.
	#  user_id - user ID of the connected client
	# Returns: Either the client or nil if not found.
	#----------------------------------------------------------------------
	def get_by_id(user_id)
		@mutex.synchronize {
			@clients.each {|client| return client if client.player.user_id == user_id}
			return nil
		}
	end

end
