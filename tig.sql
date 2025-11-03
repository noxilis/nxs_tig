-- phpMyAdmin SQL Dump
-- version 5.1.1deb5ubuntu1
-- https://www.phpmyadmin.net/
--
-- Hôte : localhost:3306
-- Généré le : sam. 01 nov. 2025 à 02:53
-- Version du serveur : 10.6.22-MariaDB-0ubuntu0.22.04.1
-- Version de PHP : 8.1.2-1ubuntu2.22

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de données : `s1_noctalia`
--

-- --------------------------------------------------------

--
-- Structure de la table `tig_data`
--

CREATE TABLE `tig_data` (
  `identifier` varchar(60) NOT NULL,
  `tasks_left` int(11) NOT NULL,
  `staff` varchar(50) DEFAULT NULL,
  `reason` varchar(255) DEFAULT NULL,
  `zone` varchar(24) DEFAULT NULL,
  `bucket` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


ALTER TABLE `tig_data`
  ADD PRIMARY KEY (`identifier`);
COMMIT;

ALTER TABLE `users`
ADD COLUMN `tig_tasks` INT DEFAULT 0,
ADD COLUMN `tig_zone` VARCHAR(50) DEFAULT NULL,
ADD COLUMN `tig_reason` VARCHAR(255) DEFAULT NULL;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
