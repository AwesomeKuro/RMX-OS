#==========================================================================
# Action
#--------------------------------------------------------------------------
# Represents an basic action.
#==========================================================================

class Action
	
	#======================================================================
	# Action::MessagePack
	#----------------------------------------------------------------------
	# Represents a package of messages for an action.
	#======================================================================

	class MessagePack
	
		attr_accessor :display
		attr_accessor :yes
		attr_accessor :no
		attr_accessor :args
		
		def initialize(display, yes, no, args)
			@display = RMXOS::Data.args(display, args)
			@yes = RMXOS::Data.args(yes, args)
			@no = RMXOS::Data.args(no, args)
			@args = args
		end
		
	end
		
	# enumeration of request types
	TYPE_NONE = 0 # should not be used
	
	TYPE_FORCED_PASSWORD_CHANGE = 1
	TYPE_FORCED_GUILD_PASSWORD_CHANGE = 2
	
	TYPE_PASSWORD_CHANGE = 11
	
	TYPE_GUILD_PASSWORD_CHANGE = 21
	TYPE_GUILD_DISBAND = 22
	TYPE_GUILD_TRANSFER = 23
	TYPE_GUILD_JOIN = 24
	TYPE_GUILD_LEAVE = 25
	TYPE_GUILD_REMOVE = 26
	
	TYPE_TRADE_REQUEST = 31
	
	TYPE_BUDDY_ADD = 41
	TYPE_BUDDY_REMOVE = 42
	
	TYPE_PM_DELETE = 51
	TYPE_PM_DELETE_ALL = 52
	
	# setting all accessible variables
	attr_reader   :action_id
	attr_reader   :type
	attr_reader   :messages
	
	#----------------------------------------------------------------------
	# Initialization.
	#----------------------------------------------------------------------
	def initialize(action_id, type, messages)
		@action_id = action_id
		@type = type
		@messages = messages
	end
	
end
