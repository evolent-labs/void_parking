CREATE TABLE IF NOT EXISTS `parkingmeters` (
  `coords` varchar(50) DEFAULT NULL,
  `rotation` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

ALTER TABLE `player_vehicles` ADD COLUMN `coords` TEXT NULL DEFAULT NULL
