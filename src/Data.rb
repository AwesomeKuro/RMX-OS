#==========================================================================
# module RMXOS
#==========================================================================

module RMXOS
	
	#======================================================================
	# module RMXOS::Data
	#----------------------------------------------------------------------
	# Contains constants.
	#======================================================================
	
	module Data
		
		Delimiter	= '--------------------------------------------------------------------------'
		GameVersion	= 'NAME vVERSION'
		Header		= '=========================================================================='
		PressEnter	= 'Press ENTER to continue.'
		Version		= 'RMX-OS Server vVERSION (using Ruby vRUBY_VERSION)'
		# basic constants
		AreYouSure			= 'Are you sure?'
		BuddyNoAdd			= 'You have turned down the buddy list invitation.'
		CommandPrompt		= 'Ruby Prompt active.'
		CommandPromptSign	= '>> '
		CTRLC				= 'Press CTRL+C to shut down RMX-OS.'
		DoYouAccept			= 'Do you accept?'
		ExtensionsLoading	= 'Loading extensions...'
		GuildNoJoin			= 'You have not accepted the guild invitation.'
		GuildNoTransfer		= 'You have not accepted the guild leadership transfer request.'
		Host				= 'Host'
		InvalidSyntax		= 'Invalid Syntax!'
		Kickall				= 'All players have been kicked.'
		MySQLOptimizing		= '> Optimizing database tables...'
		NewPMs				= 'You have new PMs.'
		NoExtensions		= 'No extensions found.'
		NoPendingAction		= 'There is currently no action that requires an answer from you.'
		PasswordChanged		= 'The password has been changed.'
		PasswordChanging	= 'You are about to change your password.'
		PasswordNoChange	= 'The password has not been changed.'
		PendingActions		= 'Following actions are currently active:'
		PMDeletedAll		= 'You have deleted all PMs in your inbox.'
		PMDeletingAll		= 'You are about to delete all PMs in your inbox.'
		PMDeletingUnreadAll	= 'You are about to delete all PMs in your inbox. Some of them are unread.'
		PMNoDeletion		= 'No PMs have been deleted.'
		PMRequested			= 'These PMs are in your inbox:'
		PMRequestedUnread	= 'These PMs are unread:'
		Restart				= 'Restart in:'
		ScriptExecuted		= 'Script successfully executed.'
		Server				= 'Server'
		ShuttingDown		= 'RMX-OS Server is shutting down...'
		ShuttingDownForced	= 'RMX-OS Server is being terminated...'
		Shutdown			= 'RMX-OS Server has shut down.'
		ShutdownForced		= 'RMX-OS Server has been terminated.'
		StartingServer		= 'RMX-OS Server is starting up...'
		TradeCanceled		= 'The trade was canceled.'
		TradeNoRequest		= 'You have not accepted the trade request.'
		TradeSuccessful		= 'The trade was successful.'
		
		# constants with arguments
		ActionCanceled_ACTION			= 'Canceled: ACTION'
		ActionSuccess_ACTION			= 'Action \'ACTION\' has been executed.'
		ActionSuccess_ACTION_ENTITY		= 'Action \'ACTION\' has been executed on \'ENTITY\'.'
		BuddyAdd_PLAYER					= '\'PLAYER\' wants to be buddies with you.'
		BuddyAdded_PLAYER				= 'You and \'PLAYER\' are now buddies.'
		BuddyAdding_PLAYER				= 'You requested to add \'PLAYER\' to your buddy list.'
		BuddyRemoving_PLAYER			= 'You are about to remove \'PLAYER\' from your buddy list.'
		BuddyNoAdd_PLAYER				= '\'PLAYER\' has not accepted the buddy list invitation.'
		BuddyNoRemove_PLAYER			= '\'PLAYER\' was not removed from your buddy list.'
		BuddyRemove_PLAYER				= 'You and \'PLAYER\' are not buddies anymore.'
		ExtensionLoaded_FILE_VERSION	= '\'FILE\' vVERSION loaded and initialized.'
		GroupChanged_PLAYER				= 'The usergroup of player \'PLAYER\' has been changed.'
		GuildCreated_GUILD				= 'Guild \'GUILD\' has been created.'
		GuildDisbanded_GUILD			= 'The guild \'GUILD\' has been disbanded.'
		GuildDisbanding_GUILD			= 'You are about to disband your guild \'GUILD\'.'
		GuildInvitation_GUILD			= 'You have been invited to join the guild \'GUILD\'.'
		GuildInvited_PLAYER				= 'You have invited \'PLAYER\' to join your guild.'
		GuildJoined_GUILD				= 'You have joined the guild \'GUILD\'.'
		GuildJoined_PLAYER				= '\'PLAYER\' has joined the guild.'
		GuildLeader_GUILD				= 'You are the new guild leader of \'GUILD\'.'
		GuildLeader_PLAYER				= '\'PLAYER\' is the new guild leader of \'GUILD\'.'
		GuildLeaving_GUILD				= 'You are about to leave the guild \'GUILD\'.'
		GuildNoDisband_GUILD			= 'The guild \'GUILD\' has not been disbanded.'
		GuildNoJoin_PLAYER				= '\'PLAYER\' has not accepted the guild invitation.'
		GuildNoLeave_GUILD				= 'You are still a member of the guild \'GUILD\'.'
		GuildNoRemove_PLAYER			= '\'PLAYER\' is still a member of your guild.'
		GuildNoTransfer_PLAYER			= '\'PLAYER\' has not accepted the guild leadership transfer request.'
		GuildRemoving_PLAYER			= 'You are about to remove \'PLAYER\' from your guild.'
		GuildRemoved_GUILD				= 'You are not a member of the guild \'GUILD\' anymore.'
		GuildRemoved_PLAYER				= 'Player \'PLAYER\' is not a member of the guild \'GUILD\' anymore.'
		GuildTransferring_GUILD_PLAYER	= 'You are about to transfer your guild leadership of the guild \'GUILD\' to \'PLAYER\'.'
		GuildTransfer_PLAYER			= 'Your guild leader \'PLAYER\' wants to transfer the leadership to you.'
		PMInboxStatus_CURRENT_SIZE		= 'Your PM inbox status: NOW / MAX'
		MySQLConnecting_DATABASE		= '> Connecting to MySQL database \'DATABASE\'...'
		PasswordForcing_ENTITY			= 'You are about to change the password of \'ENTITY\'.'
		PMDeleted_MESSAGEID				= 'You have deleted PM MESSAGEID.'
		PMDeleting_MESSAGEID			= 'You are about to delete PM MESSAGEID.'
		PMDeletingUnread_MESSAGEID		= 'You are about to delete the unread PM MESSAGEID.'
		PMSent_PLAYER					= 'PM has been sent to player \'PLAYER\'.'
		ServerStart_TIME				= 'RMX-OS Server has started successfully at TIME.'
		SocketStarting_IP_PORT			= '> Starting TCP Server at \'IP:PORT\'...'
		TableOptimizing_TABLE			= '    > Optimizing table \'TABLE\'...'
		TradeNoRequest_PLAYER			= '\'PLAYER\' has not accepted the trade request.'
		TradeRequested_PLAYER			= 'You requested to trade with \'PLAYER\'.'
		TradeRequest_PLAYER				= '\'PLAYER\' has requested to trade with you.'
		
		# Other data constants
		ColorError	= "FFBF3F"
		ColorInfo	= "BFBFFF"
		ColorOk		= "1FFF1F"
		ColorNo		= "3F7FFF"
		ColorNormal	= "FFFFFF"
		
		#------------------------------------------------------------------
		# Evaluates named arguments in messages.
		#  string - string with embedded named arguments
		#  args - hash with named arguments
		# Returns: Processed string.
		#------------------------------------------------------------------
		def self.args(string, args)
			string = string.clone
			args.each {|key, value| string.sub!(key, value)} if args != nil
			return string
		end
		
	end
		
end
