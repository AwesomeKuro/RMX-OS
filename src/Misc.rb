#======================================================================
# module RMXOS
#======================================================================

module RMXOS
	
	# these values MUST correspond with the values specified in the client
	GROUP_ADMIN = 10
	GROUP_2NDADMIN = 9
	GROUP_MOD = 8
	GROUP_PLAYER = 0
	
	# these values MUST correspond with the values specified in the client
	COMMANDS = {}
	COMMANDS[GROUP_ADMIN] = ['admin']
	COMMANDS[GROUP_2NDADMIN] = ['kickall', 'mod', 'revoke', 'pass', 'gpass',
		'eval', 'geval', 'seval', 'sql']
	COMMANDS[GROUP_MOD] = ['kick', 'ban', 'unban', 'global']
		
end
