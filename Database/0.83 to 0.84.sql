-- SQL Database for RMX-OS
-- by Blizzard
-- update v0.83 to v0.84

START TRANSACTION;

ALTER TABLE `users` CHANGE `name` `username`;
ALTER TABLE `users` CHANGE `group` `usergroup` int(10) NOT NULL DEFAULT '0';

COMMIT;
