-- SQL Database for RMX-OS
-- by Blizzard
-- update v0.87 to v0.9

START TRANSACTION;

-- new Guilds table
CREATE TABLE `guilds` (
  `guild_id` int(10) unsigned NOT NULL auto_increment,
  `leader_id` int(10) unsigned NOT NULL UNIQUE,
  `guildname` varchar(32) NOT NULL UNIQUE,
  `password` varchar(8) NOT NULL,
  PRIMARY KEY (`guild_id`),
  FOREIGN KEY (`leader_id`) REFERENCES users(`user_id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;

-- new Special User Data table
CREATE TABLE `user_data` (
  `user_id` int(10) unsigned NOT NULL,
  `notrade` tinyint(1) NOT NULL default 0,
  `lastlogin` DATETIME NOT NULL,
  `guild_id` int(10) unsigned default NULL,
  PRIMARY KEY (`user_id`),
  FOREIGN KEY (`user_id`) REFERENCES users(`user_id`) ON DELETE CASCADE,
  FOREIGN KEY (`guild_id`) REFERENCES guilds(`guild_id`) ON DELETE SET NULL
) ENGINE = InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;

-- populating Special User Data table
INSERT INTO `user_data` (`user_id`) SELECT `user_id` FROM `users`;

-- new Buddy List table
CREATE TABLE `buddy_list` (
	`user1_id` int(10) unsigned NOT NULL,
	`user2_id` int(10) unsigned NOT NULL,
	PRIMARY KEY (`user1_id`, `user2_id`),
	FOREIGN KEY (`user1_id`) REFERENCES users(`user_id`) ON DELETE CASCADE,
	FOREIGN KEY (`user2_id`) REFERENCES users(`user_id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;

-- new Inbox Data table
CREATE TABLE `inbox` (
	`pm_id` int(10) unsigned NOT NULL auto_increment,
	`recipient_id` int(10) unsigned NOT NULL,
	`sendername` varchar(32) NOT NULL,
	`senddate` DATETIME NOT NULL,
	`message` text NOT NULL,
	`unread` tinyint(1) NOT NULL default 1,
	PRIMARY KEY (`pm_id`),
	FOREIGN KEY (`recipient_id`) REFERENCES users(`user_id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;

-- removing old data
ALTER TABLE `users` DROP `nopvp`;
ALTER TABLE `users` DROP `notrade`;

-- improving passwords
UPDATE `users` SET `password` = 
	(CASE
		WHEN SUBSTRING(`password`, 1, 1) = '-'
			THEN CONV(0x100000000 - CAST(CONV(SUBSTRING(`password`, 2, 8), 16, 10) AS signed), 10, 16)
		ELSE UPPER(`password`)
    END);
ALTER TABLE `users` CHANGE `password` `password` varchar(8) NOT NULL;

COMMIT;
