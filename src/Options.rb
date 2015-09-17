#======================================================================
# module RMXOS
#----------------------------------------------------------------------
# This is the container for RMXOS.
#======================================================================

module RMXOS
	
	#==================================================================
	# RMXOS::Options
	#------------------------------------------------------------------
	# Serves as options container for the server settings.
	#==================================================================

	class Options

		attr_accessor :ip
		attr_accessor :port
		attr_accessor :sql_hostname
		attr_accessor :sql_username
		attr_accessor :sql_password
		attr_accessor :sql_database
		attr_accessor :log_messages
		attr_accessor :log_errors
		attr_accessor :log_actions
		
	end
	
end
