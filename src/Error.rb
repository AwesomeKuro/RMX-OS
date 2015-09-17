#==========================================================================
# module RMXOS
#==========================================================================

module RMXOS
	
	#======================================================================
	# module RMXOS::Error
	#----------------------------------------------------------------------
	# Contains error messages.
	#======================================================================
	
	module Error
		
		# basic constants
		ActionNotExist		= 'An error occured in action processing.'
		ConfigFile			= 'Error: The configuration file was not set up properly!'
		GameUndefined		= 'Error: \'NAME\' has not been defined properly in the configuration file.'
		PasswordIncorrect	= 'The password is incorrect.'
		PasswordSame		= 'The new password is the same as the old one.'
		PMInboxEmpty		= 'Your inbox is empty.'
		PMInboxFull			= 'Your PM inbox is full.'
		PMNoUnread			= 'There are no unread PMs in your inbox.'
		SaveFailed			= 'Error: Game data could not be saved!'
		UnexpectedError		= 'Unexpected error occured!'
		UnknownError		= 'Unknown error occured!'
		
		# constants with arguments
		ActionDenied_ACTION					= 'You do not have permission to use \'ACTION\'.'
		ActionDenied_ACTION_ACTION_ENTITY	= 'You do not have permission to use \'ACTION\' on \'ENTITY\'.'
		ActionIdNotExist_ACTIONID			= 'Action with ID ACTIONID does not exist.'
		ClientCrash_ID_NAME_TIME			= 'Client ID (NAME) at TIME has caused an error:'
		ExtensionFileNotFound_FILE			= 'Error: \'FILE\' not found.'
		ExtensionInitError_FILE				= 'Error: \'FILE\' could not be initialized.'
		ExtensionLoadError_FILE				= 'Error: \'FILE\' could not be loaded.'
		ExtensionRunError_FILE				= 'Error: \'FILE\' caused an error.'
		ExtensionVersionError_FILE_VERSION	= 'Error: \'FILE\' requires at least RMX-OS Version VERSION.'
		GuildAlreadyExist_GUILD				= 'Guild \'GUILD\' already exists.'
		GuildNotExist_GUILD					= 'Guild \'GUILD\' does not exist.'
		MessageNotHandled_MESSAGE			= 'Warning: Incoming message not handled: MESSAGE'
		PlayerAlreadyGuild_PLAYER			= 'Player \'PLAYER\' is already member of another guild.'
		PlayerNotExist_PLAYER				= 'Player \'PLAYER\' does not exist.'
		PlayerNotOnline_PLAYER				= 'Player \'PLAYER\' is not online.'
		PlayerNotOnMap_PLAYER				= 'Player \'PLAYER\' is not on the same map.'
		PMNotExist_MESSAGEID				= 'PM MESSAGEID does not exist.'
		PMInboxFull_PLAYER					= 'The inbox of player \'PLAYER\' is full.'
		UnknownClientCrash_TIME				= 'A client at TIME has caused an error:'
		WrongRubyVersion_VERSION			= 'RMX-OS does not support this version of Ruby: VERSION'
		
	end
		
end
