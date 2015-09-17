#======================================================================
# module RMXOS
#======================================================================

module RMXOS
	
	#==================================================================
	# module RMXOS::Debug
	#------------------------------------------------------------------
	# Contains debug constants.
	#==================================================================
	
	module Debug
		
		# Debug constants
		ClientConnect		= 'Client connected.'
		ClientDisconnect	= 'Client disconnected.'
		ClientFailed		= 'Client problem detected.'
		ClientLogout		= 'Client logged out forcefully.'
		ConnectionReceived	= 'New connection received.'
		DbConnectionBusy	= 'Reconnecting to database...'
		DbConnectionOk		= 'Database reconnection successful.'
		ExtensionFail		= 'Extension crash detected.'
		MaintenanceThread	= 'Maintenance Thread'
		MainThread			= 'Main Thread'
		PingFailed			= 'Ping on client failed.'
		ServerForceStopped	= 'Server forcibly stopped.'
		ServerForceStopping	= 'Server forcibly stopping...'
		ServerStarted		= 'Server started.'
		ServerStarting		= 'Server starting...'
		ServerStopped		= 'Server stopped.'
		ServerStopping		= 'Server stopping...'
		ThreadStart			= 'Thread started.'
		ThreadStop			= 'Thread stopped.'
		
		# special constants
		ClientLogin_CLIENTS_MAXIMUM			= 'Client logged in: CLIENTS / MAXIMUM'
		ClientDisconnect_CLIENTS_MAXIMUM	= 'Client disconnected: CLIENTS / MAXIMUM'
		
	end

end
