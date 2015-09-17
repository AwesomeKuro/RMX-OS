module RMXOS
	
	#------------------------------------------------------------------
	# Passes the extension's main module to RMX-OS on the top
	# level so it can handle this extension.
	# Returns: Module of this extension for update.
	#------------------------------------------------------------------
	def self.load_current_extension
		return ExtensionSkeleton
	end
	
end

#======================================================================
# module ExtensionSkeleton
#======================================================================

module ExtensionSkeleton
	
	# extension version
	VERSION = 1.0
	# required RMX-OS version
	RMXOS_VERSION = 2.0
	# whether the server should update this extension in an idividual thread or not
	SERVER_THREAD = true
	# the extension's name/identifier
	IDENTIFIER = 'Extension Skeleton'
	
	# :::: START Configuration
	# - YOUR CONFIGURATION HERE
	# :::: END Configuration
	
	#------------------------------------------------------------------
	# Initializes the extension (i.e. instantiation of classes).
	#------------------------------------------------------------------
	def self.initialize
		# create mutex
		@mutex = Mutex.new
	end
	#------------------------------------------------------------------
	# Gets the local extension mutex.
	#------------------------------------------------------------------
	def self.mutex
		return @mutex
	end
	#------------------------------------------------------------------
	# Calls constant updating on the server.
	#------------------------------------------------------------------
	def self.main
		# while server is running
		while RMXOS.server.running
			@mutex.synchronize {
				self.server_update
			}
			sleep(0.1) # 0.1 seconds pause, decreases server load
		end
	end
	#------------------------------------------------------------------
	# Handles the server update.
	#------------------------------------------------------------------
	def self.server_update
		# - YOUR SERVER CODE HERE
	end
	#------------------------------------------------------------------
	# Handles updating from a client.
	# client - Client instance (from Client.rb)
	# Returns: Whether to stop check the message or not.
	#------------------------------------------------------------------
	def self.client_update(client)
		# - YOUR CLIENT MESSAGE CODE HERE
		return false
	end
	
end

