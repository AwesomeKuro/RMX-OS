#======================================================================
# Player
#----------------------------------------------------------------------
# Contains player related data.
#======================================================================

class Player
	
	IGNORE_VARIABLES = []
	
	# setting all accessible variables
	attr_accessor :user_id
	attr_accessor :username
	attr_accessor :usergroup
	attr_accessor :buddies
	attr_accessor :guildname
	attr_accessor :guildleader
	attr_accessor :guildmembers
	attr_accessor :map_id
	attr_reader   :exchange_variables
	
	#----------------------------------------------------------------------
	# Initialization.
	#----------------------------------------------------------------------
	def initialize(client)
		@client = client
		@mutex = Mutex.new
		# database data for this user
		@user_id = -1
		@username = ''
		@usergroup = RMXOS::GROUP_PLAYER
		@buddies = []
		self.reset_guild
		# very useful when saving the transmitting map status since it's already on the server
		@map_id = 0
		@exchange_variables = {}
	end
	#----------------------------------------------------------------------
	# Resets guild data.
	#----------------------------------------------------------------------
	def reset_guild
		@mutex.synchronize {
			@guildname = ''
			@guildleader = ''
			@guildmembers = []
		}
	end
	#----------------------------------------------------------------------
	# Set general user data.
	#  user_id - user ID
	#  username - username
	#  usergroup - usergroup
	#----------------------------------------------------------------------
	def set_user_data(user_id, username, usergroup)
		@mutex.synchronize {
			@user_id = user_id
			@username = username
			@usergroup = usergroup
		}
	end
	#----------------------------------------------------------------------
	# Set guild data.
	#  guildname - guild name
	#  guildleader - username of the guild leader
	#  guildmembers - usernames of other guild members
	#----------------------------------------------------------------------
	def set_guild_data(guildname, guildleader, guildmembers)
		@mutex.synchronize {
			@guildname = guildname
			@guildleader = guildleader
			@guildmembers = guildmembers
		}
	end
	#----------------------------------------------------------------------
	# Evaluates the received data.
	# variables - array of exchange_variables
	#----------------------------------------------------------------------
	def evaluate(variables)
		@mutex.synchronize {
			(variables.keys - IGNORE_VARIABLES).each {|key| @exchange_variables[key] = variables[key]}
		}
	end
	#----------------------------------------------------------------------
	# Cets all player data.
	# Returns: Data string.
	#----------------------------------------------------------------------
	def get_all_data
		@mutex.synchronize {
			return RMXOS.make_message(@map_id, self._get_current_data)
		}
	end
	#----------------------------------------------------------------------
	# Cets player data for the current map.
	# Returns: Data string.
	#----------------------------------------------------------------------
	def get_current_data
		@mutex.synchronize {
			return self._get_current_data
		}
	end
	def _get_current_data
		return RMXOS.make_message(self._get_player_data, self._get_exchange_variables)
	end
	#----------------------------------------------------------------------
	# Cets player data.
	# Returns: Data string.
	#----------------------------------------------------------------------
	def get_player_data
		@mutex.synchronize {
			return self._get_player_data
		}
	end
	def _get_player_data
		return RMXOS.make_message(@user_id, RMXOS.sql_string(@username), @usergroup, RMXOS.sql_string(@guildname).inspect)
	end
	#----------------------------------------------------------------------
	# Cets user's login data.
	# Returns: Data string.
	#----------------------------------------------------------------------
	def get_login_data
		@mutex.synchronize {
			return RMXOS.make_message(@user_id, @username, @usergroup, self._get_buddies_list)
		}
	end
	#----------------------------------------------------------------------
	# Cets user's guild data.
	# Returns: Data string.
	#----------------------------------------------------------------------
	def get_guild_data
		@mutex.synchronize {
			return self._get_guild_data
		}
	end
	def _get_guild_data
		return RMXOS.make_message(@guildname, @guildleader, self._get_guildmembers_list)
	end
	#----------------------------------------------------------------------
	# Cets player exchange variables.
	# Returns: Data string.
	#----------------------------------------------------------------------
	def get_exchange_variables
		@mutex.synchronize {
			return self._get_exchange_variables
		}
	end
	def _get_exchange_variables
		return @exchange_variables.inspect
	end
	#----------------------------------------------------------------------
	# Cets buddies as list.
	# Returns: Buddies as list.
	#----------------------------------------------------------------------
	def get_buddies_list
		@mutex.synchronize {
			return self._get_buddies_list
		}
	end
	def _get_buddies_list
		return (@buddies.size == 0 ? 'nil' : @buddies.map {|name| name = "'#{RMXOS.sql_string(name)}'"}.join(','))
	end
	#----------------------------------------------------------------------
	# Cets guild members as list.
	# Returns: Guild members as list.
	#----------------------------------------------------------------------
	def get_guildmembers_list
		@mutex.synchronize {
			return self._get_guildmembers_list
		}
	end
	def _get_guildmembers_list
		return (@guildmembers.size == 0 ? 'nil' : @guildmembers.map {|name| name = "'#{RMXOS.sql_string(name)}'"}.join(','))
	end
	#----------------------------------------------------------------------
	# Sets up buddies.
	#----------------------------------------------------------------------
	def setup_buddies
		@mutex.synchronize {
			@buddies = []
			# get all buddy IDs
			check = RMXOS.server.sql.query("SELECT * FROM buddy_list WHERE user1_id = #{@user_id} OR user2_id = #{@user_id}")
			check.num_rows.times {
				hash = check.fetch_hash
				if hash['user1_id'].to_i == @user_id
					@buddies.push(hash['user2_id'].to_i)
				else
					@buddies.push(hash['user1_id'].to_i)
				end
			}
			# convert buddy IDs
			@buddies.each_index {|i|
				check = RMXOS.server.sql.query("SELECT username FROM users WHERE user_id = #{@buddies[i]}")
				hash = check.fetch_hash
				@buddies[i] = hash['username']
			}
		}
	end
	#----------------------------------------------------------------------
	# Sets up all guild related data.
	#  guild_id - ID of the guild
	#----------------------------------------------------------------------
	def setup_guild_data(guild_id)
		@mutex.synchronize {
			# get guild data
			check = RMXOS.server.sql.query("SELECT guildname, leader_id FROM guilds WHERE guild_id = #{guild_id}")
			hash = check.fetch_hash
			@guildname = hash['guildname']
			# get guild leader name
			if hash['leader_id'].to_i != @user_id
				check = RMXOS.server.sql.query("SELECT username FROM users WHERE user_id = #{hash['leader_id']}")
				hash = check.fetch_hash
				@guildleader = hash['username']
			else
				# this player is the guild leader
				@guildleader = @username
			end
			# get guild member count
			check = RMXOS.server.sql.query("SELECT username FROM users JOIN user_data ON users.user_id = " +
				"user_data.user_id WHERE guild_id = #{guild_id}")
			@guildmembers = []
			check.num_rows.times {
				hash = check.fetch_hash
				@guildmembers.push(hash['username'])
			}
		}
	end
	#----------------------------------------------------------------------
	# Checks if a certain command can be use by this player
	#  command - command name
	# Returns: True if command can be used.
	# Note: Usergroup changing is not checked here.
	#----------------------------------------------------------------------
	def can_use_command?(command)
		@mutex.synchronize {
			return false if @user_id == 0
			RMXOS::COMMANDS.each_key {|group| return (@usergroup >= group) if RMXOS::COMMANDS[group].include?(command)}
			return true
		}
	end
	
end