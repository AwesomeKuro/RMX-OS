-- SQL Database for RMX-OS
-- by Blizzard
-- update v1.14 to v1.15

START TRANSACTION;

-- adding IP address table
CREATE TABLE `ips` (
	`user_id` int(10) unsigned,
	`ip` varchar(15),
	PRIMARY KEY (`user_id`, `ip`),
	FOREIGN KEY (`user_id`) REFERENCES users(`user_id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;

COMMIT;
