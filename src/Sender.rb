#======================================================================
# Sender
#----------------------------------------------------------------------
# Provides methods for sending messages.
#======================================================================

class Sender
	
	# mutex for sending messages
	@@mutex = nil
	def self.reset
		@@mutex = Mutex.new
	end
	
	#----------------------------------------------------------------------
	# Initialization.
	#----------------------------------------------------------------------
	def initialize(client)
		@client = client
	end
	#----------------------------------------------------------------------
	# Tries to send a message to the actual connected client.
	#  message - message that will be sent
	#----------------------------------------------------------------------
	def send(message)
		@@mutex.synchronize {
			self._send(message)
		}
	end
	#----------------------------------------------------------------------
	# Sends a message to the actual connected client.
	#  message - message that will be sent
	#----------------------------------------------------------------------
	def _send(message)
		if @client.connected?
			begin
				self._send_unsafe(message)
			rescue
				RMXOS.log(@client.player, 'Debug', "Send Error: " + RMXOS.get_error) if RMXOS.server.options.log_errors
			end
		end
	end
	#----------------------------------------------------------------------
	# Sends a actual message to the actual connected client.
	#  message - message that will be sent
	#----------------------------------------------------------------------
	def send_unsafe(message)
		@@mutex.synchronize {
			self._send_unsafe(message)
		}
	end
	#----------------------------------------------------------------------
	# Sends a actual message to the actual connected client.
	#  message - message that will be sent
	#----------------------------------------------------------------------
	def _send_unsafe(message)
		@client.socket.send(message + "\n", 0)
		if RMXOS.server.options.log_messages && !message.start_with?("SAV\t", "LOA\t")
			RMXOS.log(@client.player, 'Outgoing Message', message)
		end
	end
	#----------------------------------------------------------------------
	# Sends a message to all clients.
	#  message - message that will be sent
	#  including - whether to include or exclude this client
	#----------------------------------------------------------------------
	def send_to_all(message, including = false)
		@@mutex.synchronize {
			self._send_to_clients(RMXOS.clients.get(including ? nil : @client), message)
		}
	end
	#----------------------------------------------------------------------
	# Sends a message to all clients on the same map.
	#  message - message that will be sent
	#  including - whether to include or exclude this client
	#----------------------------------------------------------------------
	def send_to_map(message, including = false)
		@@mutex.synchronize {
			self._send_to_clients(RMXOS.clients.get_on_map(@client, including), message)
		}
	end
	#----------------------------------------------------------------------
	# Sends a message to all clients in the same guild.
	#  message - message that will be sent
	#  including - whether to include or exclude this client
	#----------------------------------------------------------------------
	def send_to_guild(message, including = false)
		@@mutex.synchronize {
			self._send_to_clients(RMXOS.clients.get_in_guild(@client, including), message)
		}
	end
	#----------------------------------------------------------------------
	# Sends a message to actual clients.
	#  clients - clients that will receive the message
	#  message - message that will be sent
	#----------------------------------------------------------------------
	def send_to_clients(clients, message)
		@@mutex.synchronize {
			self._send_to_clients(clients, message)
		}
	end
	#----------------------------------------------------------------------
	# Sends a message to actual clients.
	#  clients - clients that will receive the message
	#  message - message that will be sent
	#----------------------------------------------------------------------
	def _send_to_clients(clients, message)
		clients.each {|client| client.sender._send(message) if client.connected?}
	end
	#----------------------------------------------------------------------
	# Sends a message to a specific actual client.
	#  username - username of the client
	#  message - message that will be sent
	# Returns: Whether the sending succeeded or failed.
	#----------------------------------------------------------------------
	def send_to_name(username, message)
		@@mutex.synchronize {
			client = RMXOS.clients.get_by_name(username)
			# client not found
			return false if client == nil
			# failed if connection is closed
			return false if !client.connected?
			# success
			client.sender._send(message)
			return true
		}
	end
	#----------------------------------------------------------------------
	# Sends a message to a specific actual client.
	#  user_id - user ID of the client
	#  message - message that will be sent
	# Returns: Whether the sending succeeded or failed.
	#----------------------------------------------------------------------
	def send_to_id(user_id, message)
		@@mutex.synchronize {
			client = RMXOS.clients.get_by_id(user_id)
			# client not found
			return false if client == nil
			# failed if connection is closed
			return false if !client.connected?
			# success
			client.sender._send(message)
			return true
		}
	end

end
