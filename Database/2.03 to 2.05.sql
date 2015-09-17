-- SQL Database for RMX-OS
-- by Blizzard
-- update v2.03 to v2.05

START TRANSACTION;

ALTER TABLE `save_data` CHANGE `data_value` `data_value` mediumblob NOT NULL;

COMMIT;
