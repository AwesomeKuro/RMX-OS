#==========================================================================
# module RMXOS
#--------------------------------------------------------------------------
# This is the container for all RMXOS classes.
#==========================================================================

module RMXOS
	
	#======================================================================
	# RMXOS::SQL
	#----------------------------------------------------------------------
	# Interfaces SQL interactions and queries in a thread-safe and more
	# stable manner than using SQL directly.
	#======================================================================
	
	class SQL
		
		#------------------------------------------------------------------
		# Initialization.
		#------------------------------------------------------------------
		def initialize(options)
			@options = options
			@sql = Mysql.new(@options.sql_hostname, @options.sql_username, @options.sql_password, @options.sql_database)
			@sql.reconnect = true
			self.optimize_database if OPTIMIZE_DATABASE_ON_STARTUP
			@mutex = Mutex.new
		end
		#------------------------------------------------------------------
		# Closes the database
		#------------------------------------------------------------------
		def close
			@mutex.synchronize {
				@sql.close rescue nil
				@sql = nil
			}
		end
		#------------------------------------------------------------------
		# Optimizes database tables.
		#------------------------------------------------------------------
		def optimize_database
			@mutex.synchronize {
				puts RMXOS::Data::MySQLOptimizing
				tables = @sql.list_tables
				tables.each {|table|
					puts RMXOS::Data.args(RMXOS::Data::TableOptimizing_TABLE, {'TABLE' => table})
					@sql.query("OPTIMIZE TABLE #{table}")
				}
			}
		end
		#------------------------------------------------------------------
		# Executes an SQL query.
		#  sql - the SQL command
		# Returns: MySQL::Result instance.
		#------------------------------------------------------------------
		def query(sql)
			@mutex.synchronize {
				return @sql.query(sql)
			}
		end
		#------------------------------------------------------------------
		# Replaces SQL escape characters.
		# Returns: Escape SQL string.
		#------------------------------------------------------------------
		def escape_string(sql)
			return @sql.escape_string(sql)
		end
		
	end
	
end
