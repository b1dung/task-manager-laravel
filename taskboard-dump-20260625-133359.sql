-- MySQL dump 10.13  Distrib 8.4.10, for Linux (x86_64)
--
-- Host: localhost    Database: taskboard
-- ------------------------------------------------------
-- Server version	8.4.10

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `account_tokens`
--

DROP TABLE IF EXISTS `account_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `account_tokens` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `type` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `token_hash` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `expires_at` timestamp NOT NULL,
  `used_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `account_tokens_token_hash_unique` (`token_hash`),
  KEY `account_tokens_user_id_type_index` (`user_id`,`type`),
  CONSTRAINT `account_tokens_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `account_tokens`
--

LOCK TABLES `account_tokens` WRITE;
/*!40000 ALTER TABLE `account_tokens` DISABLE KEYS */;
/*!40000 ALTER TABLE `account_tokens` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `activity_logs`
--

DROP TABLE IF EXISTS `activity_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `activity_logs` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `project_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `action` enum('created','updated','deleted','moved','commented','assigned','status_changed') COLLATE utf8mb4_unicode_ci NOT NULL,
  `entity_type` enum('task','project','column','comment','sprint','member') COLLATE utf8mb4_unicode_ci NOT NULL,
  `entity_id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `old_values_json` json DEFAULT NULL,
  `new_values_json` json DEFAULT NULL,
  `ip_address` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `activity_logs_user_id_foreign` (`user_id`),
  KEY `activity_logs_project_id_created_at_index` (`project_id`,`created_at`),
  KEY `activity_logs_entity_type_entity_id_index` (`entity_type`,`entity_id`),
  CONSTRAINT `activity_logs_project_id_foreign` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `activity_logs_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `activity_logs`
--

LOCK TABLES `activity_logs` WRITE;
/*!40000 ALTER TABLE `activity_logs` DISABLE KEYS */;
INSERT INTO `activity_logs` VALUES ('019ef790-eae2-733a-84e0-af84731b989b','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','created','task','019ef790-ead1-73c9-9329-482fb7ec8a2d',NULL,'{\"title\": \"Design  modul KPI\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": null}','172.20.0.1','2026-06-24 02:58:50'),('019ef791-01ae-72a8-b045-791395156cb2','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','created','task','019ef791-01a4-70e4-a06a-16add1791377',NULL,'{\"title\": \"Add api KPI\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": null}','172.20.0.1','2026-06-24 02:58:56'),('019ef791-1982-7173-9e13-df061d099f1d','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','created','task','019ef791-196f-73de-9558-2db3b4ecf03a',NULL,'{\"title\": \"UI/UX modul KPI\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": null}','172.20.0.1','2026-06-24 02:59:02'),('019ef791-2d25-7382-9b7b-c7af1aa8f580','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','created','task','019ef791-2d1a-72bc-8c89-4ff2a414bbff',NULL,'{\"title\": \"Update UI/UX màn lead\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": null}','172.20.0.1','2026-06-24 02:59:07'),('019ef791-43f6-728b-85d7-5b4caf6677e7','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','created','task','019ef791-43ed-7098-8208-a0df5c2b8c0d',NULL,'{\"title\": \"Implement Candidates Page (Leads)\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": null}','172.20.0.1','2026-06-24 02:59:13'),('019ef791-531a-7207-807b-61eac06f5ab6','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','created','task','019ef791-530f-7094-aaf4-3e3dca2f582f',NULL,'{\"title\": \"Moduls tags\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": null}','172.20.0.1','2026-06-24 02:59:16'),('019ef791-73cc-731e-bb9c-e547b651dd35','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','created','task','019ef791-73c1-7352-9231-93cec452b7c2',NULL,'{\"title\": \"Send a message Lead\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": null}','172.20.0.1','2026-06-24 02:59:25'),('019ef791-8d21-71d3-a88e-f523d7e41f1b','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','created','task','019ef791-8d18-71cf-9cfb-2d413f79d231',NULL,'{\"title\": \"API update status màn Lead\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": null}','172.20.0.1','2026-06-24 02:59:31'),('019ef791-a21d-7080-a29f-037940bf092d','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','created','task','019ef791-a215-7089-8eb1-2080249021f8',NULL,'{\"title\": \"API update status màn Job applications\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": null}','172.20.0.1','2026-06-24 02:59:37'),('019ef791-b87a-73b3-99ec-4678ddbce3d3','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','created','task','019ef791-b86f-7221-8253-d0a61d5ebdc4',NULL,'{\"title\": \"Webhook security check\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": null}','172.20.0.1','2026-06-24 02:59:42'),('019ef791-cd8b-71df-be0d-43d79f17c023','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','created','task','019ef791-cd7d-703a-b732-e149c0a813ea',NULL,'{\"title\": \"Refactor Project Structure and Clean Up Code\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": null}','172.20.0.1','2026-06-24 02:59:48'),('019ef791-de10-71c2-be7a-c2e84bb0f73f','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','created','task','019ef791-de06-72e3-9119-a3fdb9b67ca2',NULL,'{\"title\": \"API logs send messenger\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": null}','172.20.0.1','2026-06-24 02:59:52'),('019ef791-f1f3-7214-8681-88604829228e','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','created','task','019ef791-f1e9-7026-adca-d4a03846fcd4',NULL,'{\"title\": \"Moduls Leads\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": null}','172.20.0.1','2026-06-24 02:59:57'),('019ef79e-a925-705d-a8e2-fb23609f92e6','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','assigned','task','019ef791-2d1a-72bc-8c89-4ff2a414bbff','{\"title\": \"Update UI/UX màn lead\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": null}','{\"title\": \"Update UI/UX màn lead\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 03:13:50'),('019ef79e-c57d-71f8-bde0-395180de8dc2','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','status_changed','task','019ef791-2d1a-72bc-8c89-4ff2a414bbff','{\"title\": \"Update UI/UX màn lead\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','{\"title\": \"Update UI/UX màn lead\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 03:13:58'),('019ef7a1-9187-709c-b280-7e4aa9d36546','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','assigned','task','019ef790-ead1-73c9-9329-482fb7ec8a2d','{\"title\": \"Design  modul KPI\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": null}','{\"title\": \"Design  modul KPI\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a0-583a-7142-9896-dabf327e2d08\"}','172.20.0.1','2026-06-24 03:17:01'),('019ef7a1-a6be-7370-9fbd-92814414ed5d','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','assigned','task','019ef791-01a4-70e4-a06a-16add1791377','{\"title\": \"Add api KPI\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": null}','{\"title\": \"Add api KPI\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a0-583a-7142-9896-dabf327e2d08\"}','172.20.0.1','2026-06-24 03:17:06'),('019ef7a1-bd11-73ee-ba6c-49bbf897c86a','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','assigned','task','019ef791-196f-73de-9558-2db3b4ecf03a','{\"title\": \"UI/UX modul KPI\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": null}','{\"title\": \"UI/UX modul KPI\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 03:17:12'),('019ef7a1-ca67-70f6-9b52-66b9875d995d','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','assigned','task','019ef791-43ed-7098-8208-a0df5c2b8c0d','{\"title\": \"Implement Candidates Page (Leads)\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": null}','{\"title\": \"Implement Candidates Page (Leads)\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 03:17:16'),('019ef7a1-df24-73e6-8d80-e8ccf108e22f','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','assigned','task','019ef791-530f-7094-aaf4-3e3dca2f582f','{\"title\": \"Moduls tags\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": null}','{\"title\": \"Moduls tags\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a1-18e2-7073-8daa-6a65cd8a4034\"}','172.20.0.1','2026-06-24 03:17:21'),('019ef7a1-f2fb-7096-8cbc-caa00e00fde9','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','assigned','task','019ef791-73c1-7352-9231-93cec452b7c2','{\"title\": \"Send a message Lead\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": null}','{\"title\": \"Send a message Lead\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 03:17:26'),('019ef7a2-1bc2-71ad-a902-33f780d6ff3d','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','assigned','task','019ef791-8d18-71cf-9cfb-2d413f79d231','{\"title\": \"API update status màn Lead\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": null}','{\"title\": \"API update status màn Lead\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a0-583a-7142-9896-dabf327e2d08\"}','172.20.0.1','2026-06-24 03:17:36'),('019ef7a2-3d02-72c4-ad20-f133ded1d910','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','assigned','task','019ef791-a215-7089-8eb1-2080249021f8','{\"title\": \"API update status màn Job applications\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": null}','{\"title\": \"API update status màn Job applications\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a0-583a-7142-9896-dabf327e2d08\"}','172.20.0.1','2026-06-24 03:17:45'),('019ef7a2-527a-70bb-b738-525526963521','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','assigned','task','019ef791-b86f-7221-8253-d0a61d5ebdc4','{\"title\": \"Webhook security check\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": null}','{\"title\": \"Webhook security check\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a0-c758-7336-9617-7893092a2442\"}','172.20.0.1','2026-06-24 03:17:50'),('019ef7a2-5dab-731a-8c93-2a3aa1ff92cc','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','assigned','task','019ef791-cd7d-703a-b732-e149c0a813ea','{\"title\": \"Refactor Project Structure and Clean Up Code\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": null}','{\"title\": \"Refactor Project Structure and Clean Up Code\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 03:17:53'),('019ef7a2-8e45-736f-855b-6222f3b25763','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','assigned','task','019ef791-de06-72e3-9119-a3fdb9b67ca2','{\"title\": \"API logs send messenger\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": null}','{\"title\": \"API logs send messenger\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a0-c758-7336-9617-7893092a2442\"}','172.20.0.1','2026-06-24 03:18:06'),('019ef7a2-abc8-7030-9419-c05f25e39b55','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','assigned','task','019ef791-f1e9-7026-adca-d4a03846fcd4','{\"title\": \"Moduls Leads\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": null}','{\"title\": \"Moduls Leads\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a1-18e2-7073-8daa-6a65cd8a4034\"}','172.20.0.1','2026-06-24 03:18:13'),('019ef7a2-be18-72f7-95a5-83c0e51856eb','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','assigned','task','019ef791-530f-7094-aaf4-3e3dca2f582f','{\"title\": \"Moduls tags\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a1-18e2-7073-8daa-6a65cd8a4034\"}','{\"title\": \"Moduls tags\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a0-583a-7142-9896-dabf327e2d08\"}','172.20.0.1','2026-06-24 03:18:18'),('019ef7a2-da65-728a-8078-2624f3006fa4','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','moved','task','019ef791-f1e9-7026-adca-d4a03846fcd4','{\"title\": \"Moduls Leads\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a1-18e2-7073-8daa-6a65cd8a4034\"}','{\"title\": \"Moduls Leads\", \"status\": \"done\", \"dueDate\": null, \"columnId\": \"019ef78f-d168-719d-9933-7d4005560b55\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a1-18e2-7073-8daa-6a65cd8a4034\"}','172.20.0.1','2026-06-24 03:18:25'),('019ef7a2-f39a-7311-b08e-e70d41c944fe','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','moved','task','019ef791-de06-72e3-9119-a3fdb9b67ca2','{\"title\": \"API logs send messenger\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a0-c758-7336-9617-7893092a2442\"}','{\"title\": \"API logs send messenger\", \"status\": \"done\", \"dueDate\": null, \"columnId\": \"019ef78f-d168-719d-9933-7d4005560b55\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a0-c758-7336-9617-7893092a2442\"}','172.20.0.1','2026-06-24 03:18:32'),('019ef7a3-0802-702b-b9ab-ec68e7b89ed0','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','moved','task','019ef791-cd7d-703a-b732-e149c0a813ea','{\"title\": \"Refactor Project Structure and Clean Up Code\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','{\"title\": \"Refactor Project Structure and Clean Up Code\", \"status\": \"done\", \"dueDate\": null, \"columnId\": \"019ef78f-d168-719d-9933-7d4005560b55\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 03:18:37'),('019ef7a3-1c1d-707d-8e84-cc5a3218b010','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','moved','task','019ef791-530f-7094-aaf4-3e3dca2f582f','{\"title\": \"Moduls tags\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a0-583a-7142-9896-dabf327e2d08\"}','{\"title\": \"Moduls tags\", \"status\": \"in_review\", \"dueDate\": null, \"columnId\": \"019ef78f-d167-7099-a70c-da0f791cc7d6\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a0-583a-7142-9896-dabf327e2d08\"}','172.20.0.1','2026-06-24 03:18:42'),('019ef7a3-2a68-70e1-8ae1-313a82181b42','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','moved','task','019ef791-43ed-7098-8208-a0df5c2b8c0d','{\"title\": \"Implement Candidates Page (Leads)\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','{\"title\": \"Implement Candidates Page (Leads)\", \"status\": \"in_review\", \"dueDate\": null, \"columnId\": \"019ef78f-d167-7099-a70c-da0f791cc7d6\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 03:18:46'),('019ef7a3-3638-71db-a3a4-09e1afcfed0f','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','moved','task','019ef791-73c1-7352-9231-93cec452b7c2','{\"title\": \"Send a message Lead\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','{\"title\": \"Send a message Lead\", \"status\": \"in_review\", \"dueDate\": null, \"columnId\": \"019ef78f-d167-7099-a70c-da0f791cc7d6\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 03:18:49'),('019ef7a3-483c-712a-b25c-8ccd3cd10794','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','moved','task','019ef791-a215-7089-8eb1-2080249021f8','{\"title\": \"API update status màn Job applications\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a0-583a-7142-9896-dabf327e2d08\"}','{\"title\": \"API update status màn Job applications\", \"status\": \"in_review\", \"dueDate\": null, \"columnId\": \"019ef78f-d167-7099-a70c-da0f791cc7d6\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a0-583a-7142-9896-dabf327e2d08\"}','172.20.0.1','2026-06-24 03:18:53'),('019ef7a3-5fe3-734a-9370-f1deeec24fab','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','moved','task','019ef791-b86f-7221-8253-d0a61d5ebdc4','{\"title\": \"Webhook security check\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a0-c758-7336-9617-7893092a2442\"}','{\"title\": \"Webhook security check\", \"status\": \"in_review\", \"dueDate\": null, \"columnId\": \"019ef78f-d167-7099-a70c-da0f791cc7d6\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a0-c758-7336-9617-7893092a2442\"}','172.20.0.1','2026-06-24 03:18:59'),('019ef7a3-b128-7238-a277-d118ef722b63','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','moved','task','019ef791-8d18-71cf-9cfb-2d413f79d231','{\"title\": \"API update status màn Lead\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a0-583a-7142-9896-dabf327e2d08\"}','{\"title\": \"API update status màn Lead\", \"status\": \"in_review\", \"dueDate\": null, \"columnId\": \"019ef78f-d167-7099-a70c-da0f791cc7d6\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a0-583a-7142-9896-dabf327e2d08\"}','172.20.0.1','2026-06-24 03:19:20'),('019ef7a4-43e6-7317-8403-f15ba878f2e5','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','updated','task','019ef791-de06-72e3-9119-a3fdb9b67ca2',NULL,'{\"loggedHours\": 6}','172.20.0.1','2026-06-24 03:19:58'),('019ef7a4-6ec2-7372-9e44-e9e7847c0a4b','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','updated','task','019ef791-f1e9-7026-adca-d4a03846fcd4',NULL,'{\"loggedHours\": 11}','172.20.0.1','2026-06-24 03:20:09'),('019ef7a4-8efe-7034-9ce5-bee5c170e9eb','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','updated','task','019ef791-cd7d-703a-b732-e149c0a813ea',NULL,'{\"loggedHours\": 16}','172.20.0.1','2026-06-24 03:20:17'),('019ef7a4-cba3-7004-a2d5-5732868b032c','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','updated','task','019ef791-b86f-7221-8253-d0a61d5ebdc4',NULL,'{\"loggedHours\": 15}','172.20.0.1','2026-06-24 03:20:32'),('019ef7a4-e8d9-73e8-9471-f8dafcbc36ec','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','updated','task','019ef791-8d18-71cf-9cfb-2d413f79d231',NULL,'{\"loggedHours\": 10}','172.20.0.1','2026-06-24 03:20:40'),('019ef7a5-0929-7236-b579-69c7cf649acf','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','updated','task','019ef791-a215-7089-8eb1-2080249021f8',NULL,'{\"loggedHours\": 5}','172.20.0.1','2026-06-24 03:20:48'),('019ef7a5-3cd0-70cb-81b6-e4ac4e428572','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','updated','task','019ef791-73c1-7352-9231-93cec452b7c2',NULL,'{\"loggedHours\": 20}','172.20.0.1','2026-06-24 03:21:01'),('019ef7a5-564c-73e7-a8fd-da7c5f4edf25','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','updated','task','019ef791-530f-7094-aaf4-3e3dca2f582f',NULL,'{\"loggedHours\": 8}','172.20.0.1','2026-06-24 03:21:08'),('019ef7a5-73ec-7285-9b5d-feef9ab8a51a','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','updated','task','019ef791-43ed-7098-8208-a0df5c2b8c0d',NULL,'{\"loggedHours\": 24}','172.20.0.1','2026-06-24 03:21:16'),('019ef7a9-7886-7258-bb03-26eff5c0b814','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','created','task','019ef7a9-7873-72d3-b241-4c948b80bc78',NULL,'{\"title\": \"Deploy\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": null}','172.20.0.1','2026-06-24 03:25:39'),('019ef7aa-36f0-708a-9916-aecc47224f64','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','assigned','task','019ef7a9-7873-72d3-b241-4c948b80bc78','{\"title\": \"Deploy\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": null}','{\"title\": \"Deploy\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a9-da2f-73f2-88a1-1e7849a91af2\"}','172.20.0.1','2026-06-24 03:26:28'),('019ef7aa-5c7e-73d0-a5ae-729c22eb7f33','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','moved','task','019ef7a9-7873-72d3-b241-4c948b80bc78','{\"title\": \"Deploy\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a9-da2f-73f2-88a1-1e7849a91af2\"}','{\"title\": \"Deploy\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a9-da2f-73f2-88a1-1e7849a91af2\"}','172.20.0.1','2026-06-24 03:26:37'),('019ef7aa-6f0a-72e2-b364-5b0fe194a604','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','moved','task','019ef7a9-7873-72d3-b241-4c948b80bc78','{\"title\": \"Deploy\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a9-da2f-73f2-88a1-1e7849a91af2\"}','{\"title\": \"Deploy\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a9-da2f-73f2-88a1-1e7849a91af2\"}','172.20.0.1','2026-06-24 03:26:42'),('019ef7c2-dd44-726c-8b5c-50a826ee0a36','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','updated','task','019ef791-2d1a-72bc-8c89-4ff2a414bbff','{\"title\": \"Update UI/UX màn lead\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','{\"title\": \"Update UI/UX màn lead\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 03:53:23'),('019ef7c3-1089-7356-8e9e-81e6f8eededd','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','updated','task','019ef791-2d1a-72bc-8c89-4ff2a414bbff','{\"title\": \"Update UI/UX màn lead\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','{\"title\": \"Update UI/UX màn lead\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 03:53:36'),('019ef7c5-3181-70d6-b00d-077558430106','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','updated','task','019ef791-cd7d-703a-b732-e149c0a813ea','{\"title\": \"Refactor Project Structure and Clean Up Code\", \"status\": \"done\", \"dueDate\": null, \"columnId\": \"019ef78f-d168-719d-9933-7d4005560b55\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','{\"title\": \"Refactor Project Structure and Clean Up Code\", \"status\": \"done\", \"dueDate\": null, \"columnId\": \"019ef78f-d168-719d-9933-7d4005560b55\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 03:55:56'),('019ef7c5-3b7c-7070-a8ec-43bc2c4ea37d','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','updated','task','019ef791-cd7d-703a-b732-e149c0a813ea','{\"title\": \"Refactor Project Structure and Clean Up Code\", \"status\": \"done\", \"dueDate\": null, \"columnId\": \"019ef78f-d168-719d-9933-7d4005560b55\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','{\"title\": \"Refactor Project Structure and Clean Up Code\", \"status\": \"done\", \"dueDate\": null, \"columnId\": \"019ef78f-d168-719d-9933-7d4005560b55\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 03:55:58'),('019ef7c5-5390-72bb-a13c-488a0d0260f1','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','updated','task','019ef791-cd7d-703a-b732-e149c0a813ea',NULL,'{\"qaLoggedHours\": 0.5}','172.20.0.1','2026-06-24 03:56:04'),('019ef7c5-705d-722a-aa0d-14fc56679acf','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','updated','task','019ef791-f1e9-7026-adca-d4a03846fcd4','{\"title\": \"Moduls Leads\", \"status\": \"done\", \"dueDate\": null, \"columnId\": \"019ef78f-d168-719d-9933-7d4005560b55\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a1-18e2-7073-8daa-6a65cd8a4034\"}','{\"title\": \"Moduls Leads\", \"status\": \"done\", \"dueDate\": null, \"columnId\": \"019ef78f-d168-719d-9933-7d4005560b55\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a1-18e2-7073-8daa-6a65cd8a4034\"}','172.20.0.1','2026-06-24 03:56:12'),('019ef7c5-879c-704f-a8bf-94b84b56aba2','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','updated','task','019ef791-f1e9-7026-adca-d4a03846fcd4',NULL,'{\"qaLoggedHours\": 0.75}','172.20.0.1','2026-06-24 03:56:18'),('019ef7c5-a9f7-7045-bb4c-df77165f1482','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','updated','task','019ef791-de06-72e3-9119-a3fdb9b67ca2','{\"title\": \"API logs send messenger\", \"status\": \"done\", \"dueDate\": null, \"columnId\": \"019ef78f-d168-719d-9933-7d4005560b55\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a0-c758-7336-9617-7893092a2442\"}','{\"title\": \"API logs send messenger\", \"status\": \"done\", \"dueDate\": null, \"columnId\": \"019ef78f-d168-719d-9933-7d4005560b55\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a0-c758-7336-9617-7893092a2442\"}','172.20.0.1','2026-06-24 03:56:27'),('019ef7c5-d0eb-726d-b80c-1bc66c8c39a9','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','updated','task','019ef791-de06-72e3-9119-a3fdb9b67ca2',NULL,'{\"qaLoggedHours\": 1.5}','172.20.0.1','2026-06-24 03:56:36'),('019ef7c6-2a29-7067-be26-47173dc78737','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','updated','task','019ef791-43ed-7098-8208-a0df5c2b8c0d','{\"title\": \"Implement Candidates Page (Leads)\", \"status\": \"in_review\", \"dueDate\": null, \"columnId\": \"019ef78f-d167-7099-a70c-da0f791cc7d6\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','{\"title\": \"Implement Candidates Page (Leads)\", \"status\": \"in_review\", \"dueDate\": null, \"columnId\": \"019ef78f-d167-7099-a70c-da0f791cc7d6\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 03:56:59'),('019ef7c6-459f-7144-9cd7-a8243fd073ac','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','updated','task','019ef791-530f-7094-aaf4-3e3dca2f582f','{\"title\": \"Moduls tags\", \"status\": \"in_review\", \"dueDate\": null, \"columnId\": \"019ef78f-d167-7099-a70c-da0f791cc7d6\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a0-583a-7142-9896-dabf327e2d08\"}','{\"title\": \"Moduls tags\", \"status\": \"in_review\", \"dueDate\": null, \"columnId\": \"019ef78f-d167-7099-a70c-da0f791cc7d6\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a0-583a-7142-9896-dabf327e2d08\"}','172.20.0.1','2026-06-24 03:57:06'),('019ef7c6-57ac-73ec-bd9d-693b191ed693','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','updated','task','019ef791-73c1-7352-9231-93cec452b7c2','{\"title\": \"Send a message Lead\", \"status\": \"in_review\", \"dueDate\": null, \"columnId\": \"019ef78f-d167-7099-a70c-da0f791cc7d6\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','{\"title\": \"Send a message Lead\", \"status\": \"in_review\", \"dueDate\": null, \"columnId\": \"019ef78f-d167-7099-a70c-da0f791cc7d6\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 03:57:11'),('019ef7c6-650f-7115-8c98-05349777cb34','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','updated','task','019ef791-a215-7089-8eb1-2080249021f8','{\"title\": \"API update status màn Job applications\", \"status\": \"in_review\", \"dueDate\": null, \"columnId\": \"019ef78f-d167-7099-a70c-da0f791cc7d6\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a0-583a-7142-9896-dabf327e2d08\"}','{\"title\": \"API update status màn Job applications\", \"status\": \"in_review\", \"dueDate\": null, \"columnId\": \"019ef78f-d167-7099-a70c-da0f791cc7d6\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a0-583a-7142-9896-dabf327e2d08\"}','172.20.0.1','2026-06-24 03:57:14'),('019ef7c6-77d1-72de-a46d-fdbddc36a2b6','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','updated','task','019ef791-a215-7089-8eb1-2080249021f8','{\"title\": \"API update status màn Job applications\", \"status\": \"in_review\", \"dueDate\": null, \"columnId\": \"019ef78f-d167-7099-a70c-da0f791cc7d6\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a0-583a-7142-9896-dabf327e2d08\"}','{\"title\": \"API update status màn Job applications\", \"status\": \"in_review\", \"dueDate\": null, \"columnId\": \"019ef78f-d167-7099-a70c-da0f791cc7d6\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a0-583a-7142-9896-dabf327e2d08\"}','172.20.0.1','2026-06-24 03:57:19'),('019ef7c6-8627-718f-9210-791db80c58b0','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','updated','task','019ef791-8d18-71cf-9cfb-2d413f79d231','{\"title\": \"API update status màn Lead\", \"status\": \"in_review\", \"dueDate\": null, \"columnId\": \"019ef78f-d167-7099-a70c-da0f791cc7d6\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a0-583a-7142-9896-dabf327e2d08\"}','{\"title\": \"API update status màn Lead\", \"status\": \"in_review\", \"dueDate\": null, \"columnId\": \"019ef78f-d167-7099-a70c-da0f791cc7d6\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a0-583a-7142-9896-dabf327e2d08\"}','172.20.0.1','2026-06-24 03:57:23'),('019ef7ce-fdda-70b4-84c1-c2ea363dcb39','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','updated','task','019ef791-2d1a-72bc-8c89-4ff2a414bbff','{\"title\": \"Update UI/UX màn lead\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','{\"title\": \"Update UI/UX màn lead\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 04:06:38'),('019ef7de-092e-7300-bc08-5b5f63b15cdf','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','updated','task','019ef791-2d1a-72bc-8c89-4ff2a414bbff','{\"title\": \"Update UI/UX màn lead\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','{\"title\": \"Update UI/UX màn lead\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 04:23:04'),('019ef7de-5b09-7351-be6e-657ee6c18c33','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','updated','task','019ef791-2d1a-72bc-8c89-4ff2a414bbff','{\"title\": \"Update UI/UX màn lead\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','{\"title\": \"Update UI/UX màn lead\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 04:23:25'),('019ef7e0-f3bc-71e5-b62f-7c9227381a87','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','updated','task','019ef791-2d1a-72bc-8c89-4ff2a414bbff','{\"title\": \"Update UI/UX màn lead\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','{\"title\": \"Update UI/UX màn lead\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 04:26:15'),('019ef7e1-420d-71bb-a49b-c6f18bc8e36e','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','updated','task','019ef791-2d1a-72bc-8c89-4ff2a414bbff','{\"title\": \"Update UI/UX màn lead\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','{\"title\": \"Update UI/UX màn lead\", \"status\": \"in_progress\", \"dueDate\": \"2026-06-30\", \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 04:26:35'),('019ef7e1-d100-7146-9f1f-1f6a527957d0','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','created','task','019ef7e1-d0f8-70de-af54-63a02d8f79d6',NULL,'{\"title\": \"Cập nhật UI/UX màn Job Applications để hiển thị trạng thái mới\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": null}','172.20.0.1','2026-06-24 04:27:12'),('019ef7e1-f11a-7050-983d-e36b1cac8303','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','created','task','019ef7e1-f112-7164-a46f-0e862bc93bfc',NULL,'{\"title\": \"Cập nhật logic kéo trạng thái trên màn Lead\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": null}','172.20.0.1','2026-06-24 04:27:20'),('019ef7e2-1097-713e-8244-155539346f31','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','created','task','019ef7e2-108f-71aa-9ad5-0208233f0e2a',NULL,'{\"title\": \"Hiển thị danh sách job đang apply khi chuyển sang Start Work\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": null}','172.20.0.1','2026-06-24 04:27:28'),('019ef7e2-2827-727a-8e11-5688e0612698','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','created','task','019ef7e2-2821-718f-abe1-04ef4786e043',NULL,'{\"title\": \"Thiết kế giao diện UI/UX cho màn Lead với các giới hạn kéo trạng thái\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": null}','172.20.0.1','2026-06-24 04:27:34'),('019ef7e2-4d14-710d-8c27-665872e51c81','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','assigned','task','019ef7e1-d0f8-70de-af54-63a02d8f79d6','{\"title\": \"Cập nhật UI/UX màn Job Applications để hiển thị trạng thái mới\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": null}','{\"title\": \"Cập nhật UI/UX màn Job Applications để hiển thị trạng thái mới\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 04:27:43'),('019ef7e2-5cb3-7062-9221-6be4dcf4e1f9','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','assigned','task','019ef7e1-f112-7164-a46f-0e862bc93bfc','{\"title\": \"Cập nhật logic kéo trạng thái trên màn Lead\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": null}','{\"title\": \"Cập nhật logic kéo trạng thái trên màn Lead\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 04:27:47'),('019ef7e2-6a02-707d-be3b-afbddd0ecd45','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','assigned','task','019ef7e2-108f-71aa-9ad5-0208233f0e2a','{\"title\": \"Hiển thị danh sách job đang apply khi chuyển sang Start Work\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": null}','{\"title\": \"Hiển thị danh sách job đang apply khi chuyển sang Start Work\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 04:27:51'),('019ef7e2-798e-722a-9768-8c0e15836ee7','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','assigned','task','019ef7e2-2821-718f-abe1-04ef4786e043','{\"title\": \"Thiết kế giao diện UI/UX cho màn Lead với các giới hạn kéo trạng thái\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": null}','{\"title\": \"Thiết kế giao diện UI/UX cho màn Lead với các giới hạn kéo trạng thái\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 04:27:55'),('019ef7e2-8e13-7188-a786-8f8b9a941cc8','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','status_changed','task','019ef7e1-f112-7164-a46f-0e862bc93bfc','{\"title\": \"Cập nhật logic kéo trạng thái trên màn Lead\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','{\"title\": \"Cập nhật logic kéo trạng thái trên màn Lead\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 04:28:00'),('019ef7e2-92d0-7307-8453-c7c5edce78e4','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','status_changed','task','019ef7e2-108f-71aa-9ad5-0208233f0e2a','{\"title\": \"Hiển thị danh sách job đang apply khi chuyển sang Start Work\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','{\"title\": \"Hiển thị danh sách job đang apply khi chuyển sang Start Work\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 04:28:01'),('019ef7e2-9800-70e8-a0c8-03f66c67fce0','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','status_changed','task','019ef7e2-2821-718f-abe1-04ef4786e043','{\"title\": \"Thiết kế giao diện UI/UX cho màn Lead với các giới hạn kéo trạng thái\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','{\"title\": \"Thiết kế giao diện UI/UX cho màn Lead với các giới hạn kéo trạng thái\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 04:28:02'),('019ef7e2-a317-726e-9c07-30f23cc5be65','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','status_changed','task','019ef7e1-f112-7164-a46f-0e862bc93bfc','{\"title\": \"Cập nhật logic kéo trạng thái trên màn Lead\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','{\"title\": \"Cập nhật logic kéo trạng thái trên màn Lead\", \"status\": \"in_review\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 04:28:05'),('019ef7e2-ac19-71a9-a8b4-41d8072a7a6e','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','status_changed','task','019ef7e2-2821-718f-abe1-04ef4786e043','{\"title\": \"Thiết kế giao diện UI/UX cho màn Lead với các giới hạn kéo trạng thái\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','{\"title\": \"Thiết kế giao diện UI/UX cho màn Lead với các giới hạn kéo trạng thái\", \"status\": \"done\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 04:28:08'),('019ef7ec-3751-70f9-a1e8-13694abddcff','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','status_changed','task','019ef7e1-f112-7164-a46f-0e862bc93bfc','{\"title\": \"Cập nhật logic kéo trạng thái trên màn Lead\", \"status\": \"in_review\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','{\"title\": \"Cập nhật logic kéo trạng thái trên màn Lead\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 04:38:33'),('019ef7ec-4ec2-7334-b60c-100e47eeeb77','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','updated','task','019ef7e2-108f-71aa-9ad5-0208233f0e2a','{\"title\": \"Hiển thị danh sách job đang apply khi chuyển sang Start Work\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','{\"title\": \"Hiển thị danh sách job đang apply khi chuyển sang Start Work\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef790-28bf-710d-8dd2-366b2e94d89f\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 04:38:39'),('019ef7ec-5d24-71da-a548-446f4ca5a6cc','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','updated','task','019ef7e2-2821-718f-abe1-04ef4786e043','{\"title\": \"Thiết kế giao diện UI/UX cho màn Lead với các giới hạn kéo trạng thái\", \"status\": \"done\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','{\"title\": \"Thiết kế giao diện UI/UX cho màn Lead với các giới hạn kéo trạng thái\", \"status\": \"done\", \"dueDate\": null, \"columnId\": \"019ef78f-d168-719d-9933-7d4005560b55\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 04:38:43'),('019ef7ee-5939-7123-9afd-3fede19650d7','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','created','task','019ef7ee-5931-7309-a992-0d530cb7b063',NULL,'{\"title\": \"Kiểm thử UI/UX mới trên màn Lead và Job Applications\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": null}','172.20.0.1','2026-06-24 04:40:53'),('019ef7ee-7310-713f-86dd-0cee9d8e7e6b','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','assigned','task','019ef7ee-5931-7309-a992-0d530cb7b063','{\"title\": \"Kiểm thử UI/UX mới trên màn Lead và Job Applications\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": null}','{\"title\": \"Kiểm thử UI/UX mới trên màn Lead và Job Applications\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 04:40:59'),('019ef7ee-79ad-731f-9b1a-2e111ab76a51','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','status_changed','task','019ef7ee-5931-7309-a992-0d530cb7b063','{\"title\": \"Kiểm thử UI/UX mới trên màn Lead và Job Applications\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','{\"title\": \"Kiểm thử UI/UX mới trên màn Lead và Job Applications\", \"status\": \"in_review\", \"dueDate\": null, \"columnId\": \"019ef78f-d167-7099-a70c-da0f791cc7d6\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 04:41:01'),('019ef86d-96cd-7369-882f-a183c0a041bb','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','created','task','019ef86d-96b7-7108-9fe8-6911f1451b85',NULL,'{\"title\": \"Implement Leads Page\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": null}','172.20.0.1','2026-06-24 06:59:52'),('019ef86d-eba5-7378-8048-04e190a42f3b','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','assigned','task','019ef86d-96b7-7108-9fe8-6911f1451b85','{\"title\": \"Implement Leads Page\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": null}','{\"title\": \"Implement Leads Page\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 07:00:13'),('019ef8af-a827-7243-bc36-c90b1ff62c27','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','moved','task','019ef791-b86f-7221-8253-d0a61d5ebdc4','{\"title\": \"Webhook security check\", \"status\": \"in_review\", \"dueDate\": null, \"columnId\": \"019ef78f-d167-7099-a70c-da0f791cc7d6\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a0-c758-7336-9617-7893092a2442\"}','{\"title\": \"Webhook security check\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef790-28bf-710d-8dd2-366b2e94d89f\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a0-c758-7336-9617-7893092a2442\"}','172.20.0.1','2026-06-24 08:12:01'),('019ef8af-b993-7002-8434-1e315086b5a0','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','moved','task','019ef791-8d18-71cf-9cfb-2d413f79d231','{\"title\": \"API update status màn Lead\", \"status\": \"in_review\", \"dueDate\": null, \"columnId\": \"019ef78f-d167-7099-a70c-da0f791cc7d6\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a0-583a-7142-9896-dabf327e2d08\"}','{\"title\": \"API update status màn Lead\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef790-28bf-710d-8dd2-366b2e94d89f\", \"priority\": \"medium\", \"assigneeId\": \"019ef7a0-583a-7142-9896-dabf327e2d08\"}','172.20.0.1','2026-06-24 08:12:06'),('019ef8b2-7ac6-73f9-8cd0-78d7c708dc7f','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','moved','task','019ef791-73c1-7352-9231-93cec452b7c2','{\"title\": \"Send a message Lead\", \"status\": \"in_review\", \"dueDate\": null, \"columnId\": \"019ef78f-d167-7099-a70c-da0f791cc7d6\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','{\"title\": \"Send a message Lead\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef790-28bf-710d-8dd2-366b2e94d89f\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 08:15:06'),('019ef8f9-d5a8-7239-ae15-01c361793bce','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','updated','task','019ef791-196f-73de-9558-2db3b4ecf03a','{\"title\": \"UI/UX modul KPI\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','{\"title\": \"UI/UX modul KPI\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"urgent\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 09:33:03'),('019ef8fa-053f-711a-a065-23b730664ba6','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','status_changed','task','019ef791-196f-73de-9558-2db3b4ecf03a','{\"title\": \"UI/UX modul KPI\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"urgent\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','{\"title\": \"UI/UX modul KPI\", \"status\": \"done\", \"dueDate\": null, \"columnId\": \"019ef78f-d159-71d9-ad7a-8c5ea536e419\", \"priority\": \"urgent\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-24 09:33:15'),('019efd67-f687-73a6-9a9a-f5980f4a23ae','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','updated','task','019ef791-2d1a-72bc-8c89-4ff2a414bbff','{\"title\": \"Update UI/UX màn lead\", \"status\": \"in_progress\", \"dueDate\": \"2026-06-30\", \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','{\"title\": \"Update UI/UX màn lead\", \"status\": \"in_progress\", \"dueDate\": \"2026-06-30\", \"columnId\": \"019ef78f-d165-718a-b28d-6b7a0b4827b0\", \"priority\": \"medium\", \"assigneeId\": \"019ef3d3-e929-7298-80ce-21f75a189ec3\"}','172.20.0.1','2026-06-25 06:11:49');
/*!40000 ALTER TABLE `activity_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `app_settings`
--

