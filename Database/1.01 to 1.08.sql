-- SQL Database for RMX-OS
-- by Blizzard
-- update v1.01 to v1.08

START TRANSACTION;

-- changing the way passwords are stored
ALTER TABLE `users` CHANGE `password` `password` varchar(11) NOT NULL;
ALTER TABLE `guilds` CHANGE `password` `password` varchar(11) NOT NULL;

COMMIT;
