-- SQL Database for RMX-OS
-- by Blizzard
-- update v1.2 to v2.0

START TRANSACTION;

ALTER TABLE `user_data` DROP `notrade`;

COMMIT;
