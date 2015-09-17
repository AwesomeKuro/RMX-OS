#======================================================================
# ActionSent
#----------------------------------------------------------------------
# Represents a sent action request.
#======================================================================

class ActionSent < Action
	
	# setting all accessible variables
	attr_accessor :user_ids
	
	#------------------------------------------------------------------
	# Initialization.
	#------------------------------------------------------------------
	def initialize(action_id, type, messages, user_ids)
		super(action_id, type, messages)
		@user_ids = user_ids
	end
	
end
