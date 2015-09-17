#======================================================================
# ActionPending
#----------------------------------------------------------------------
# Represents a pending action.
#======================================================================

class ActionPending < Action
	
	# setting all accessible variables
	attr_accessor :data
	attr_accessor :sender_id
	
	#------------------------------------------------------------------
	# Initialization.
	#------------------------------------------------------------------
	def initialize(action_id, type, messages, data, sender_id)
		super(action_id, type, messages)
		@data = data
		@sender_id = sender_id
	end
	
end
