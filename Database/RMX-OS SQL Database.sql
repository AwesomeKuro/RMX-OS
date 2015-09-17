-- SQL Database for RMX-OS
-- by Blizzard

START TRANSACTION;

-- these two are used to create the database and can be omitted in case the database already exists
CREATE DATABASE IF NOT EXISTS `rmxosdb` DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
USE `rmxosdb`;

DROP TABLE IF EXISTS `save_data`;
DROP TABLE IF EXISTS `inbox`;
DROP TABLE IF EXISTS `buddy_list`;
DROP TABLE IF EXISTS `user_data`;
DROP TABLE IF EXISTS `guilds`;
DROP TABLE IF EXISTS `ips`;
DROP TABLE IF EXISTS `users`;

-- Registered Users

CREATE TABLE `users` (
	`user_id` int(10) unsigned NOT NULL auto_increment,
	`username` varchar(32) NOT NULL UNIQUE,
	`password` varchar(11) NOT NULL,
	`usergroup` int(10) NOT NULL default 0,
	`banned` tinyint(1) NOT NULL default 0,
	PRIMARY KEY (`user_id`)
) ENGINE = InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;

-- IPs

CREATE TABLE `ips` (
	`user_id` int(10) unsigned NOT NULL,
	`ip` varchar(15) NOT NULL,
	PRIMARY KEY (`user_id`, `ip`),
	FOREIGN KEY (`user_id`) REFERENCES users(`user_id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;

-- Guilds

CREATE TABLE `guilds` (
	`guild_id` int(10) unsigned NOT NULL auto_increment,
	`leader_id` int(10) unsigned NOT NULL UNIQUE,
	`guildname` varchar(32) NOT NULL UNIQUE,
	`password` varchar(11) NOT NULL,
	PRIMARY KEY (`guild_id`),
	FOREIGN KEY (`leader_id`) REFERENCES users(`user_id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;

-- Special User Data

CREATE TABLE `user_data` (
	`user_id` int(10) unsigned NOT NULL,
	`lastlogin` DATETIME NOT NULL,
	`guild_id` int(10) unsigned default NULL,
	PRIMARY KEY (`user_id`),
	FOREIGN KEY (`user_id`) REFERENCES users(`user_id`) ON DELETE CASCADE,
	FOREIGN KEY (`guild_id`) REFERENCES guilds(`guild_id`) ON DELETE SET NULL
) ENGINE = InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;

-- Buddy List

CREATE TABLE `buddy_list` (
	`user1_id` int(10) unsigned NOT NULL,
	`user2_id` int(10) unsigned NOT NULL,
	PRIMARY KEY (`user1_id`, `user2_id`),
	FOREIGN KEY (`user1_id`) REFERENCES users(`user_id`) ON DELETE CASCADE,
	FOREIGN KEY (`user2_id`) REFERENCES users(`user_id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;

-- PM Inbox Data

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

-- Saved Data

CREATE TABLE `save_data` (
	`user_id` int(10) unsigned NOT NULL,
	`data_name` varchar(255) NOT NULL,
	`data_value` mediumblob NOT NULL,
	PRIMARY KEY (`user_id`, `data_name`),
	FOREIGN KEY (`user_id`) REFERENCES users(`user_id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;

COMMIT;
