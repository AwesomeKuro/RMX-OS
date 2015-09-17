#==========================================================================
# module RMXOS
#==========================================================================

module RMXOS
	
	#======================================================================
	# RMXOS::Result
	#----------------------------------------------------------------------
	# Contains action result constants.
	#======================================================================
	
	class Result
	
		SUCCESS = 0
		DENIED = 1
		DENIED_S = 2
		SERVER_VERSION_MISMATCH = 3
		GAME_VERSION_MISMATCH = 4
		IGNORE = 5
		
		WAIT_ACTION = 11
		NO_ACTION = 12
		NO_ACTION_ID = 13
		
		PASSWORD_INCORRECT = 21
		ACCOUNT_ALREADY_EXIST = 22
		PASSWORD_SAME = 23
		
		PLAYER_NOT_EXIST = 31
		PLAYER_NOT_ONLINE = 32
		PLAYER_NOT_ON_MAP = 33
		PLAYER_ALREADY_IN_GUILD = 34
		
		GUILD_NOT_EXIST = 41
		GUILD_ALREADY_EXIST = 42
		
		PM_INBOX_EMPTY = 51
		PM_INBOX_FULL = 52
		PM_UNREAD = 53
		PM_UNREAD_ALL = 54
		PM_NOT_EXIST = 55
		
		RUBY_INVALID_SYNTAX = 61
		RUBY_SCRIPT_ERROR = 62
		
		SQL_SCRIPT_ERROR = 71
		
		# setting all accessible variables
		attr_accessor :color
		attr_accessor :message

		#------------------------------------------------------------------
		# Initialization.
		#------------------------------------------------------------------
		def initialize(color, message = '')
			@color = color
			@message = message
		end
		#------------------------------------------------------------------
		# Processes a result code.
		#  code - the result code
		#  message - override message for success and special codes
		#  args - arguments for message
		#  confirmation - whether "Are you sure?" should be added
		# Returns: Result object.
		#------------------------------------------------------------------
		def self.process(code, message, args = {}, confirmation = false)
			result = Result.success(code, message)
			if result == nil
				result = Result.warning(code, message)
				if result == nil
					result = Result.error(code, message)
				elsif confirmation
					result.message = "#{result.message} #{RMXOS::Data::AreYouSure}"
				end
			elsif confirmation
				result.message = "#{result.message} #{RMXOS::Data::AreYouSure}"
			end
			result.message = RMXOS::Data.args(result.message, args)
			return result
		end
		#------------------------------------------------------------------
		# Processes a successful result.
		#  code - the result code
		#  message - override message for success and special codes
		# Returns: Result object if result is successful.
		#------------------------------------------------------------------
		def self.success(code, message)
			return Result.new(RMXOS::Data::ColorInfo, '') if code == RMXOS::Result::IGNORE
			return nil if code != RMXOS::Result::SUCCESS
			return Result.new(RMXOS::Data::ColorInfo, message)
		end
		#------------------------------------------------------------------
		# Processes an error result.
		#  code - the result code
		#  message - override message for success and special codes
		# Returns: Result object.
		#------------------------------------------------------------------
		def self.error(code, message)
			result = Result.new(RMXOS::Data::ColorError)
			result.message = case code
			when RMXOS::Result::PASSWORD_INCORRECT		then RMXOS::Error::PasswordIncorrect
			when RMXOS::Result::PASSWORD_SAME			then RMXOS::Error::PasswordSame
			when RMXOS::Result::DENIED_S				then RMXOS::Error::ActionDenied_ACTION
			when RMXOS::Result::DENIED					then RMXOS::Error::ActionDenied_ACTION_ACTION_ENTITY
			when RMXOS::Result::PLAYER_NOT_EXIST		then RMXOS::Error::PlayerNotExist_PLAYER
			when RMXOS::Result::PLAYER_NOT_ONLINE		then RMXOS::Error::PlayerNotOnline_PLAYER
			when RMXOS::Result::PLAYER_NOT_ON_MAP		then RMXOS::Error::PlayerNotOnMap_PLAYER
			when RMXOS::Result::PLAYER_ALREADY_IN_GUILD	then RMXOS::Error::PlayerAlreadyGuild_PLAYER
			when RMXOS::Result::GUILD_NOT_EXIST			then RMXOS::Error::GuildNotExist_GUILD
			when RMXOS::Result::GUILD_ALREADY_EXIST		then RMXOS::Error::GuildAlreadyExist_GUILD
			when RMXOS::Result::PM_INBOX_EMPTY			then RMXOS::Error::PMInboxEmpty
			when RMXOS::Result::PM_INBOX_FULL			then RMXOS::Error::PMInboxFull_PLAYER
			when RMXOS::Result::PM_NOT_EXIST			then RMXOS::Error::PMNotExist_MESSAGEID
			when RMXOS::Result::NO_ACTION_ID			then RMXOS::Error::ActionIdNotExist_ACTIONID
			when RMXOS::Result::NO_ACTION				then RMXOS::Error::ActionNotExist
			when RMXOS::Result::RUBY_SCRIPT_ERROR		then message
			when RMXOS::Result::SQL_SCRIPT_ERROR		then message
			else
				RMXOS::Error::UnknownError
			end
			return result
		end
		#------------------------------------------------------------------
		# Processes an result that requires a warning.
		#  code - the result code
		#  message - override message for success and special codes
		# Returns: Result object.
		#------------------------------------------------------------------
		def self.warning(code, message)
			result = Result.new(RMXOS::Data::ColorInfo)
			result.message = case code
			when RMXOS::Result::PM_UNREAD		then RMXOS::Data::PMDeletingUnread_MESSAGEID
			when RMXOS::Result::PM_UNREAD_ALL	then RMXOS::Data::PMDeletingUnreadAll
			else
				return nil
			end
			return result
		end
	
	end

end