DROP TABLE IF EXISTS `app_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `app_settings` (
  `key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `value` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `app_settings`
--

LOCK TABLES `app_settings` WRITE;
/*!40000 ALTER TABLE `app_settings` DISABLE KEYS */;
INSERT INTO `app_settings` VALUES ('timezone','Asia/Ho_Chi_Minh');
/*!40000 ALTER TABLE `app_settings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `attachments`
--

DROP TABLE IF EXISTS `attachments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `attachments` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `task_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `uploader_id` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `file_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `file_url` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `file_size` bigint unsigned NOT NULL,
  `mime_type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `attachments_task_id_foreign` (`task_id`),
  KEY `attachments_uploader_id_foreign` (`uploader_id`),
  CONSTRAINT `attachments_task_id_foreign` FOREIGN KEY (`task_id`) REFERENCES `tasks` (`id`) ON DELETE CASCADE,
  CONSTRAINT `attachments_uploader_id_foreign` FOREIGN KEY (`uploader_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `attachments`
--

LOCK TABLES `attachments` WRITE;
/*!40000 ALTER TABLE `attachments` DISABLE KEYS */;
/*!40000 ALTER TABLE `attachments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cache`
--

DROP TABLE IF EXISTS `cache`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cache` (
  `key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `value` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `expiration` bigint NOT NULL,
  PRIMARY KEY (`key`),
  KEY `cache_expiration_index` (`expiration`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cache`
--

LOCK TABLES `cache` WRITE;
/*!40000 ALTER TABLE `cache` DISABLE KEYS */;
/*!40000 ALTER TABLE `cache` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cache_locks`
--

DROP TABLE IF EXISTS `cache_locks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cache_locks` (
  `key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `owner` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `expiration` bigint NOT NULL,
  PRIMARY KEY (`key`),
  KEY `cache_locks_expiration_index` (`expiration`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cache_locks`
--

LOCK TABLES `cache_locks` WRITE;
/*!40000 ALTER TABLE `cache_locks` DISABLE KEYS */;
/*!40000 ALTER TABLE `cache_locks` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `columns`
--

DROP TABLE IF EXISTS `columns`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `columns` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `project_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `position` int NOT NULL DEFAULT '0',
  `color` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `wip_limit` int DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `columns_project_id_foreign` (`project_id`),
  CONSTRAINT `columns_project_id_foreign` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `columns`
--

LOCK TABLES `columns` WRITE;
/*!40000 ALTER TABLE `columns` DISABLE KEYS */;
INSERT INTO `columns` VALUES ('019ef78f-d159-71d9-ad7a-8c5ea536e419','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','To Do',0,'#6b7280',NULL,'2026-06-24 02:57:38'),('019ef78f-d165-718a-b28d-6b7a0b4827b0','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','In Progress',1,'#3b82f6',NULL,'2026-06-24 02:57:38'),('019ef78f-d167-7099-a70c-da0f791cc7d6','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','In Review',2,'#8b5cf6',NULL,'2026-06-24 02:57:38'),('019ef78f-d168-719d-9933-7d4005560b55','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','Done',4,'#14b8a6',NULL,'2026-06-24 02:57:38'),('019ef790-28bf-710d-8dd2-366b2e94d89f','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','Fix',3,'#ef4444',NULL,'2026-06-24 02:58:00');
/*!40000 ALTER TABLE `columns` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `comment_mentions`
--

DROP TABLE IF EXISTS `comment_mentions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `comment_mentions` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `comment_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  KEY `comment_mentions_comment_id_foreign` (`comment_id`),
  KEY `comment_mentions_user_id_foreign` (`user_id`),
  CONSTRAINT `comment_mentions_comment_id_foreign` FOREIGN KEY (`comment_id`) REFERENCES `comments` (`id`) ON DELETE CASCADE,
  CONSTRAINT `comment_mentions_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `comment_mentions`
--

LOCK TABLES `comment_mentions` WRITE;
/*!40000 ALTER TABLE `comment_mentions` DISABLE KEYS */;
/*!40000 ALTER TABLE `comment_mentions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `comments`
--

DROP TABLE IF EXISTS `comments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `comments` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `task_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `author_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `content` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `parent_id` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `edited_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `comments_task_id_foreign` (`task_id`),
  KEY `comments_author_id_foreign` (`author_id`),
  KEY `comments_parent_id_foreign` (`parent_id`),
  CONSTRAINT `comments_author_id_foreign` FOREIGN KEY (`author_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `comments_parent_id_foreign` FOREIGN KEY (`parent_id`) REFERENCES `comments` (`id`) ON DELETE CASCADE,
  CONSTRAINT `comments_task_id_foreign` FOREIGN KEY (`task_id`) REFERENCES `tasks` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `comments`
--

LOCK TABLES `comments` WRITE;
/*!40000 ALTER TABLE `comments` DISABLE KEYS */;
/*!40000 ALTER TABLE `comments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `failed_jobs`
--

DROP TABLE IF EXISTS `failed_jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `failed_jobs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `connection` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `queue` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `payload` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `exception` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`),
  KEY `failed_jobs_connection_queue_failed_at_index` (`connection`,`queue`,`failed_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `failed_jobs`
--

LOCK TABLES `failed_jobs` WRITE;
/*!40000 ALTER TABLE `failed_jobs` DISABLE KEYS */;
/*!40000 ALTER TABLE `failed_jobs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `invites`
--

DROP TABLE IF EXISTS `invites`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `invites` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `role_id` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `token_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `invited_by` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `expires_at` timestamp NOT NULL,
  `accepted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `invites_token_hash_unique` (`token_hash`),
  KEY `invites_role_id_foreign` (`role_id`),
  KEY `invites_invited_by_foreign` (`invited_by`),
  KEY `invites_email_index` (`email`),
  CONSTRAINT `invites_invited_by_foreign` FOREIGN KEY (`invited_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `invites_role_id_foreign` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `invites`
--

LOCK TABLES `invites` WRITE;
/*!40000 ALTER TABLE `invites` DISABLE KEYS */;
/*!40000 ALTER TABLE `invites` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `job_batches`
--

DROP TABLE IF EXISTS `job_batches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `job_batches` (
  `id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `total_jobs` int NOT NULL,
  `pending_jobs` int NOT NULL,
  `failed_jobs` int NOT NULL,
  `failed_job_ids` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `options` mediumtext COLLATE utf8mb4_unicode_ci,
  `cancelled_at` int DEFAULT NULL,
  `created_at` int NOT NULL,
  `finished_at` int DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `job_batches`
--

LOCK TABLES `job_batches` WRITE;
/*!40000 ALTER TABLE `job_batches` DISABLE KEYS */;
/*!40000 ALTER TABLE `job_batches` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jobs`
--

DROP TABLE IF EXISTS `jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jobs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `queue` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `payload` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `attempts` smallint unsigned NOT NULL,
  `reserved_at` int unsigned DEFAULT NULL,
  `available_at` int unsigned NOT NULL,
  `created_at` int unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `jobs_queue_index` (`queue`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jobs`
--

LOCK TABLES `jobs` WRITE;
/*!40000 ALTER TABLE `jobs` DISABLE KEYS */;
/*!40000 ALTER TABLE `jobs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `labels`
--

DROP TABLE IF EXISTS `labels`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `labels` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `project_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `color` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  KEY `labels_project_id_foreign` (`project_id`),
  CONSTRAINT `labels_project_id_foreign` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `labels`
--

LOCK TABLES `labels` WRITE;
/*!40000 ALTER TABLE `labels` DISABLE KEYS */;
INSERT INTO `labels` VALUES ('019ef7ce-fd91-7056-998f-4da7401d9d8e','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','Mintoku','#FF5630');
/*!40000 ALTER TABLE `labels` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `migrations`
--

DROP TABLE IF EXISTS `migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `migrations` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `migration` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `batch` int NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `migrations`
--

LOCK TABLES `migrations` WRITE;
/*!40000 ALTER TABLE `migrations` DISABLE KEYS */;
INSERT INTO `migrations` VALUES (1,'0001_01_01_000000_create_users_table',1),(2,'0001_01_01_000001_create_cache_table',1),(3,'0001_01_01_000002_create_jobs_table',1),(4,'2026_06_21_104505_create_personal_access_tokens_table',1),(5,'2026_06_21_110001_create_roles_table',1),(6,'2026_06_21_110002_create_projects_tables',1),(7,'2026_06_21_110003_create_board_tables',1),(8,'2026_06_21_110004_create_tasks_tables',1),(9,'2026_06_21_110005_create_collaboration_tables',1),(10,'2026_06_21_110006_create_system_tables',1),(11,'2026_06_24_120000_add_qa_fields_to_tasks',2),(12,'2026_06_24_130000_create_requesters_tables',3),(13,'2026_06_24_140000_create_app_settings_table',4),(14,'2026_06_24_140001_add_manage_settings_permission',4),(15,'2026_06_24_140002_drop_timezone_from_users',5),(16,'2026_06_25_000001_drop_story_points_from_tasks',6);
/*!40000 ALTER TABLE `migrations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notifications`
--

DROP TABLE IF EXISTS `notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notifications` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `recipient_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `actor_id` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `type` enum('task_assigned','task_updated','task_moved','comment_added','mention','due_date_reminder','export_ready','task_created','time_logged') COLLATE utf8mb4_unicode_ci NOT NULL,
  `entity_type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `entity_id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `message` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `read_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `notifications_actor_id_foreign` (`actor_id`),
  KEY `notifications_recipient_id_read_at_index` (`recipient_id`,`read_at`),
  CONSTRAINT `notifications_actor_id_foreign` FOREIGN KEY (`actor_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `notifications_recipient_id_foreign` FOREIGN KEY (`recipient_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notifications`
--

LOCK TABLES `notifications` WRITE;
/*!40000 ALTER TABLE `notifications` DISABLE KEYS */;
INSERT INTO `notifications` VALUES ('0595ca0b-833f-436f-815b-6dc08a15e3dd','019ef7c1-f6af-71c7-8686-f2ccc8fef73d','019ef3d3-e929-7298-80ce-21f75a189ec3','task_updated','task','019ef791-530f-7094-aaf4-3e3dca2f582f','updated task \"Moduls tags\"',NULL,'2026-06-24 03:57:06'),('0a2f68ac-b412-4128-9883-2b5720412196','019ef7c1-f6af-71c7-8686-f2ccc8fef73d','019ef3d3-e929-7298-80ce-21f75a189ec3','time_logged','task','019ef791-de06-72e3-9119-a3fdb9b67ca2','logged QA time on \"API logs send messenger\"','2026-06-24 09:26:46','2026-06-24 03:56:36'),('0ecc870c-61bc-4f01-a802-f914d2b19b87','019ef7c2-8b2d-7281-a0ca-49580a604b66','019ef3d3-e929-7298-80ce-21f75a189ec3','task_updated','task','019ef791-cd7d-703a-b732-e149c0a813ea','updated task \"Refactor Project Structure and Clean Up Code\"',NULL,'2026-06-24 03:55:58'),('11b705a3-1f19-40cf-8835-2b59b07abc49','019ef7a0-c758-7336-9617-7893092a2442','019ef3d3-e929-7298-80ce-21f75a189ec3','task_assigned','task','019ef791-de06-72e3-9119-a3fdb9b67ca2','updated task \"API logs send messenger\"',NULL,'2026-06-24 03:18:06'),('164ed4c8-2c34-42de-b82c-ce22bdda1287','019ef7a0-583a-7142-9896-dabf327e2d08','019ef3d3-e929-7298-80ce-21f75a189ec3','time_logged','task','019ef791-530f-7094-aaf4-3e3dca2f582f','logged time on \"Moduls tags\"',NULL,'2026-06-24 03:21:08'),('16e208bc-dc54-4b39-bb1e-2604610d11a0','019ef7c2-8b2d-7281-a0ca-49580a604b66','019ef3d3-e929-7298-80ce-21f75a189ec3','task_updated','task','019ef791-2d1a-72bc-8c89-4ff2a414bbff','updated task \"Update UI/UX màn lead\"',NULL,'2026-06-24 04:23:25'),('1eecf250-8397-4489-b13f-ba6e77b1122b','019ef7a1-18e2-7073-8daa-6a65cd8a4034','019ef3d3-e929-7298-80ce-21f75a189ec3','time_logged','task','019ef791-f1e9-7026-adca-d4a03846fcd4','logged QA time on \"Moduls Leads\"',NULL,'2026-06-24 03:56:18'),('1f36c4e0-3f77-429b-9fbf-6d55bd3fdaba','019ef7a0-583a-7142-9896-dabf327e2d08','019ef3d3-e929-7298-80ce-21f75a189ec3','task_moved','task','019ef791-530f-7094-aaf4-3e3dca2f582f','moved task \"Moduls tags\"',NULL,'2026-06-24 03:18:42'),('21de257d-f137-4bd4-a650-3f9b2453a4d3','019ef7c2-8b2d-7281-a0ca-49580a604b66','019ef3d3-e929-7298-80ce-21f75a189ec3','task_updated','task','019ef791-2d1a-72bc-8c89-4ff2a414bbff','updated task \"Update UI/UX màn lead\"',NULL,'2026-06-24 04:23:04'),('22115d4e-0655-4727-9fcb-607be1395ae8','019ef7c1-f6af-71c7-8686-f2ccc8fef73d','019ef3d3-e929-7298-80ce-21f75a189ec3','task_updated','task','019ef791-de06-72e3-9119-a3fdb9b67ca2','updated task \"API logs send messenger\"',NULL,'2026-06-24 03:56:27'),('234d4504-7c1d-44c2-b9dd-5d7fd28f59a3','019ef7a0-c758-7336-9617-7893092a2442','019ef3d3-e929-7298-80ce-21f75a189ec3','time_logged','task','019ef791-de06-72e3-9119-a3fdb9b67ca2','logged QA time on \"API logs send messenger\"',NULL,'2026-06-24 03:56:36'),('24a4e035-7c76-4fdd-a2fe-44e456a59c70','019ef7a0-583a-7142-9896-dabf327e2d08','019ef3d3-e929-7298-80ce-21f75a189ec3','task_updated','task','019ef791-a215-7089-8eb1-2080249021f8','updated task \"API update status màn Job applications\"',NULL,'2026-06-24 03:57:14'),('2b255dfa-59be-4664-8260-785a95b1b67c','019ef7c2-8b2d-7281-a0ca-49580a604b66','019ef3d3-e929-7298-80ce-21f75a189ec3','task_updated','task','019ef791-2d1a-72bc-8c89-4ff2a414bbff','updated task \"Update UI/UX màn lead\"',NULL,'2026-06-24 04:06:38'),('37f24a6d-115e-4537-82ec-3f782b90d534','019ef7a1-18e2-7073-8daa-6a65cd8a4034','019ef3d3-e929-7298-80ce-21f75a189ec3','task_updated','task','019ef791-f1e9-7026-adca-d4a03846fcd4','updated task \"Moduls Leads\"',NULL,'2026-06-24 03:56:12'),('3c0cd631-c9c7-4baf-9b73-ee11c4c7c195','019ef7c2-8b2d-7281-a0ca-49580a604b66','019ef3d3-e929-7298-80ce-21f75a189ec3','task_updated','task','019ef791-8d18-71cf-9cfb-2d413f79d231','updated task \"API update status màn Lead\"',NULL,'2026-06-24 03:57:23'),('419fcaa4-eb11-461d-a7e4-40e64c765ede','019ef7c2-8b2d-7281-a0ca-49580a604b66','019ef3d3-e929-7298-80ce-21f75a189ec3','task_updated','task','019ef791-2d1a-72bc-8c89-4ff2a414bbff','updated task \"Update UI/UX màn lead\"',NULL,'2026-06-24 03:53:36'),('497ddc12-a519-4ecd-b967-016fe82400f5','019ef7c2-8b2d-7281-a0ca-49580a604b66','019ef3d3-e929-7298-80ce-21f75a189ec3','task_updated','task','019ef791-2d1a-72bc-8c89-4ff2a414bbff','updated task \"Update UI/UX màn lead\"',NULL,'2026-06-24 04:26:15'),('4a92c429-0865-4865-8ddb-fe2b98f9eaa4','019ef7a0-c758-7336-9617-7893092a2442','019ef3d3-e929-7298-80ce-21f75a189ec3','task_moved','task','019ef791-b86f-7221-8253-d0a61d5ebdc4','moved task \"Webhook security check\"',NULL,'2026-06-24 08:12:01'),('4f7a0e30-53ac-4074-8a6a-158c82de0159','019ef7a0-583a-7142-9896-dabf327e2d08','019ef3d3-e929-7298-80ce-21f75a189ec3','task_moved','task','019ef791-a215-7089-8eb1-2080249021f8','moved task \"API update status màn Job applications\"',NULL,'2026-06-24 03:18:53'),('5461a52b-02b1-4620-947d-28f9f5a5b4d4','019ef7c1-f6af-71c7-8686-f2ccc8fef73d','019ef3d3-e929-7298-80ce-21f75a189ec3','task_updated','task','019ef791-f1e9-7026-adca-d4a03846fcd4','updated task \"Moduls Leads\"',NULL,'2026-06-24 03:56:12'),('5a654f2f-fb23-49f7-808e-0bdbd7b6d463','019ef7c2-8b2d-7281-a0ca-49580a604b66','019ef3d3-e929-7298-80ce-21f75a189ec3','time_logged','task','019ef791-cd7d-703a-b732-e149c0a813ea','logged QA time on \"Refactor Project Structure and Clean Up Code\"',NULL,'2026-06-24 03:56:04'),('5cfe8e1f-17c1-41b0-a88b-0f0b1f6576d2','019ef7a0-583a-7142-9896-dabf327e2d08','019ef3d3-e929-7298-80ce-21f75a189ec3','task_assigned','task','019ef791-a215-7089-8eb1-2080249021f8','updated task \"API update status màn Job applications\"',NULL,'2026-06-24 03:17:45'),('61c2fcb6-4021-42e4-8f6f-c18fceea2783','019ef7c2-8b2d-7281-a0ca-49580a604b66','019ef3d3-e929-7298-80ce-21f75a189ec3','task_updated','task','019ef791-2d1a-72bc-8c89-4ff2a414bbff','updated task \"Update UI/UX màn lead\"',NULL,'2026-06-24 04:26:35'),('6c175faa-5a95-46b3-aaff-d79ba96e001c','019ef7c1-f6af-71c7-8686-f2ccc8fef73d','019ef3d3-e929-7298-80ce-21f75a189ec3','time_logged','task','019ef791-f1e9-7026-adca-d4a03846fcd4','logged QA time on \"Moduls Leads\"','2026-06-24 09:26:39','2026-06-24 03:56:18'),('6e85e073-6d36-4b6f-9788-e7ced267e403','019ef7a0-583a-7142-9896-dabf327e2d08','019ef3d3-e929-7298-80ce-21f75a189ec3','task_updated','task','019ef791-530f-7094-aaf4-3e3dca2f582f','updated task \"Moduls tags\"',NULL,'2026-06-24 03:57:06'),('6e904830-869b-4aee-9002-5c064f70d5ff','019ef7a1-18e2-7073-8daa-6a65cd8a4034','019ef3d3-e929-7298-80ce-21f75a189ec3','task_moved','task','019ef791-f1e9-7026-adca-d4a03846fcd4','moved task \"Moduls Leads\"',NULL,'2026-06-24 03:18:25'),('6fcfff3e-b3a6-43ec-8cb6-6b13ab149675','019ef7a0-c758-7336-9617-7893092a2442','019ef3d3-e929-7298-80ce-21f75a189ec3','time_logged','task','019ef791-de06-72e3-9119-a3fdb9b67ca2','logged time on \"API logs send messenger\"',NULL,'2026-06-24 03:19:58'),('70ce0aab-d801-4637-a086-031996c333d3','019ef7c1-f6af-71c7-8686-f2ccc8fef73d','019ef3d3-e929-7298-80ce-21f75a189ec3','task_updated','task','019ef791-a215-7089-8eb1-2080249021f8','updated task \"API update status màn Job applications\"','2026-06-24 09:21:22','2026-06-24 03:57:14'),('74a8cd7b-65a4-48c3-8b8a-ba50f6070526','019ef7a0-583a-7142-9896-dabf327e2d08','019ef3d3-e929-7298-80ce-21f75a189ec3','task_assigned','task','019ef791-530f-7094-aaf4-3e3dca2f582f','updated task \"Moduls tags\"',NULL,'2026-06-24 03:18:18'),('7a9661a3-613d-45a5-a94d-8c342c04e99b','019ef7a0-c758-7336-9617-7893092a2442','019ef3d3-e929-7298-80ce-21f75a189ec3','task_assigned','task','019ef791-b86f-7221-8253-d0a61d5ebdc4','updated task \"Webhook security check\"',NULL,'2026-06-24 03:17:50'),('7c14acb7-d8df-44c7-be0a-7129671dd405','019ef7a0-583a-7142-9896-dabf327e2d08','019ef3d3-e929-7298-80ce-21f75a189ec3','task_moved','task','019ef791-8d18-71cf-9cfb-2d413f79d231','moved task \"API update status màn Lead\"',NULL,'2026-06-24 08:12:06'),('7f12e89a-495b-445f-8690-46dec8b6c66a','019ef7a0-c758-7336-9617-7893092a2442','019ef3d3-e929-7298-80ce-21f75a189ec3','task_moved','task','019ef791-b86f-7221-8253-d0a61d5ebdc4','moved task \"Webhook security check\"',NULL,'2026-06-24 03:18:59'),('81d752e0-6f8b-4680-b5c7-9859e887b7a9','019ef7c2-8b2d-7281-a0ca-49580a604b66','019ef3d3-e929-7298-80ce-21f75a189ec3','task_updated','task','019ef791-43ed-7098-8208-a0df5c2b8c0d','updated task \"Implement Candidates Page (Leads)\"',NULL,'2026-06-24 03:56:59'),('866826a1-27fe-41ab-aeec-2167696d914a','019ef7a0-583a-7142-9896-dabf327e2d08','019ef3d3-e929-7298-80ce-21f75a189ec3','task_moved','task','019ef791-8d18-71cf-9cfb-2d413f79d231','moved task \"API update status màn Lead\"',NULL,'2026-06-24 03:19:20'),('8b9aae1f-0465-4ba5-bb55-6d79a604952f','019ef7a0-583a-7142-9896-dabf327e2d08','019ef3d3-e929-7298-80ce-21f75a189ec3','task_updated','task','019ef791-a215-7089-8eb1-2080249021f8','updated task \"API update status màn Job applications\"',NULL,'2026-06-24 03:57:19'),('8bceefeb-c140-4399-bb6e-084ab37935a8','019ef7a1-18e2-7073-8daa-6a65cd8a4034','019ef3d3-e929-7298-80ce-21f75a189ec3','time_logged','task','019ef791-f1e9-7026-adca-d4a03846fcd4','logged time on \"Moduls Leads\"',NULL,'2026-06-24 03:20:09'),('93ca7393-52bc-4353-a6fe-bf6372a1e028','019ef7a1-18e2-7073-8daa-6a65cd8a4034','019ef3d3-e929-7298-80ce-21f75a189ec3','task_assigned','task','019ef791-f1e9-7026-adca-d4a03846fcd4','updated task \"Moduls Leads\"',NULL,'2026-06-24 03:18:13'),('948aec63-765b-4ac5-9c5e-40bbda220137','019ef7c1-f6af-71c7-8686-f2ccc8fef73d','019ef3d3-e929-7298-80ce-21f75a189ec3','task_updated','task','019ef791-73c1-7352-9231-93cec452b7c2','updated task \"Send a message Lead\"','2026-06-24 09:26:34','2026-06-24 03:57:11'),('950143da-499e-4073-840d-ed7a0b3e0239','019ef7a0-583a-7142-9896-dabf327e2d08','019ef3d3-e929-7298-80ce-21f75a189ec3','task_assigned','task','019ef791-01a4-70e4-a06a-16add1791377','updated task \"Add api KPI\"',NULL,'2026-06-24 03:17:06'),('9adf3f69-7502-4f60-a00d-8b4cef739406','019ef7a9-da2f-73f2-88a1-1e7849a91af2','019ef3d3-e929-7298-80ce-21f75a189ec3','task_moved','task','019ef7a9-7873-72d3-b241-4c948b80bc78','moved task \"Deploy\"',NULL,'2026-06-24 03:26:37'),('9b8aa87e-1587-4490-a44d-81d3b48060f8','019ef7c2-8b2d-7281-a0ca-49580a604b66','019ef3d3-e929-7298-80ce-21f75a189ec3','task_updated','task','019ef791-2d1a-72bc-8c89-4ff2a414bbff','updated task \"Update UI/UX màn lead\"',NULL,'2026-06-25 06:11:49'),('b0ae1703-27d4-49e6-9be6-a75f43908763','019ef7a0-c758-7336-9617-7893092a2442','019ef3d3-e929-7298-80ce-21f75a189ec3','task_moved','task','019ef791-de06-72e3-9119-a3fdb9b67ca2','moved task \"API logs send messenger\"',NULL,'2026-06-24 03:18:32'),('baf42a02-0343-4b02-984e-150628ec5f17','019ef7a9-da2f-73f2-88a1-1e7849a91af2','019ef3d3-e929-7298-80ce-21f75a189ec3','task_assigned','task','019ef7a9-7873-72d3-b241-4c948b80bc78','updated task \"Deploy\"',NULL,'2026-06-24 03:26:28'),('bd09794b-4174-4c34-9e4d-19e32d4520f1','019ef7a0-583a-7142-9896-dabf327e2d08','019ef3d3-e929-7298-80ce-21f75a189ec3','task_assigned','task','019ef791-8d18-71cf-9cfb-2d413f79d231','updated task \"API update status màn Lead\"',NULL,'2026-06-24 03:17:36'),('d33c98c0-4650-4ad0-8ba9-30b4ad9a2cae','019ef7a9-da2f-73f2-88a1-1e7849a91af2','019ef3d3-e929-7298-80ce-21f75a189ec3','task_moved','task','019ef7a9-7873-72d3-b241-4c948b80bc78','moved task \"Deploy\"',NULL,'2026-06-24 03:26:42'),('dc68ff5b-8ce2-46ff-9f00-74a5e95827b4','019ef7a1-18e2-7073-8daa-6a65cd8a4034','019ef3d3-e929-7298-80ce-21f75a189ec3','task_assigned','task','019ef791-530f-7094-aaf4-3e3dca2f582f','updated task \"Moduls tags\"',NULL,'2026-06-24 03:17:21'),('ddf4337f-bfd5-4cf7-beb3-c6bd806305b9','019ef7a0-583a-7142-9896-dabf327e2d08','019ef3d3-e929-7298-80ce-21f75a189ec3','time_logged','task','019ef791-a215-7089-8eb1-2080249021f8','logged time on \"API update status màn Job applications\"',NULL,'2026-06-24 03:20:48'),('e2cd9560-8d7b-4dc0-99be-2d48248f8c60','019ef7a0-c758-7336-9617-7893092a2442','019ef3d3-e929-7298-80ce-21f75a189ec3','task_updated','task','019ef791-de06-72e3-9119-a3fdb9b67ca2','updated task \"API logs send messenger\"',NULL,'2026-06-24 03:56:27'),('ecda6e66-da9e-45b2-a7e2-3b3e5b4bcd66','019ef7a0-c758-7336-9617-7893092a2442','019ef3d3-e929-7298-80ce-21f75a189ec3','time_logged','task','019ef791-b86f-7221-8253-d0a61d5ebdc4','logged time on \"Webhook security check\"',NULL,'2026-06-24 03:20:32'),('f4fcc2b2-22f4-4e3b-a8ce-0b3059e78cf9','019ef7a0-583a-7142-9896-dabf327e2d08','019ef3d3-e929-7298-80ce-21f75a189ec3','task_updated','task','019ef791-8d18-71cf-9cfb-2d413f79d231','updated task \"API update status màn Lead\"',NULL,'2026-06-24 03:57:23'),('f86e3d04-0441-4700-9a88-1d462a9cc3f7','019ef7c2-8b2d-7281-a0ca-49580a604b66','019ef3d3-e929-7298-80ce-21f75a189ec3','task_updated','task','019ef791-a215-7089-8eb1-2080249021f8','updated task \"API update status màn Job applications\"',NULL,'2026-06-24 03:57:19'),('f979aafa-39a5-4dab-a1af-5d027db1e712','019ef7a0-583a-7142-9896-dabf327e2d08','019ef3d3-e929-7298-80ce-21f75a189ec3','time_logged','task','019ef791-8d18-71cf-9cfb-2d413f79d231','logged time on \"API update status màn Lead\"',NULL,'2026-06-24 03:20:40'),('ff124e34-cc1c-447a-b82b-f3f03b82523a','019ef7a0-583a-7142-9896-dabf327e2d08','019ef3d3-e929-7298-80ce-21f75a189ec3','task_assigned','task','019ef790-ead1-73c9-9329-482fb7ec8a2d','updated task \"Design  modul KPI\"',NULL,'2026-06-24 03:17:01');
/*!40000 ALTER TABLE `notifications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `personal_access_tokens`
--

DROP TABLE IF EXISTS `personal_access_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `personal_access_tokens` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `tokenable_type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tokenable_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `token` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `abilities` text COLLATE utf8mb4_unicode_ci,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`),
  KEY `personal_access_tokens_expires_at_index` (`expires_at`)
) ENGINE=InnoDB AUTO_INCREMENT=39 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `personal_access_tokens`
--

LOCK TABLES `personal_access_tokens` WRITE;
/*!40000 ALTER TABLE `personal_access_tokens` DISABLE KEYS */;
INSERT INTO `personal_access_tokens` VALUES (1,'App\\Models\\User','019ef3d3-e929-7298-80ce-21f75a189ec3','access','fdba2dfb7a14d38270445074d1f8626c47e6ec68401e4d63068601889ec5fb71','[\"*\"]',NULL,'2026-06-23 09:48:32','2026-06-23 09:33:32','2026-06-23 09:33:32'),(3,'App\\Models\\User','019ef772-d913-73ac-97f2-037f88232e82','access','a5abf1bacdb52af33d13fa5decc0d0d5fcf7ac3d13193466605b82044319fe12','[\"*\"]',NULL,'2026-06-24 03:02:24','2026-06-24 02:47:24','2026-06-24 02:47:24'),(4,'App\\Models\\User','019ef3d3-e929-7298-80ce-21f75a189ec3','access','528684bfba91ec4553330609b1475584b1832a5e628095b461ee12a0a58287d1','[\"*\"]','2026-06-24 03:11:36','2026-06-24 03:12:06','2026-06-24 02:57:06','2026-06-24 03:11:36'),(5,'App\\Models\\User','019ef3d3-e929-7298-80ce-21f75a189ec3','access','2db9679895df94f032737b85431862b34be807c0b39feacbd662ee666526ec31','[\"*\"]','2026-06-24 03:28:11','2026-06-24 03:28:12','2026-06-24 03:13:12','2026-06-24 03:28:11'),(6,'App\\Models\\User','019ef3d3-e929-7298-80ce-21f75a189ec3','access','66f3197c8efc485095673fc9b2e17f44d1d850e9c7e42c92f3e6e52d5f51e1ab','[\"*\"]','2026-06-24 03:41:45','2026-06-24 03:43:18','2026-06-24 03:28:18','2026-06-24 03:41:45'),(9,'App\\Models\\User','019ef3d3-e929-7298-80ce-21f75a189ec3','access','45ceb3bb45465b07db22288a7e0b296321105e615faa5327f016600e250177bb','[\"*\"]','2026-06-24 05:22:12','2026-06-24 05:34:09','2026-06-24 04:34:09','2026-06-24 05:22:12'),(11,'App\\Models\\User','019ef3d3-e929-7298-80ce-21f75a189ec3','access','59180769534c6717eb52bcc1168c05292952b91b33d079e44878af3048de4544','[\"*\"]','2026-06-24 06:59:25','2026-06-24 06:59:35','2026-06-24 05:59:35','2026-06-24 06:59:25'),(21,'App\\Models\\User','019ef3d3-e929-7298-80ce-21f75a189ec3','access','15df624427079b40118fe9e6ac82bb4c21b43eb6ac47959634e9d4fea2770839','[\"*\"]','2026-06-24 07:48:38','2026-06-24 07:59:47','2026-06-24 06:59:47','2026-06-24 07:48:38'),(23,'App\\Models\\User','019ef3d3-e929-7298-80ce-21f75a189ec3','access','b736fc7dbbeeb22649c8eafb14a2f5f178c90e04e2360df572559fa4a389cca2','[\"*\"]','2026-06-24 08:18:42','2026-06-24 08:21:03','2026-06-24 07:21:03','2026-06-24 08:18:42'),(28,'App\\Models\\User','019ef3d3-e929-7298-80ce-21f75a189ec3','access','12d62175c6082aa59df88e0a4c985b9e668b8a0032e2eb6cc9c73950fd33d5b5','[\"*\"]','2026-06-24 09:01:28','2026-06-24 09:25:01','2026-06-24 08:25:01','2026-06-24 09:01:28'),(36,'App\\Models\\User','019ef3d3-e929-7298-80ce-21f75a189ec3','access','fd11afee8d6a22834e871139c5c75bf3b3c727495bfba4e2c5155d576005c61a','[\"*\"]','2026-06-24 09:42:21','2026-06-24 10:27:45','2026-06-24 09:27:45','2026-06-24 09:42:21'),(38,'App\\Models\\User','019ef3d3-e929-7298-80ce-21f75a189ec3','access','eddeb8ed31b56efce9f5da633309c80d7d4e538428ac753cc1e57a851e489899','[\"*\"]','2026-06-25 06:33:40','2026-06-25 07:08:30','2026-06-25 06:08:30','2026-06-25 06:33:40');
/*!40000 ALTER TABLE `personal_access_tokens` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `project_members`
--

DROP TABLE IF EXISTS `project_members`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `project_members` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `project_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `role` enum('admin','manager','member','viewer') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'member',
  `joined_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `project_members_project_id_user_id_unique` (`project_id`,`user_id`),
  KEY `project_members_user_id_foreign` (`user_id`),
  CONSTRAINT `project_members_project_id_foreign` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `project_members_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `project_members`
--

LOCK TABLES `project_members` WRITE;
/*!40000 ALTER TABLE `project_members` DISABLE KEYS */;
INSERT INTO `project_members` VALUES ('019ef78f-d16b-71b6-9847-c75b67bb02a2','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef3d3-e929-7298-80ce-21f75a189ec3','admin','2026-06-24 02:57:38'),('019ef7a1-5d88-72fe-a223-a1565ca0e67b','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef7a1-18e2-7073-8daa-6a65cd8a4034','member','2026-06-24 03:16:48'),('019ef7a1-5db1-7234-9991-4aaca14ced31','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef7a0-c758-7336-9617-7893092a2442','member','2026-06-24 03:16:48'),('019ef7a1-5df8-73c1-89c2-28335918945a','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef7a0-583a-7142-9896-dabf327e2d08','member','2026-06-24 03:16:48'),('019ef7aa-2138-73a3-8327-5d594c006364','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef7a9-da2f-73f2-88a1-1e7849a91af2','member','2026-06-24 03:26:22'),('019ef7c2-f937-71c3-9fb8-4a3fbb43261f','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef7c2-8b2d-7281-a0ca-49580a604b66','member','2026-06-24 03:53:30'),('019ef7c2-f984-715f-8811-b57750b3005d','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef7c1-f6af-71c7-8686-f2ccc8fef73d','member','2026-06-24 03:53:30'),('019ef7c2-f9c9-7261-b61f-ddb2dec30773','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef7c1-8431-722b-afbc-bde2fd6f21d2','member','2026-06-24 03:53:30');
/*!40000 ALTER TABLE `project_members` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `project_task_counters`
--

DROP TABLE IF EXISTS `project_task_counters`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `project_task_counters` (
  `project_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `last_number` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`project_id`),
  CONSTRAINT `project_task_counters_project_id_foreign` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `project_task_counters`
--

LOCK TABLES `project_task_counters` WRITE;
/*!40000 ALTER TABLE `project_task_counters` DISABLE KEYS */;
INSERT INTO `project_task_counters` VALUES ('019ef78f-d153-70a4-a65b-0b42b1c1c1fb',20);
/*!40000 ALTER TABLE `project_task_counters` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `projects`
--

DROP TABLE IF EXISTS `projects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `projects` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `slug` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `owner_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `settings_json` json DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `deadline` timestamp NULL DEFAULT NULL,
  `archived_at` timestamp NULL DEFAULT NULL,
  `archived_by` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `projects_slug_unique` (`slug`),
  KEY `projects_owner_id_foreign` (`owner_id`),
  CONSTRAINT `projects_owner_id_foreign` FOREIGN KEY (`owner_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `projects`
--

LOCK TABLES `projects` WRITE;
/*!40000 ALTER TABLE `projects` DISABLE KEYS */;
INSERT INTO `projects` VALUES ('019ef78f-d153-70a4-a65b-0b42b1c1c1fb','CRM CAMCOM','crm-camcom',NULL,'019ef3d3-e929-7298-80ce-21f75a189ec3',NULL,'2026-06-24 02:57:38',NULL,NULL,NULL,NULL);
/*!40000 ALTER TABLE `projects` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `refresh_tokens`
--

DROP TABLE IF EXISTS `refresh_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `refresh_tokens` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `token_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `expires_at` timestamp NOT NULL,
  `revoked_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `refresh_tokens_token_hash_unique` (`token_hash`),
  KEY `refresh_tokens_user_id_foreign` (`user_id`),
  CONSTRAINT `refresh_tokens_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `refresh_tokens`
--

LOCK TABLES `refresh_tokens` WRITE;
/*!40000 ALTER TABLE `refresh_tokens` DISABLE KEYS */;
INSERT INTO `refresh_tokens` VALUES ('019ef3d3-ead6-70c1-9a9d-b8841e7a144c','019ef3d3-e929-7298-80ce-21f75a189ec3','6a05d41c902b305b629b1f2264b36c8b79e1005674d528f5b1007ab8ee6c72c5','2026-06-30 09:33:32','2026-06-24 03:13:27','2026-06-23 09:33:32'),('019ef3d4-2c52-7041-be4a-5d8338f4d2df','019ef3d3-e929-7298-80ce-21f75a189ec3','00798b883a7a651763bdad20b229a9a13a802c629d2ae12ad16c42ef77a754c2','2026-06-30 09:33:49','2026-06-24 03:13:27','2026-06-23 09:33:49'),('019ef78f-5549-7005-952b-651ab509a924','019ef3d3-e929-7298-80ce-21f75a189ec3','21105b79bcb3d4f5266c4dd1b62a9c80e0337b59faa9740852ab62fd5e22e0e3','2026-07-01 02:57:06','2026-06-24 03:13:27','2026-06-24 02:57:06'),('019ef79e-1518-711f-836f-348557c6b55e','019ef3d3-e929-7298-80ce-21f75a189ec3','6924cebf14626b93084afbb5f23e0b07665ae4839d36a27f5d7e9377c6096940','2026-07-01 03:13:12','2026-06-24 03:13:27','2026-06-24 03:13:12'),('019ef7ab-e6e3-721b-9083-0679e8f9928f','019ef3d3-e929-7298-80ce-21f75a189ec3','e35bb9922ba6967b28501b6db17299d22c18d7d842d40dfc6a7ebc68d831a037','2026-07-01 03:28:18','2026-06-24 03:44:56','2026-06-24 03:28:18'),('019ef7b0-9a57-720f-ab85-cbbfc5429495','019ef3d3-e929-7298-80ce-21f75a189ec3','ad502dd1e4b31d942644f218af90b9b10e1307e605225b2b149a456c9902746a','2026-07-24 03:33:26','2026-06-24 03:44:55','2026-06-24 03:33:26'),('019ef7ba-e842-734c-8d56-e452c8b733e7','019ef3d3-e929-7298-80ce-21f75a189ec3','c2fbcfdd9162b50ace27c1a675180645b052b3163e40e22c1388f5a932853683','2026-07-24 03:44:42',NULL,'2026-06-24 03:44:42'),('019ef7e8-2e76-7365-a4c7-f1cd2db26aa4','019ef3d3-e929-7298-80ce-21f75a189ec3','576a6eeec841cc600b8e9ec7badc36d612bef75d9137094c9d185c0a8ee8bd95','2026-07-24 04:34:09',NULL,'2026-06-24 04:34:09'),('019ef836-6605-7361-85e0-83bbea1ef79d','019ef3d3-e929-7298-80ce-21f75a189ec3','23b77050a6f3342b43376d254bf6685cb5a53bd2f1da1a684729c8a79a0f89fe','2026-07-24 05:59:35',NULL,'2026-06-24 05:59:35'),('019ef86d-86a0-7044-9b51-cbcdcf01bd37','019ef3d3-e929-7298-80ce-21f75a189ec3','548bee7aa79839172fe8445406eda8d232cca58dab87f5bd194efcd2f52275be','2026-07-24 06:59:47',NULL,'2026-06-24 06:59:48'),('019ef880-fe7c-7327-9edf-2fa21a1ca0ca','019ef3d3-e929-7298-80ce-21f75a189ec3','f702abeadc5d1f365062df1cc6d311a6b6ec151df0786e495d3238605878d4e6','2026-07-24 07:21:03',NULL,'2026-06-24 07:21:03'),('019ef8bb-8ef1-73b0-937d-544383703966','019ef3d3-e929-7298-80ce-21f75a189ec3','33176b754e34e8ff1cfb408b286764db39be041137a8e2700d96bf2f7fd8da8a','2026-07-24 08:25:01',NULL,'2026-06-24 08:25:01'),('019ef8dd-66e2-73c5-bded-dab3a4a9889d','019ef3d3-e929-7298-80ce-21f75a189ec3','3b2827084dd61db804079f2b272a3613862096daca025e68b58631651bf99ce9','2026-07-24 09:01:59',NULL,'2026-06-24 09:01:59'),('019ef8ed-a4df-721a-94dc-f1000942a770','019ef7c1-8431-722b-afbc-bde2fd6f21d2','d6923fa3eb5c6daa000b58ad63c779ad82ede53721e0746783c753c1ac42bf47','2026-07-24 09:19:44',NULL,'2026-06-24 09:19:44'),('019ef8ee-ffd8-73fe-a8ce-ab66b0aaa6c1','019ef7c1-f6af-71c7-8686-f2ccc8fef73d','29b013c2b3434f5d3995c60af88ee35cc53355a21e8156e69cbb229a885a7ed9','2026-07-24 09:21:13',NULL,'2026-06-24 09:21:13'),('019ef8f4-fdad-71cd-8be8-aefddc4ce7aa','019ef3d3-e929-7298-80ce-21f75a189ec3','0759d72c3bd95d32257ab5c39e63465f2c9088c7feba5918331954d701256d35','2026-07-24 09:27:45',NULL,'2026-06-24 09:27:45'),('019efd64-ef25-7326-be00-6b794837068d','019ef3d3-e929-7298-80ce-21f75a189ec3','1eb0e2b2a3694dd4e47cd87ee65f3c0246076711d16e0d8f38bf1e0102b49204','2026-07-25 06:08:30',NULL,'2026-06-25 06:08:31');
/*!40000 ALTER TABLE `refresh_tokens` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `requesters`
--

DROP TABLE IF EXISTS `requesters`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `requesters` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `project_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `color` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  KEY `requesters_project_id_foreign` (`project_id`),
  CONSTRAINT `requesters_project_id_foreign` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `requesters`
--

LOCK TABLES `requesters` WRITE;
/*!40000 ALTER TABLE `requesters` DISABLE KEYS */;
INSERT INTO `requesters` VALUES ('019ef7de-5aac-70a6-adc9-f3b52efce636','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','山崎','#00B8D9');
/*!40000 ALTER TABLE `requesters` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `roles`
--

DROP TABLE IF EXISTS `roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `roles` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `is_system` tinyint(1) NOT NULL DEFAULT '0',
  `permissions` json NOT NULL,
  `sort_order` int NOT NULL DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `roles_key_unique` (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `roles`
--

LOCK TABLES `roles` WRITE;
/*!40000 ALTER TABLE `roles` DISABLE KEYS */;
INSERT INTO `roles` VALUES ('019ef3d3-e83f-7338-b363-be7a340fc667','owner','Owner',NULL,1,'[\"manage_users\", \"manage_roles\", \"create_project\", \"edit_project\", \"delete_project\", \"create_sprint\", \"assign_tasks\", \"create_task\", \"update_own_task\", \"approve_task\", \"view_reports\", \"billing_access\", \"invite_client\", \"view_pages\", \"view_all_projects\", \"manage_settings\"]',0,'2026-06-23 09:33:31'),('019ef3d3-e847-73eb-914b-ef82e4aab5c1','admin','Admin',NULL,1,'[\"manage_users\", \"manage_roles\", \"create_project\", \"edit_project\", \"delete_project\", \"create_sprint\", \"assign_tasks\", \"create_task\", \"update_own_task\", \"approve_task\", \"view_reports\", \"invite_client\", \"view_pages\", \"manage_settings\"]',1,'2026-06-23 09:33:31'),('019ef3d3-e84c-7132-9561-4f8276a2d554','pm','PM',NULL,1,'[\"create_project\", \"edit_project\", \"create_sprint\", \"assign_tasks\", \"create_task\", \"update_own_task\", \"approve_task\", \"view_reports\", \"invite_client\", \"view_pages\"]',2,'2026-06-23 09:33:31'),('019ef3d3-e853-70d2-94ac-51d9e2b8bb3d','team_lead','Team Lead',NULL,1,'[\"edit_project\", \"create_sprint\", \"assign_tasks\", \"create_task\", \"update_own_task\", \"approve_task\", \"view_reports\", \"view_pages\"]',3,'2026-06-23 09:33:31'),('019ef3d3-e858-70b9-86a2-f63e4c74e400','member','Member',NULL,1,'[\"create_task\", \"update_own_task\", \"view_reports\", \"view_pages\"]',4,'2026-06-23 09:33:31'),('019ef3d3-e872-73f8-93aa-a2dae3cc8372','client','Client',NULL,1,'[\"view_reports\", \"view_pages\"]',5,'2026-06-23 09:33:31');
/*!40000 ALTER TABLE `roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sessions`
--

DROP TABLE IF EXISTS `sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sessions` (
  `id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_agent` text COLLATE utf8mb4_unicode_ci,
  `payload` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `last_activity` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `sessions_user_id_index` (`user_id`),
  KEY `sessions_last_activity_index` (`last_activity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sessions`
--

LOCK TABLES `sessions` WRITE;
/*!40000 ALTER TABLE `sessions` DISABLE KEYS */;
/*!40000 ALTER TABLE `sessions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sprints`
--

DROP TABLE IF EXISTS `sprints`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sprints` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `project_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `goal` text COLLATE utf8mb4_unicode_ci,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `status` enum('planned','active','completed') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'planned',
  PRIMARY KEY (`id`),
  KEY `sprints_project_id_foreign` (`project_id`),
  CONSTRAINT `sprints_project_id_foreign` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sprints`
--

LOCK TABLES `sprints` WRITE;
/*!40000 ALTER TABLE `sprints` DISABLE KEYS */;
/*!40000 ALTER TABLE `sprints` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `task_labels`
--

DROP TABLE IF EXISTS `task_labels`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `task_labels` (
  `task_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `label_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`task_id`,`label_id`),
  KEY `task_labels_label_id_foreign` (`label_id`),
  CONSTRAINT `task_labels_label_id_foreign` FOREIGN KEY (`label_id`) REFERENCES `labels` (`id`) ON DELETE CASCADE,
  CONSTRAINT `task_labels_task_id_foreign` FOREIGN KEY (`task_id`) REFERENCES `tasks` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `task_labels`
--

LOCK TABLES `task_labels` WRITE;
/*!40000 ALTER TABLE `task_labels` DISABLE KEYS */;
INSERT INTO `task_labels` VALUES ('019ef791-2d1a-72bc-8c89-4ff2a414bbff','019ef7ce-fd91-7056-998f-4da7401d9d8e');
/*!40000 ALTER TABLE `task_labels` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `task_links`
--

DROP TABLE IF EXISTS `task_links`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `task_links` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `source_task_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `target_task_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `link_type` enum('blocks','blocked_by','relates_to') COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  KEY `task_links_source_task_id_foreign` (`source_task_id`),
  KEY `task_links_target_task_id_foreign` (`target_task_id`),
  CONSTRAINT `task_links_source_task_id_foreign` FOREIGN KEY (`source_task_id`) REFERENCES `tasks` (`id`) ON DELETE CASCADE,
  CONSTRAINT `task_links_target_task_id_foreign` FOREIGN KEY (`target_task_id`) REFERENCES `tasks` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `task_links`
--

LOCK TABLES `task_links` WRITE;
/*!40000 ALTER TABLE `task_links` DISABLE KEYS */;
/*!40000 ALTER TABLE `task_links` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `task_requesters`
--

DROP TABLE IF EXISTS `task_requesters`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `task_requesters` (
  `task_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `requester_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`task_id`,`requester_id`),
  KEY `task_requesters_requester_id_foreign` (`requester_id`),
  CONSTRAINT `task_requesters_requester_id_foreign` FOREIGN KEY (`requester_id`) REFERENCES `requesters` (`id`) ON DELETE CASCADE,
  CONSTRAINT `task_requesters_task_id_foreign` FOREIGN KEY (`task_id`) REFERENCES `tasks` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `task_requesters`
--

LOCK TABLES `task_requesters` WRITE;
/*!40000 ALTER TABLE `task_requesters` DISABLE KEYS */;
INSERT INTO `task_requesters` VALUES ('019ef791-2d1a-72bc-8c89-4ff2a414bbff','019ef7de-5aac-70a6-adc9-f3b52efce636');
/*!40000 ALTER TABLE `task_requesters` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tasks`
--

DROP TABLE IF EXISTS `tasks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tasks` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `project_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `column_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `sprint_id` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `type` enum('bug','feature','task','story','epic') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'task',
  `priority` enum('urgent','high','medium','low','lowest') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'medium',
  `status` enum('todo','in_progress','in_review','done') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'todo',
  `assignee_id` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `qa_assignee_id` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `reporter_id` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `due_date` date DEFAULT NULL,
  `estimated_hours` decimal(6,2) DEFAULT NULL,
  `qa_estimated_hours` decimal(6,2) DEFAULT NULL,
  `logged_hours` decimal(6,2) NOT NULL DEFAULT '0.00',
  `qa_logged_hours` decimal(6,2) NOT NULL DEFAULT '0.00',
  `position` int NOT NULL DEFAULT '0',
  `parent_task_id` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `task_number` int DEFAULT NULL,
  `archived_at` timestamp NULL DEFAULT NULL,
  `archived_by` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `tasks_project_id_task_number_unique` (`project_id`,`task_number`),
  KEY `tasks_sprint_id_foreign` (`sprint_id`),
  KEY `tasks_assignee_id_foreign` (`assignee_id`),
  KEY `tasks_reporter_id_foreign` (`reporter_id`),
  KEY `tasks_parent_task_id_foreign` (`parent_task_id`),
  KEY `tasks_project_id_status_index` (`project_id`,`status`),
  KEY `tasks_column_id_position_index` (`column_id`,`position`),
  KEY `tasks_project_id_created_at_index` (`project_id`,`created_at`),
  KEY `tasks_due_date_index` (`due_date`),
  KEY `tasks_qa_assignee_id_index` (`qa_assignee_id`),
  FULLTEXT KEY `tasks_title_description_fulltext` (`title`,`description`),
  CONSTRAINT `tasks_assignee_id_foreign` FOREIGN KEY (`assignee_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tasks_column_id_foreign` FOREIGN KEY (`column_id`) REFERENCES `columns` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tasks_parent_task_id_foreign` FOREIGN KEY (`parent_task_id`) REFERENCES `tasks` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tasks_project_id_foreign` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tasks_qa_assignee_id_foreign` FOREIGN KEY (`qa_assignee_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tasks_reporter_id_foreign` FOREIGN KEY (`reporter_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tasks_sprint_id_foreign` FOREIGN KEY (`sprint_id`) REFERENCES `sprints` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tasks`
--

LOCK TABLES `tasks` WRITE;
/*!40000 ALTER TABLE `tasks` DISABLE KEYS */;
INSERT INTO `tasks` VALUES ('019ef790-ead1-73c9-9329-482fb7ec8a2d','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef78f-d159-71d9-ad7a-8c5ea536e419',NULL,'Design  modul KPI',NULL,'task','medium','todo','019ef7a0-583a-7142-9896-dabf327e2d08',NULL,'019ef3d3-e929-7298-80ce-21f75a189ec3',NULL,NULL,NULL,0.00,0.00,0,NULL,1,NULL,NULL,'2026-06-24 02:58:50','2026-06-24 03:49:46',NULL),('019ef791-01a4-70e4-a06a-16add1791377','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef78f-d159-71d9-ad7a-8c5ea536e419',NULL,'Add api KPI',NULL,'task','medium','todo','019ef7a0-583a-7142-9896-dabf327e2d08',NULL,'019ef3d3-e929-7298-80ce-21f75a189ec3',NULL,NULL,NULL,0.00,0.00,1,NULL,2,NULL,NULL,'2026-06-24 02:58:56','2026-06-24 03:17:06',NULL),('019ef791-196f-73de-9558-2db3b4ecf03a','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef78f-d159-71d9-ad7a-8c5ea536e419',NULL,'UI/UX modul KPI',NULL,'task','urgent','done','019ef3d3-e929-7298-80ce-21f75a189ec3',NULL,'019ef3d3-e929-7298-80ce-21f75a189ec3',NULL,NULL,NULL,0.00,0.00,2,NULL,3,NULL,NULL,'2026-06-24 02:59:02','2026-06-24 09:33:15',NULL),('019ef791-2d1a-72bc-8c89-4ff2a414bbff','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef78f-d165-718a-b28d-6b7a0b4827b0',NULL,'Update UI/UX màn lead',NULL,'task','medium','in_progress','019ef3d3-e929-7298-80ce-21f75a189ec3','019ef7c2-8b2d-7281-a0ca-49580a604b66','019ef3d3-e929-7298-80ce-21f75a189ec3','2026-06-30',NULL,NULL,0.00,0.00,0,NULL,4,NULL,NULL,'2026-06-24 02:59:07','2026-06-24 04:26:35',NULL),('019ef791-43ed-7098-8208-a0df5c2b8c0d','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef78f-d167-7099-a70c-da0f791cc7d6',NULL,'Implement Candidates Page (Leads)',NULL,'task','medium','in_review','019ef3d3-e929-7298-80ce-21f75a189ec3','019ef7c2-8b2d-7281-a0ca-49580a604b66','019ef3d3-e929-7298-80ce-21f75a189ec3',NULL,NULL,NULL,24.00,0.00,0,NULL,5,NULL,NULL,'2026-06-24 02:59:13','2026-06-24 03:56:59',NULL),('019ef791-530f-7094-aaf4-3e3dca2f582f','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef78f-d167-7099-a70c-da0f791cc7d6',NULL,'Moduls tags',NULL,'task','medium','in_review','019ef7a0-583a-7142-9896-dabf327e2d08','019ef7c1-f6af-71c7-8686-f2ccc8fef73d','019ef3d3-e929-7298-80ce-21f75a189ec3',NULL,NULL,NULL,8.00,0.00,0,NULL,6,NULL,NULL,'2026-06-24 02:59:16','2026-06-24 03:57:06',NULL),('019ef791-73c1-7352-9231-93cec452b7c2','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef790-28bf-710d-8dd2-366b2e94d89f',NULL,'Send a message Lead',NULL,'task','medium','todo','019ef3d3-e929-7298-80ce-21f75a189ec3','019ef7c1-f6af-71c7-8686-f2ccc8fef73d','019ef3d3-e929-7298-80ce-21f75a189ec3',NULL,NULL,NULL,20.00,0.00,3,NULL,7,NULL,NULL,'2026-06-24 02:59:25','2026-06-24 08:15:06',NULL),('019ef791-8d18-71cf-9cfb-2d413f79d231','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef790-28bf-710d-8dd2-366b2e94d89f',NULL,'API update status màn Lead',NULL,'task','medium','todo','019ef7a0-583a-7142-9896-dabf327e2d08','019ef7c2-8b2d-7281-a0ca-49580a604b66','019ef3d3-e929-7298-80ce-21f75a189ec3',NULL,NULL,NULL,10.00,0.00,1,NULL,8,NULL,NULL,'2026-06-24 02:59:31','2026-06-24 08:12:06',NULL),('019ef791-a215-7089-8eb1-2080249021f8','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef78f-d167-7099-a70c-da0f791cc7d6',NULL,'API update status màn Job applications',NULL,'task','medium','in_review','019ef7a0-583a-7142-9896-dabf327e2d08','019ef7c2-8b2d-7281-a0ca-49580a604b66','019ef3d3-e929-7298-80ce-21f75a189ec3',NULL,NULL,NULL,5.00,0.00,3,NULL,9,NULL,NULL,'2026-06-24 02:59:37','2026-06-24 03:57:19',NULL),('019ef791-b86f-7221-8253-d0a61d5ebdc4','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef790-28bf-710d-8dd2-366b2e94d89f',NULL,'Webhook security check',NULL,'task','medium','todo','019ef7a0-c758-7336-9617-7893092a2442',NULL,'019ef3d3-e929-7298-80ce-21f75a189ec3',NULL,NULL,NULL,15.00,0.00,1,NULL,10,NULL,NULL,'2026-06-24 02:59:42','2026-06-24 08:12:01',NULL),('019ef791-cd7d-703a-b732-e149c0a813ea','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef78f-d168-719d-9933-7d4005560b55',NULL,'Refactor Project Structure and Clean Up Code',NULL,'task','medium','done','019ef3d3-e929-7298-80ce-21f75a189ec3','019ef7c2-8b2d-7281-a0ca-49580a604b66','019ef3d3-e929-7298-80ce-21f75a189ec3',NULL,NULL,NULL,16.00,0.50,0,NULL,11,NULL,NULL,'2026-06-24 02:59:48','2026-06-24 03:56:04',NULL),('019ef791-de06-72e3-9119-a3fdb9b67ca2','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef78f-d168-719d-9933-7d4005560b55',NULL,'API logs send messenger',NULL,'task','medium','done','019ef7a0-c758-7336-9617-7893092a2442','019ef7c1-f6af-71c7-8686-f2ccc8fef73d','019ef3d3-e929-7298-80ce-21f75a189ec3',NULL,NULL,NULL,6.00,1.50,1,NULL,12,NULL,NULL,'2026-06-24 02:59:52','2026-06-24 03:56:36',NULL),('019ef791-f1e9-7026-adca-d4a03846fcd4','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef78f-d168-719d-9933-7d4005560b55',NULL,'Moduls Leads',NULL,'task','medium','done','019ef7a1-18e2-7073-8daa-6a65cd8a4034','019ef7c1-f6af-71c7-8686-f2ccc8fef73d','019ef3d3-e929-7298-80ce-21f75a189ec3',NULL,NULL,NULL,11.00,0.75,0,NULL,13,NULL,NULL,'2026-06-24 02:59:57','2026-06-24 03:56:18',NULL),('019ef7a9-7873-72d3-b241-4c948b80bc78','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef78f-d165-718a-b28d-6b7a0b4827b0',NULL,'Deploy',NULL,'task','medium','in_progress','019ef7a9-da2f-73f2-88a1-1e7849a91af2',NULL,'019ef3d3-e929-7298-80ce-21f75a189ec3',NULL,NULL,NULL,0.00,0.00,0,NULL,14,NULL,NULL,'2026-06-24 03:25:39','2026-06-24 03:26:37',NULL),('019ef7e1-d0f8-70de-af54-63a02d8f79d6','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef78f-d165-718a-b28d-6b7a0b4827b0',NULL,'Cập nhật UI/UX màn Job Applications để hiển thị trạng thái mới',NULL,'task','medium','in_progress','019ef3d3-e929-7298-80ce-21f75a189ec3',NULL,'019ef3d3-e929-7298-80ce-21f75a189ec3',NULL,NULL,NULL,0.00,0.00,2,'019ef791-2d1a-72bc-8c89-4ff2a414bbff',15,NULL,NULL,'2026-06-24 04:27:11','2026-06-24 04:27:43',NULL),('019ef7e1-f112-7164-a46f-0e862bc93bfc','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef78f-d159-71d9-ad7a-8c5ea536e419',NULL,'Cập nhật logic kéo trạng thái trên màn Lead',NULL,'task','medium','todo','019ef3d3-e929-7298-80ce-21f75a189ec3',NULL,'019ef3d3-e929-7298-80ce-21f75a189ec3',NULL,NULL,NULL,0.00,0.00,3,'019ef791-2d1a-72bc-8c89-4ff2a414bbff',16,NULL,NULL,'2026-06-24 04:27:20','2026-06-24 04:38:33',NULL),('019ef7e2-108f-71aa-9ad5-0208233f0e2a','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef790-28bf-710d-8dd2-366b2e94d89f',NULL,'Hiển thị danh sách job đang apply khi chuyển sang Start Work',NULL,'task','medium','todo','019ef3d3-e929-7298-80ce-21f75a189ec3',NULL,'019ef3d3-e929-7298-80ce-21f75a189ec3',NULL,NULL,NULL,0.00,0.00,0,'019ef791-2d1a-72bc-8c89-4ff2a414bbff',17,NULL,NULL,'2026-06-24 04:27:28','2026-06-24 04:38:39',NULL),('019ef7e2-2821-718f-abe1-04ef4786e043','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef78f-d168-719d-9933-7d4005560b55',NULL,'Thiết kế giao diện UI/UX cho màn Lead với các giới hạn kéo trạng thái',NULL,'task','medium','done','019ef3d3-e929-7298-80ce-21f75a189ec3',NULL,'019ef3d3-e929-7298-80ce-21f75a189ec3',NULL,NULL,NULL,0.00,0.00,3,'019ef791-2d1a-72bc-8c89-4ff2a414bbff',18,NULL,NULL,'2026-06-24 04:27:34','2026-06-24 04:38:43',NULL),('019ef7ee-5931-7309-a992-0d530cb7b063','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef78f-d167-7099-a70c-da0f791cc7d6',NULL,'Kiểm thử UI/UX mới trên màn Lead và Job Applications',NULL,'task','medium','in_review','019ef3d3-e929-7298-80ce-21f75a189ec3',NULL,'019ef3d3-e929-7298-80ce-21f75a189ec3',NULL,NULL,NULL,0.00,0.00,6,'019ef791-2d1a-72bc-8c89-4ff2a414bbff',19,NULL,NULL,'2026-06-24 04:40:53','2026-06-24 04:41:01',NULL),('019ef86d-96b7-7108-9fe8-6911f1451b85','019ef78f-d153-70a4-a65b-0b42b1c1c1fb','019ef78f-d159-71d9-ad7a-8c5ea536e419',NULL,'Implement Leads Page',NULL,'task','medium','todo','019ef3d3-e929-7298-80ce-21f75a189ec3',NULL,'019ef3d3-e929-7298-80ce-21f75a189ec3',NULL,NULL,NULL,0.00,0.00,4,NULL,20,NULL,NULL,'2026-06-24 06:59:52','2026-06-24 07:00:13',NULL);
/*!40000 ALTER TABLE `tasks` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `full_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `avatar_url` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `role` enum('owner','admin','manager','pm','team_lead','member','client','viewer') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'member',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `role_id` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `language` varchar(5) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'en',
  `appearance` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'light',
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `two_factor_enabled` tinyint(1) NOT NULL DEFAULT '0',
  `two_factor_secret` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `users_email_unique` (`email`),
  KEY `users_role_id_index` (`role_id`),
  CONSTRAINT `users_role_id_foreign` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES ('019ef3d3-e929-7298-80ce-21f75a189ec3','b1dung@sougo-career-vietnam.com','$2y$12$L2qhPstt1FdGqecE/nbtQOFhKT..1kjBBH/WRT0xfiYRzzU//m.Si','Bui Manh Dung','/uploads/avatars/ea3932d9-e59d-4518-b456-40adf843d9a5.jpg','owner',1,'019ef3d3-e83f-7338-b363-be7a340fc667','en','mint','2026-06-23 09:33:31',0,NULL,'2026-06-23 09:33:31'),('019ef7a0-583a-7142-9896-dabf327e2d08','b2son@sougo-career-vietnam.com','$2y$12$oEfDWdRTJ52CUCoCccnRAOyNH6liRQTHFNQPJXFxqH2mEPaefELPK','Bùi Hoàng Sơn',NULL,'member',1,'019ef3d3-e858-70b9-86a2-f63e4c74e400','en','light','2026-06-24 03:15:41',0,NULL,'2026-06-24 03:15:41'),('019ef7a0-c758-7336-9617-7893092a2442','d2tien@sougo-career-vietnam.com','$2y$12$K9yi.ITDzmDxBtJg8o.vvuUXS.z5JN3UHjjYCe5.xp81ffiPJjwp6','Đỗ Bá Tiến',NULL,'member',1,'019ef3d3-e858-70b9-86a2-f63e4c74e400','en','light','2026-06-24 03:16:09',0,NULL,'2026-06-24 03:16:09'),('019ef7a1-18e2-7073-8daa-6a65cd8a4034','d2giang@sougo-career-vietnam.com','$2y$12$DKkIgNvKpz490KL/aGnbmuzjgaH7wrub7Mha4DAE8HVB7pgjpswpC','Đoàn Văn Giang',NULL,'member',1,'019ef3d3-e858-70b9-86a2-f63e4c74e400','en','light','2026-06-24 03:16:30',0,NULL,'2026-06-24 03:16:30'),('019ef7a9-da2f-73f2-88a1-1e7849a91af2','v1thuc@sougo-career-vietnam.com','$2y$12$1cq2dOGSFnB07/dV4nR0XeZAImT6mrQkud.M6AUCzYnbJP/h91Cke','Vũ Văn Thức',NULL,'member',1,'019ef3d3-e858-70b9-86a2-f63e4c74e400','en','light','2026-06-24 03:26:04',0,NULL,'2026-06-24 03:26:04'),('019ef7c1-8431-722b-afbc-bde2fd6f21d2','l1linh@sougo-career-vietnam.com','$2y$12$gF3g4AA32nyp9QyyFm/2tuPEUqbmcdRzU.rCoLAKUFvfJCzwBv1pO','Lê Duy Linh',NULL,'member',1,'019ef3d3-e858-70b9-86a2-f63e4c74e400','en','light','2026-06-24 03:51:55',0,NULL,'2026-06-24 03:51:55'),('019ef7c1-f6af-71c7-8686-f2ccc8fef73d','d1tuan@sougo-career-vietnam.com','$2y$12$e9XJ7kH52aNd0HCdxy1rZeFtvdWVWKnBOAqMo2LmNV3LToI3pE4xu','Đỗ Anh Tuấn',NULL,'member',1,'019ef3d3-e84c-7132-9561-4f8276a2d554','en','light','2026-06-24 03:52:24',0,NULL,'2026-06-24 03:52:24'),('019ef7c2-8b2d-7281-a0ca-49580a604b66','n1thao@sougo-career-vietnam.com','$2y$12$TtXNF08qYyoqshIJFJEjOOtRrQH2BcNXxu2nXL0lGZaBdIFUDSyKa','Nguyễn Phương Thảo',NULL,'member',1,'019ef3d3-e858-70b9-86a2-f63e4c74e400','en','light','2026-06-24 03:53:02',0,NULL,'2026-06-24 03:53:02');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `working_hours`
--

DROP TABLE IF EXISTS `working_hours`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `working_hours` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `task_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `hours` decimal(6,2) NOT NULL,
  `is_qa` tinyint(1) NOT NULL DEFAULT '0',
  `logged_date` date NOT NULL,
  `note` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `working_hours_task_id_foreign` (`task_id`),
  KEY `working_hours_user_id_foreign` (`user_id`),
  CONSTRAINT `working_hours_task_id_foreign` FOREIGN KEY (`task_id`) REFERENCES `tasks` (`id`) ON DELETE CASCADE,
  CONSTRAINT `working_hours_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `working_hours`
--

LOCK TABLES `working_hours` WRITE;
/*!40000 ALTER TABLE `working_hours` DISABLE KEYS */;
INSERT INTO `working_hours` VALUES ('019ef7a4-43d5-7327-9cc0-7f8b2811a335','019ef791-de06-72e3-9119-a3fdb9b67ca2','019ef3d3-e929-7298-80ce-21f75a189ec3',6.00,0,'2026-06-24',NULL,'2026-06-24 03:19:58'),('019ef7a4-6ebb-704e-b722-b5b1a3de6aad','019ef791-f1e9-7026-adca-d4a03846fcd4','019ef3d3-e929-7298-80ce-21f75a189ec3',11.00,0,'2026-06-24',NULL,'2026-06-24 03:20:09'),('019ef7a4-8ef4-70be-a293-e1bf44557eab','019ef791-cd7d-703a-b732-e149c0a813ea','019ef3d3-e929-7298-80ce-21f75a189ec3',16.00,0,'2026-06-24',NULL,'2026-06-24 03:20:17'),('019ef7a4-cb99-7370-9733-ec4dbde8ee55','019ef791-b86f-7221-8253-d0a61d5ebdc4','019ef3d3-e929-7298-80ce-21f75a189ec3',15.00,0,'2026-06-24',NULL,'2026-06-24 03:20:32'),('019ef7a4-e8d1-7078-87ae-44957837e5ca','019ef791-8d18-71cf-9cfb-2d413f79d231','019ef3d3-e929-7298-80ce-21f75a189ec3',10.00,0,'2026-06-24',NULL,'2026-06-24 03:20:40'),('019ef7a5-091f-70c6-94b6-b5d1f3031fbc','019ef791-a215-7089-8eb1-2080249021f8','019ef3d3-e929-7298-80ce-21f75a189ec3',5.00,0,'2026-06-24',NULL,'2026-06-24 03:20:48'),('019ef7a5-3cc7-7021-8ebb-6bc480a4fcb2','019ef791-73c1-7352-9231-93cec452b7c2','019ef3d3-e929-7298-80ce-21f75a189ec3',20.00,0,'2026-06-24',NULL,'2026-06-24 03:21:01'),('019ef7a5-563d-71d0-b4f3-2c91bc7563b2','019ef791-530f-7094-aaf4-3e3dca2f582f','019ef3d3-e929-7298-80ce-21f75a189ec3',8.00,0,'2026-06-24',NULL,'2026-06-24 03:21:08'),('019ef7a5-73e4-7394-bb66-069c1d2bd1f7','019ef791-43ed-7098-8208-a0df5c2b8c0d','019ef3d3-e929-7298-80ce-21f75a189ec3',24.00,0,'2026-06-24',NULL,'2026-06-24 03:21:16'),('019ef7c5-5388-72af-97dd-784727b4ed29','019ef791-cd7d-703a-b732-e149c0a813ea','019ef3d3-e929-7298-80ce-21f75a189ec3',0.50,1,'2026-06-24',NULL,'2026-06-24 03:56:04'),('019ef7c5-8793-712f-a0d2-d38e45d92d8e','019ef791-f1e9-7026-adca-d4a03846fcd4','019ef3d3-e929-7298-80ce-21f75a189ec3',0.75,1,'2026-06-24',NULL,'2026-06-24 03:56:18'),('019ef7c5-d0e3-737b-9793-f06a7b829fb3','019ef791-de06-72e3-9119-a3fdb9b67ca2','019ef3d3-e929-7298-80ce-21f75a189ec3',1.50,1,'2026-06-24',NULL,'2026-06-24 03:56:36');
/*!40000 ALTER TABLE `working_hours` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'taskboard'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-06-25  6:34:00
