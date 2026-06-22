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
INSERT INTO `activity_logs` VALUES ('019eee18-6a47-7099-84e6-6398ebc3b287','019eee06-ae97-736d-acc4-a52252afd487','019eee08-0bf4-7213-86f5-7b5ec5938755','created','task','019eee18-6a3a-736f-a31a-12a1be25db48',NULL,'{\"title\": \"Update UI/UX màn lead\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019eee06-ae9e-70b0-a22c-8d2b0643b7e6\", \"priority\": \"medium\", \"assigneeId\": null}','172.20.0.1','2026-06-22 06:50:38'),('019eee18-bb05-7243-81a2-3ce3c1e6b0f6','019eee06-ae97-736d-acc4-a52252afd487','019eee08-0bf4-7213-86f5-7b5ec5938755','assigned','task','019eee18-6a3a-736f-a31a-12a1be25db48','{\"title\": \"Update UI/UX màn lead\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019eee06-ae9e-70b0-a22c-8d2b0643b7e6\", \"priority\": \"medium\", \"assigneeId\": null}','{\"title\": \"Update UI/UX màn lead\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019eee06-ae9e-70b0-a22c-8d2b0643b7e6\", \"priority\": \"medium\", \"assigneeId\": \"019eee08-0bf4-7213-86f5-7b5ec5938755\"}','172.20.0.1','2026-06-22 06:50:58'),('019eee19-0b5c-728e-9983-f47185b9bc31','019eee06-ae97-736d-acc4-a52252afd487','019eee08-0bf4-7213-86f5-7b5ec5938755','created','task','019eee19-0b4b-70e1-92b9-dac37c9b62a0',NULL,'{\"title\": \"Webhook security check\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019eee06-ae9e-70b0-a22c-8d2b0643b7e6\", \"priority\": \"medium\", \"assigneeId\": null}','172.20.0.1','2026-06-22 06:51:19'),('019eee19-2dcf-72fd-afa9-a20daf710503','019eee06-ae97-736d-acc4-a52252afd487','019eee08-0bf4-7213-86f5-7b5ec5938755','created','task','019eee19-2db6-7053-a2fe-112493694042',NULL,'{\"title\": \"Implement Candidates Page (Leads)\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019eee06-ae9e-70b0-a22c-8d2b0643b7e6\", \"priority\": \"medium\", \"assigneeId\": null}','172.20.0.1','2026-06-22 06:51:28'),('019eee19-448a-7275-b9cd-1e9a695ad16e','019eee06-ae97-736d-acc4-a52252afd487','019eee08-0bf4-7213-86f5-7b5ec5938755','created','task','019eee19-4481-7228-9494-aeccc27ce9b3',NULL,'{\"title\": \"Send a message Lead\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019eee06-ae9e-70b0-a22c-8d2b0643b7e6\", \"priority\": \"medium\", \"assigneeId\": null}','172.20.0.1','2026-06-22 06:51:33'),('019eee19-5970-73a1-8280-a72cbc29cadb','019eee06-ae97-736d-acc4-a52252afd487','019eee08-0bf4-7213-86f5-7b5ec5938755','created','task','019eee19-5965-7391-979c-9fa938981bee',NULL,'{\"title\": \"API update status màn Lead\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019eee06-ae9e-70b0-a22c-8d2b0643b7e6\", \"priority\": \"medium\", \"assigneeId\": null}','172.20.0.1','2026-06-22 06:51:39'),('019eee19-7432-7125-baf8-191ef8662b64','019eee06-ae97-736d-acc4-a52252afd487','019eee08-0bf4-7213-86f5-7b5ec5938755','created','task','019eee19-742b-7188-92e4-57dde8ab0771',NULL,'{\"title\": \"API update status màn Job applications\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019eee06-ae9e-70b0-a22c-8d2b0643b7e6\", \"priority\": \"medium\", \"assigneeId\": null}','172.20.0.1','2026-06-22 06:51:46'),('019eee1c-05a1-7178-a370-3d85835fb552','019eee06-ae97-736d-acc4-a52252afd487','019eee08-0bf4-7213-86f5-7b5ec5938755','assigned','task','019eee19-0b4b-70e1-92b9-dac37c9b62a0','{\"title\": \"Webhook security check\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019eee06-ae9e-70b0-a22c-8d2b0643b7e6\", \"priority\": \"medium\", \"assigneeId\": null}','{\"title\": \"Webhook security check\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019eee06-ae9e-70b0-a22c-8d2b0643b7e6\", \"priority\": \"medium\", \"assigneeId\": \"019eee1a-facb-70fd-9bc7-067a7613ac6a\"}','172.20.0.1','2026-06-22 06:54:34'),('019eee1c-0ca4-7018-8c79-89e16a2ad901','019eee06-ae97-736d-acc4-a52252afd487','019eee08-0bf4-7213-86f5-7b5ec5938755','assigned','task','019eee19-2db6-7053-a2fe-112493694042','{\"title\": \"Implement Candidates Page (Leads)\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019eee06-ae9e-70b0-a22c-8d2b0643b7e6\", \"priority\": \"medium\", \"assigneeId\": null}','{\"title\": \"Implement Candidates Page (Leads)\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019eee06-ae9e-70b0-a22c-8d2b0643b7e6\", \"priority\": \"medium\", \"assigneeId\": \"019eee1b-5f37-732b-87c9-439e4b65c8de\"}','172.20.0.1','2026-06-22 06:54:36'),('019eee1c-1468-71b0-830e-f7b91caf841d','019eee06-ae97-736d-acc4-a52252afd487','019eee08-0bf4-7213-86f5-7b5ec5938755','assigned','task','019eee19-4481-7228-9494-aeccc27ce9b3','{\"title\": \"Send a message Lead\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019eee06-ae9e-70b0-a22c-8d2b0643b7e6\", \"priority\": \"medium\", \"assigneeId\": null}','{\"title\": \"Send a message Lead\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019eee06-ae9e-70b0-a22c-8d2b0643b7e6\", \"priority\": \"medium\", \"assigneeId\": \"019eee05-40f4-7379-bc0c-547bf006d433\"}','172.20.0.1','2026-06-22 06:54:38'),('019eee1c-22dc-7023-a358-3f0925c33716','019eee06-ae97-736d-acc4-a52252afd487','019eee08-0bf4-7213-86f5-7b5ec5938755','assigned','task','019eee19-5965-7391-979c-9fa938981bee','{\"title\": \"API update status màn Lead\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019eee06-ae9e-70b0-a22c-8d2b0643b7e6\", \"priority\": \"medium\", \"assigneeId\": null}','{\"title\": \"API update status màn Lead\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019eee06-ae9e-70b0-a22c-8d2b0643b7e6\", \"priority\": \"medium\", \"assigneeId\": \"019eee05-403c-73cb-80be-46e4e79e2577\"}','172.20.0.1','2026-06-22 06:54:41'),('019eee1c-317c-72f9-9696-a54531418c41','019eee06-ae97-736d-acc4-a52252afd487','019eee08-0bf4-7213-86f5-7b5ec5938755','assigned','task','019eee19-742b-7188-92e4-57dde8ab0771','{\"title\": \"API update status màn Job applications\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019eee06-ae9e-70b0-a22c-8d2b0643b7e6\", \"priority\": \"medium\", \"assigneeId\": null}','{\"title\": \"API update status màn Job applications\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019eee06-ae9e-70b0-a22c-8d2b0643b7e6\", \"priority\": \"medium\", \"assigneeId\": \"019eee05-3f83-72e1-bf62-96a9befa0c8e\"}','172.20.0.1','2026-06-22 06:54:45'),('019eee1c-3a04-7321-b08c-86e681aa0a1c','019eee06-ae97-736d-acc4-a52252afd487','019eee08-0bf4-7213-86f5-7b5ec5938755','moved','task','019eee18-6a3a-736f-a31a-12a1be25db48','{\"title\": \"Update UI/UX màn lead\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019eee06-ae9e-70b0-a22c-8d2b0643b7e6\", \"priority\": \"medium\", \"assigneeId\": \"019eee08-0bf4-7213-86f5-7b5ec5938755\"}','{\"title\": \"Update UI/UX màn lead\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019eee06-aea0-7370-8e22-a5c9e9010ec0\", \"priority\": \"medium\", \"assigneeId\": \"019eee08-0bf4-7213-86f5-7b5ec5938755\"}','172.20.0.1','2026-06-22 06:54:47'),('019eee1c-46f7-7241-822c-67e10091f092','019eee06-ae97-736d-acc4-a52252afd487','019eee08-0bf4-7213-86f5-7b5ec5938755','moved','task','019eee19-2db6-7053-a2fe-112493694042','{\"title\": \"Implement Candidates Page (Leads)\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019eee06-ae9e-70b0-a22c-8d2b0643b7e6\", \"priority\": \"medium\", \"assigneeId\": \"019eee1b-5f37-732b-87c9-439e4b65c8de\"}','{\"title\": \"Implement Candidates Page (Leads)\", \"status\": \"in_review\", \"dueDate\": null, \"columnId\": \"019eee06-aea2-7152-b0d9-f3ed6d060b9e\", \"priority\": \"medium\", \"assigneeId\": \"019eee1b-5f37-732b-87c9-439e4b65c8de\"}','172.20.0.1','2026-06-22 06:54:51'),('019eee1c-4d82-738f-994c-37324fddfae2','019eee06-ae97-736d-acc4-a52252afd487','019eee08-0bf4-7213-86f5-7b5ec5938755','moved','task','019eee19-4481-7228-9494-aeccc27ce9b3','{\"title\": \"Send a message Lead\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019eee06-ae9e-70b0-a22c-8d2b0643b7e6\", \"priority\": \"medium\", \"assigneeId\": \"019eee05-40f4-7379-bc0c-547bf006d433\"}','{\"title\": \"Send a message Lead\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019eee06-aea0-7370-8e22-a5c9e9010ec0\", \"priority\": \"medium\", \"assigneeId\": \"019eee05-40f4-7379-bc0c-547bf006d433\"}','172.20.0.1','2026-06-22 06:54:52'),('019eee1c-5531-70f5-ae1c-ea63f55a4d5d','019eee06-ae97-736d-acc4-a52252afd487','019eee08-0bf4-7213-86f5-7b5ec5938755','moved','task','019eee19-742b-7188-92e4-57dde8ab0771','{\"title\": \"API update status màn Job applications\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019eee06-ae9e-70b0-a22c-8d2b0643b7e6\", \"priority\": \"medium\", \"assigneeId\": \"019eee05-3f83-72e1-bf62-96a9befa0c8e\"}','{\"title\": \"API update status màn Job applications\", \"status\": \"in_review\", \"dueDate\": null, \"columnId\": \"019eee06-aea2-7152-b0d9-f3ed6d060b9e\", \"priority\": \"medium\", \"assigneeId\": \"019eee05-3f83-72e1-bf62-96a9befa0c8e\"}','172.20.0.1','2026-06-22 06:54:54'),('019eee1c-5e27-722f-bdb1-a99e568df936','019eee06-ae97-736d-acc4-a52252afd487','019eee08-0bf4-7213-86f5-7b5ec5938755','moved','task','019eee19-5965-7391-979c-9fa938981bee','{\"title\": \"API update status màn Lead\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019eee06-ae9e-70b0-a22c-8d2b0643b7e6\", \"priority\": \"medium\", \"assigneeId\": \"019eee05-403c-73cb-80be-46e4e79e2577\"}','{\"title\": \"API update status màn Lead\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019eee06-aea0-7370-8e22-a5c9e9010ec0\", \"priority\": \"medium\", \"assigneeId\": \"019eee05-403c-73cb-80be-46e4e79e2577\"}','172.20.0.1','2026-06-22 06:54:57'),('019eee1c-6bf5-73e2-b061-67291e6c2b99','019eee06-ae97-736d-acc4-a52252afd487','019eee08-0bf4-7213-86f5-7b5ec5938755','moved','task','019eee18-6a3a-736f-a31a-12a1be25db48','{\"title\": \"Update UI/UX màn lead\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019eee06-aea0-7370-8e22-a5c9e9010ec0\", \"priority\": \"medium\", \"assigneeId\": \"019eee08-0bf4-7213-86f5-7b5ec5938755\"}','{\"title\": \"Update UI/UX màn lead\", \"status\": \"in_review\", \"dueDate\": null, \"columnId\": \"019eee06-aea2-7152-b0d9-f3ed6d060b9e\", \"priority\": \"medium\", \"assigneeId\": \"019eee08-0bf4-7213-86f5-7b5ec5938755\"}','172.20.0.1','2026-06-22 06:55:00'),('019eee1c-7629-7381-935e-5ecee712fa8a','019eee06-ae97-736d-acc4-a52252afd487','019eee08-0bf4-7213-86f5-7b5ec5938755','moved','task','019eee18-6a3a-736f-a31a-12a1be25db48','{\"title\": \"Update UI/UX màn lead\", \"status\": \"in_review\", \"dueDate\": null, \"columnId\": \"019eee06-aea2-7152-b0d9-f3ed6d060b9e\", \"priority\": \"medium\", \"assigneeId\": \"019eee08-0bf4-7213-86f5-7b5ec5938755\"}','{\"title\": \"Update UI/UX màn lead\", \"status\": \"done\", \"dueDate\": null, \"columnId\": \"019eee06-aea3-7326-a998-0b4af6946e5c\", \"priority\": \"medium\", \"assigneeId\": \"019eee08-0bf4-7213-86f5-7b5ec5938755\"}','172.20.0.1','2026-06-22 06:55:03'),('019eee1c-b96a-7123-8629-40ba0a991709','019eee06-ae97-736d-acc4-a52252afd487','019eee08-0bf4-7213-86f5-7b5ec5938755','updated','task','019eee18-6a3a-736f-a31a-12a1be25db48',NULL,'{\"loggedHours\": 16}','172.20.0.1','2026-06-22 06:55:20'),('019eee1d-784e-7345-8905-86f85f314e27','019eee06-ae97-736d-acc4-a52252afd487','019eee1b-5f37-732b-87c9-439e4b65c8de','status_changed','task','019eee19-2db6-7053-a2fe-112493694042','{\"title\": \"Implement Candidates Page (Leads)\", \"status\": \"in_review\", \"dueDate\": null, \"columnId\": \"019eee06-aea2-7152-b0d9-f3ed6d060b9e\", \"priority\": \"medium\", \"assigneeId\": \"019eee1b-5f37-732b-87c9-439e4b65c8de\"}','{\"title\": \"Implement Candidates Page (Leads)\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019eee06-aea0-7370-8e22-a5c9e9010ec0\", \"priority\": \"medium\", \"assigneeId\": \"019eee1b-5f37-732b-87c9-439e4b65c8de\"}','172.20.0.1','2026-06-22 06:56:09'),('019eee1e-c92a-71c6-ba97-903943c76666','019eee06-ae97-736d-acc4-a52252afd487','019eee1b-5f37-732b-87c9-439e4b65c8de','moved','task','019eee19-5965-7391-979c-9fa938981bee','{\"title\": \"API update status màn Lead\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019eee06-aea0-7370-8e22-a5c9e9010ec0\", \"priority\": \"medium\", \"assigneeId\": \"019eee05-403c-73cb-80be-46e4e79e2577\"}','{\"title\": \"API update status màn Lead\", \"status\": \"in_review\", \"dueDate\": null, \"columnId\": \"019eee06-aea2-7152-b0d9-f3ed6d060b9e\", \"priority\": \"medium\", \"assigneeId\": \"019eee05-403c-73cb-80be-46e4e79e2577\"}','172.20.0.1','2026-06-22 06:57:35'),('019eee1e-d0a7-72ae-8f4d-b440c71b3a25','019eee06-ae97-736d-acc4-a52252afd487','019eee1b-5f37-732b-87c9-439e4b65c8de','moved','task','019eee19-5965-7391-979c-9fa938981bee','{\"title\": \"API update status màn Lead\", \"status\": \"in_review\", \"dueDate\": null, \"columnId\": \"019eee06-aea2-7152-b0d9-f3ed6d060b9e\", \"priority\": \"medium\", \"assigneeId\": \"019eee05-403c-73cb-80be-46e4e79e2577\"}','{\"title\": \"API update status màn Lead\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019eee06-aea0-7370-8e22-a5c9e9010ec0\", \"priority\": \"medium\", \"assigneeId\": \"019eee05-403c-73cb-80be-46e4e79e2577\"}','172.20.0.1','2026-06-22 06:57:37'),('019eee21-0978-71d6-92e0-6d08ea149b22','019eee06-ae97-736d-acc4-a52252afd487','019eee08-0bf4-7213-86f5-7b5ec5938755','created','task','019eee21-0967-71c0-ac81-ae8f08a8a3c4',NULL,'{\"title\": \"Cập nhật UI/UX màn Job Applications để hiển thị trạng thái mới\", \"status\": \"done\", \"dueDate\": null, \"columnId\": \"019eee06-aea3-7326-a998-0b4af6946e5c\", \"priority\": \"medium\", \"assigneeId\": null}','172.20.0.1','2026-06-22 07:00:03'),('019eee21-45f3-73a3-bce6-0b78c9f311b1','019eee06-ae97-736d-acc4-a52252afd487','019eee08-0bf4-7213-86f5-7b5ec5938755','moved','task','019eee18-6a3a-736f-a31a-12a1be25db48','{\"title\": \"Update UI/UX màn lead\", \"status\": \"done\", \"dueDate\": null, \"columnId\": \"019eee06-aea3-7326-a998-0b4af6946e5c\", \"priority\": \"medium\", \"assigneeId\": \"019eee08-0bf4-7213-86f5-7b5ec5938755\"}','{\"title\": \"Update UI/UX màn lead\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019eee06-aea0-7370-8e22-a5c9e9010ec0\", \"priority\": \"medium\", \"assigneeId\": \"019eee08-0bf4-7213-86f5-7b5ec5938755\"}','172.20.0.1','2026-06-22 07:00:18'),('019eee21-6d0a-7070-8c3f-4d9a92b399ac','019eee06-ae97-736d-acc4-a52252afd487','019eee08-0bf4-7213-86f5-7b5ec5938755','status_changed','task','019eee21-0967-71c0-ac81-ae8f08a8a3c4','{\"title\": \"Cập nhật UI/UX màn Job Applications để hiển thị trạng thái mới\", \"status\": \"done\", \"dueDate\": null, \"columnId\": \"019eee06-aea3-7326-a998-0b4af6946e5c\", \"priority\": \"medium\", \"assigneeId\": null}','{\"title\": \"Cập nhật UI/UX màn Job Applications để hiển thị trạng thái mới\", \"status\": \"todo\", \"dueDate\": null, \"columnId\": \"019eee06-ae9e-70b0-a22c-8d2b0643b7e6\", \"priority\": \"medium\", \"assigneeId\": null}','172.20.0.1','2026-06-22 07:00:28'),('019eee40-f8da-7355-a068-380a7675b605','019eee06-ae97-736d-acc4-a52252afd487','019eee08-0bf4-7213-86f5-7b5ec5938755','created','task','019eee40-f8cb-70bc-a9c0-4405d08b7622',NULL,'{\"title\": \"sub task 1\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019eee06-aea0-7370-8e22-a5c9e9010ec0\", \"priority\": \"medium\", \"assigneeId\": null}','172.20.0.1','2026-06-22 07:34:55'),('019eee4a-8086-733e-930b-94a9824af947','019eee06-ae97-736d-acc4-a52252afd487','019eee08-0bf4-7213-86f5-7b5ec5938755','created','task','019eee4a-8062-709c-9be3-34516a6b611f',NULL,'{\"title\": \"Hiển thị danh sách job đang apply khi chuyển sang Start Work\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019eee06-aea0-7370-8e22-a5c9e9010ec0\", \"priority\": \"medium\", \"assigneeId\": null}','172.20.0.1','2026-06-22 07:45:20'),('019eee63-2766-71dd-a09b-635ac05dc0e5','019eee06-ae97-736d-acc4-a52252afd487','019eee08-0bf4-7213-86f5-7b5ec5938755','moved','task','019eee18-6a3a-736f-a31a-12a1be25db48','{\"title\": \"Update UI/UX màn lead\", \"status\": \"in_progress\", \"dueDate\": null, \"columnId\": \"019eee06-aea0-7370-8e22-a5c9e9010ec0\", \"priority\": \"medium\", \"assigneeId\": \"019eee08-0bf4-7213-86f5-7b5ec5938755\"}','{\"title\": \"Update UI/UX màn lead\", \"status\": \"in_review\", \"dueDate\": null, \"columnId\": \"019eee06-aea2-7152-b0d9-f3ed6d060b9e\", \"priority\": \"medium\", \"assigneeId\": \"019eee08-0bf4-7213-86f5-7b5ec5938755\"}','172.20.0.1','2026-06-22 08:12:16'),('019eee83-6937-716c-a66d-8ae3b5d0992b','019eee06-ae97-736d-acc4-a52252afd487','019eee08-0bf4-7213-86f5-7b5ec5938755','commented','comment','019eee83-692a-73d4-8300-5c8764a16892',NULL,'{\"taskId\": \"019eee19-5965-7391-979c-9fa938981bee\", \"content\": \"làm đến đâu rồi\"}','172.20.0.1','2026-06-22 08:47:30');
/*!40000 ALTER TABLE `activity_logs` ENABLE KEYS */;
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
INSERT INTO `columns` VALUES ('019eee06-ae9e-70b0-a22c-8d2b0643b7e6','019eee06-ae97-736d-acc4-a52252afd487','To Do',0,'#6b7280',NULL,'2026-06-22 06:31:15'),('019eee06-aea0-7370-8e22-a5c9e9010ec0','019eee06-ae97-736d-acc4-a52252afd487','In Progress',1,'#3b82f6',NULL,'2026-06-22 06:31:15'),('019eee06-aea2-7152-b0d9-f3ed6d060b9e','019eee06-ae97-736d-acc4-a52252afd487','In Review',2,'#8b5cf6',NULL,'2026-06-22 06:31:15'),('019eee06-aea3-7326-a998-0b4af6946e5c','019eee06-ae97-736d-acc4-a52252afd487','Done',3,'#10b981',NULL,'2026-06-22 06:31:15');
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
INSERT INTO `comments` VALUES ('019eee83-692a-73d4-8300-5c8764a16892','019eee19-5965-7391-979c-9fa938981bee','019eee08-0bf4-7213-86f5-7b5ec5938755','làm đến đâu rồi',NULL,NULL,'2026-06-22 08:47:30',NULL);
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
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `migrations`
--

LOCK TABLES `migrations` WRITE;
/*!40000 ALTER TABLE `migrations` DISABLE KEYS */;
INSERT INTO `migrations` VALUES (1,'0001_01_01_000000_create_users_table',1),(2,'0001_01_01_000001_create_cache_table',1),(3,'0001_01_01_000002_create_jobs_table',1),(4,'2026_06_21_104505_create_personal_access_tokens_table',1),(5,'2026_06_21_110001_create_roles_table',1),(6,'2026_06_21_110002_create_projects_tables',1),(7,'2026_06_21_110003_create_board_tables',1),(8,'2026_06_21_110004_create_tasks_tables',1),(9,'2026_06_21_110005_create_collaboration_tables',1),(10,'2026_06_21_110006_create_system_tables',1);
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
INSERT INTO `notifications` VALUES ('0230793e-333f-4a97-9523-8ecf434468d3','019eee05-3f83-72e1-bf62-96a9befa0c8e','019eee08-0bf4-7213-86f5-7b5ec5938755','task_created','task','019eee21-0967-71c0-ac81-ae8f08a8a3c4','created task \"Cập nhật UI/UX màn Job Applications để hiển thị trạng thái mới\"',NULL,'2026-06-22 07:00:03'),('04548aac-aa81-4836-8a88-45721454d1f9','019eee05-403c-73cb-80be-46e4e79e2577','019eee1b-5f37-732b-87c9-439e4b65c8de','task_moved','task','019eee19-5965-7391-979c-9fa938981bee','moved task \"API update status màn Lead\"',NULL,'2026-06-22 06:57:35'),('09daa065-caf2-4412-8d8f-afc199d781e1','019eee05-3f83-72e1-bf62-96a9befa0c8e','019eee08-0bf4-7213-86f5-7b5ec5938755','task_moved','task','019eee18-6a3a-736f-a31a-12a1be25db48','moved task \"Update UI/UX màn lead\"',NULL,'2026-06-22 08:12:16'),('09fc79d0-8176-4146-88ed-9def3c748e1f','019eee05-3f83-72e1-bf62-96a9befa0c8e','019eee08-0bf4-7213-86f5-7b5ec5938755','task_created','task','019eee18-6a3a-736f-a31a-12a1be25db48','created task \"Update UI/UX màn lead\"',NULL,'2026-06-22 06:50:38'),('0cff444e-42e4-4fdc-98bc-fba62c4750b5','019eee05-3f83-72e1-bf62-96a9befa0c8e','019eee08-0bf4-7213-86f5-7b5ec5938755','task_created','task','019eee19-5965-7391-979c-9fa938981bee','created task \"API update status màn Lead\"',NULL,'2026-06-22 06:51:39'),('103446e3-4a38-42ab-988d-5c9e06717db8','019eee05-3f83-72e1-bf62-96a9befa0c8e','019eee08-0bf4-7213-86f5-7b5ec5938755','task_assigned','task','019eee19-2db6-7053-a2fe-112493694042','updated task \"Implement Candidates Page (Leads)\"',NULL,'2026-06-22 06:54:36'),('1141ee83-ebe0-4d1b-b907-1daf00961145','019eee05-3f83-72e1-bf62-96a9befa0c8e','019eee08-0bf4-7213-86f5-7b5ec5938755','task_moved','task','019eee19-2db6-7053-a2fe-112493694042','moved task \"Implement Candidates Page (Leads)\"',NULL,'2026-06-22 06:54:51'),('21b06b1e-5e24-4d2e-bcbd-c578d6b68cd1','019eee05-40f4-7379-bc0c-547bf006d433','019eee08-0bf4-7213-86f5-7b5ec5938755','task_moved','task','019eee19-4481-7228-9494-aeccc27ce9b3','moved task \"Send a message Lead\"',NULL,'2026-06-22 06:54:52'),('243d0f15-68bd-440b-9c89-3c76090141ff','019eee05-3f83-72e1-bf62-96a9befa0c8e','019eee08-0bf4-7213-86f5-7b5ec5938755','task_assigned','task','019eee19-5965-7391-979c-9fa938981bee','updated task \"API update status màn Lead\"',NULL,'2026-06-22 06:54:41'),('2494f65c-83a3-4f40-9a78-e9d15755264e','019eee05-3f83-72e1-bf62-96a9befa0c8e','019eee1b-5f37-732b-87c9-439e4b65c8de','task_updated','task','019eee19-2db6-7053-a2fe-112493694042','updated task \"Implement Candidates Page (Leads)\"',NULL,'2026-06-22 06:56:09'),('364553f2-0fa6-4088-a6a5-df91172ab0e1','019eee05-3f83-72e1-bf62-96a9befa0c8e','019eee08-0bf4-7213-86f5-7b5ec5938755','task_moved','task','019eee19-4481-7228-9494-aeccc27ce9b3','moved task \"Send a message Lead\"',NULL,'2026-06-22 06:54:52'),('3ab3c445-ebe4-4fb2-90b4-9efa83219d0c','019eee08-0bf4-7213-86f5-7b5ec5938755','019eee1b-5f37-732b-87c9-439e4b65c8de','task_updated','task','019eee19-2db6-7053-a2fe-112493694042','updated task \"Implement Candidates Page (Leads)\"','2026-06-22 08:48:02','2026-06-22 06:56:09'),('43ae7062-160a-4c70-8111-a561fd6e4413','019eee05-3f83-72e1-bf62-96a9befa0c8e','019eee08-0bf4-7213-86f5-7b5ec5938755','task_updated','task','019eee21-0967-71c0-ac81-ae8f08a8a3c4','updated task \"Cập nhật UI/UX màn Job Applications để hiển thị trạng thái mới\"',NULL,'2026-06-22 07:00:28'),('477736dd-c129-403d-a13f-8c45f49d75c6','019eee05-3f83-72e1-bf62-96a9befa0c8e','019eee08-0bf4-7213-86f5-7b5ec5938755','task_created','task','019eee19-742b-7188-92e4-57dde8ab0771','created task \"API update status màn Job applications\"',NULL,'2026-06-22 06:51:46'),('4fba8bae-7b6e-4cfa-8f4f-2a353a8e575a','019eee05-3f83-72e1-bf62-96a9befa0c8e','019eee08-0bf4-7213-86f5-7b5ec5938755','task_moved','task','019eee19-742b-7188-92e4-57dde8ab0771','moved task \"API update status màn Job applications\"',NULL,'2026-06-22 06:54:54'),('59a3df88-6449-4333-bc53-8a0df0c71e1b','019eee05-3f83-72e1-bf62-96a9befa0c8e','019eee08-0bf4-7213-86f5-7b5ec5938755','task_moved','task','019eee19-5965-7391-979c-9fa938981bee','moved task \"API update status màn Lead\"',NULL,'2026-06-22 06:54:57'),('5f747732-41ab-404f-bddb-4cd955eae35e','019eee05-3f83-72e1-bf62-96a9befa0c8e','019eee08-0bf4-7213-86f5-7b5ec5938755','task_created','task','019eee19-4481-7228-9494-aeccc27ce9b3','created task \"Send a message Lead\"',NULL,'2026-06-22 06:51:33'),('631f7011-c1a6-4467-b5f4-59a4f29eb787','019eee05-3f83-72e1-bf62-96a9befa0c8e','019eee08-0bf4-7213-86f5-7b5ec5938755','comment_added','comment','019eee83-692a-73d4-8300-5c8764a16892','commented on \"API update status màn Lead\"',NULL,'2026-06-22 08:47:30'),('65c46aaa-506b-487d-a1f3-2b894ca2e1f3','019eee05-40f4-7379-bc0c-547bf006d433','019eee08-0bf4-7213-86f5-7b5ec5938755','task_assigned','task','019eee19-4481-7228-9494-aeccc27ce9b3','updated task \"Send a message Lead\"',NULL,'2026-06-22 06:54:38'),('685b6164-c6c0-4a13-80e7-7a44ac4500c3','019eee05-3f83-72e1-bf62-96a9befa0c8e','019eee08-0bf4-7213-86f5-7b5ec5938755','task_assigned','task','019eee19-4481-7228-9494-aeccc27ce9b3','updated task \"Send a message Lead\"',NULL,'2026-06-22 06:54:38'),('6c911916-8487-4546-b818-5c818d0871d1','019eee05-3f83-72e1-bf62-96a9befa0c8e','019eee08-0bf4-7213-86f5-7b5ec5938755','task_assigned','task','019eee19-742b-7188-92e4-57dde8ab0771','updated task \"API update status màn Job applications\"',NULL,'2026-06-22 06:54:45'),('76b7b91d-e853-4aae-8963-6a94ceeebdf0','019eee05-403c-73cb-80be-46e4e79e2577','019eee08-0bf4-7213-86f5-7b5ec5938755','task_assigned','task','019eee19-5965-7391-979c-9fa938981bee','updated task \"API update status màn Lead\"',NULL,'2026-06-22 06:54:41'),('7e1c32a0-9a75-427e-816a-94a5f0b13253','019eee05-403c-73cb-80be-46e4e79e2577','019eee08-0bf4-7213-86f5-7b5ec5938755','task_moved','task','019eee19-5965-7391-979c-9fa938981bee','moved task \"API update status màn Lead\"',NULL,'2026-06-22 06:54:57'),('8ac58eee-ce9b-4854-87b8-80da30e92f12','019eee05-3f83-72e1-bf62-96a9befa0c8e','019eee08-0bf4-7213-86f5-7b5ec5938755','task_assigned','task','019eee18-6a3a-736f-a31a-12a1be25db48','updated task \"Update UI/UX màn lead\"',NULL,'2026-06-22 06:50:58'),('8d827c4d-2954-4077-8db5-eda08bed3bc7','019eee05-3f83-72e1-bf62-96a9befa0c8e','019eee08-0bf4-7213-86f5-7b5ec5938755','task_created','task','019eee19-0b4b-70e1-92b9-dac37c9b62a0','created task \"Webhook security check\"',NULL,'2026-06-22 06:51:19'),('8e37ccdd-b25a-48dc-8447-a562bf0a40dc','019eee08-0bf4-7213-86f5-7b5ec5938755','019eee1b-5f37-732b-87c9-439e4b65c8de','task_moved','task','019eee19-5965-7391-979c-9fa938981bee','moved task \"API update status màn Lead\"','2026-06-22 08:47:51','2026-06-22 06:57:35'),('9d312ce7-1b48-4c44-9ddc-8429322f2129','019eee08-0bf4-7213-86f5-7b5ec5938755','019eee1b-5f37-732b-87c9-439e4b65c8de','task_moved','task','019eee19-5965-7391-979c-9fa938981bee','moved task \"API update status màn Lead\"','2026-06-22 08:47:49','2026-06-22 06:57:37'),('9d9c6405-919c-4eab-8680-2bed6fd9dd98','019eee1a-facb-70fd-9bc7-067a7613ac6a','019eee08-0bf4-7213-86f5-7b5ec5938755','task_assigned','task','019eee19-0b4b-70e1-92b9-dac37c9b62a0','updated task \"Webhook security check\"',NULL,'2026-06-22 06:54:34'),('a1b27d21-b24a-41a6-a66e-632f640b40cb','019eee05-3f83-72e1-bf62-96a9befa0c8e','019eee1b-5f37-732b-87c9-439e4b65c8de','task_moved','task','019eee19-5965-7391-979c-9fa938981bee','moved task \"API update status màn Lead\"',NULL,'2026-06-22 06:57:37'),('ac96203b-164b-4da0-b996-a8750ef8e227','019eee05-3f83-72e1-bf62-96a9befa0c8e','019eee08-0bf4-7213-86f5-7b5ec5938755','time_logged','task','019eee18-6a3a-736f-a31a-12a1be25db48','logged time on \"Update UI/UX màn lead\"',NULL,'2026-06-22 06:55:20'),('b2fb4b70-125c-460f-9ddd-79425202303e','019eee05-3f83-72e1-bf62-96a9befa0c8e','019eee08-0bf4-7213-86f5-7b5ec5938755','task_moved','task','019eee18-6a3a-736f-a31a-12a1be25db48','moved task \"Update UI/UX màn lead\"',NULL,'2026-06-22 07:00:18'),('b64bd46c-df19-4f4a-a12e-6e2a0d6bd0c1','019eee05-403c-73cb-80be-46e4e79e2577','019eee08-0bf4-7213-86f5-7b5ec5938755','comment_added','comment','019eee83-692a-73d4-8300-5c8764a16892','commented on \"API update status màn Lead\"',NULL,'2026-06-22 08:47:30'),('c7c50c70-d0d6-4a7c-b1f5-9157deb2b4b1','019eee05-3f83-72e1-bf62-96a9befa0c8e','019eee08-0bf4-7213-86f5-7b5ec5938755','task_created','task','019eee4a-8062-709c-9be3-34516a6b611f','created task \"Hiển thị danh sách job đang apply khi chuyển sang Start Work\"',NULL,'2026-06-22 07:45:20'),('ca4ea753-b267-4aee-ba27-21adab589941','019eee05-3f83-72e1-bf62-96a9befa0c8e','019eee08-0bf4-7213-86f5-7b5ec5938755','task_moved','task','019eee18-6a3a-736f-a31a-12a1be25db48','moved task \"Update UI/UX màn lead\"',NULL,'2026-06-22 06:55:03'),('cc6a5787-3c47-4ef0-a150-2014d069b65c','019eee05-403c-73cb-80be-46e4e79e2577','019eee1b-5f37-732b-87c9-439e4b65c8de','task_moved','task','019eee19-5965-7391-979c-9fa938981bee','moved task \"API update status màn Lead\"',NULL,'2026-06-22 06:57:37'),('d703bf2f-fcda-4adf-bfc6-a447d0975abd','019eee1b-5f37-732b-87c9-439e4b65c8de','019eee08-0bf4-7213-86f5-7b5ec5938755','task_assigned','task','019eee19-2db6-7053-a2fe-112493694042','updated task \"Implement Candidates Page (Leads)\"','2026-06-22 06:57:50','2026-06-22 06:54:36'),('d88a8128-52dd-4a57-962a-219bfee2f1d3','019eee05-3f83-72e1-bf62-96a9befa0c8e','019eee08-0bf4-7213-86f5-7b5ec5938755','task_created','task','019eee40-f8cb-70bc-a9c0-4405d08b7622','created task \"sub task 1\"',NULL,'2026-06-22 07:34:55'),('d923070b-dc12-44ce-a148-1f0772f9cc7f','019eee05-3f83-72e1-bf62-96a9befa0c8e','019eee08-0bf4-7213-86f5-7b5ec5938755','task_created','task','019eee19-2db6-7053-a2fe-112493694042','created task \"Implement Candidates Page (Leads)\"',NULL,'2026-06-22 06:51:28'),('dbe053c1-a830-4b56-9d5d-2c168ce1dfa9','019eee05-3f83-72e1-bf62-96a9befa0c8e','019eee1b-5f37-732b-87c9-439e4b65c8de','task_moved','task','019eee19-5965-7391-979c-9fa938981bee','moved task \"API update status màn Lead\"',NULL,'2026-06-22 06:57:35'),('ee6dc086-14f1-4382-a5e9-b71488387f68','019eee05-3f83-72e1-bf62-96a9befa0c8e','019eee08-0bf4-7213-86f5-7b5ec5938755','task_moved','task','019eee18-6a3a-736f-a31a-12a1be25db48','moved task \"Update UI/UX màn lead\"',NULL,'2026-06-22 06:55:00'),('ef757511-b3b0-4657-bf1f-459b8a25ea36','019eee05-3f83-72e1-bf62-96a9befa0c8e','019eee08-0bf4-7213-86f5-7b5ec5938755','task_moved','task','019eee18-6a3a-736f-a31a-12a1be25db48','moved task \"Update UI/UX màn lead\"',NULL,'2026-06-22 06:54:47'),('f6333f8a-50bc-4d82-baf2-323ce1729da7','019eee1b-5f37-732b-87c9-439e4b65c8de','019eee08-0bf4-7213-86f5-7b5ec5938755','task_moved','task','019eee19-2db6-7053-a2fe-112493694042','moved task \"Implement Candidates Page (Leads)\"','2026-06-22 06:56:04','2026-06-22 06:54:51'),('fde10f02-3b0f-4132-877a-96e5eaea1747','019eee05-3f83-72e1-bf62-96a9befa0c8e','019eee08-0bf4-7213-86f5-7b5ec5938755','task_assigned','task','019eee19-0b4b-70e1-92b9-dac37c9b62a0','updated task \"Webhook security check\"',NULL,'2026-06-22 06:54:34');
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
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `personal_access_tokens`
--

LOCK TABLES `personal_access_tokens` WRITE;
/*!40000 ALTER TABLE `personal_access_tokens` DISABLE KEYS */;
INSERT INTO `personal_access_tokens` VALUES (2,'App\\Models\\User','019eee08-0bf4-7213-86f5-7b5ec5938755','access','6ea7ea87c1cb20b920160852ee95f52eb3717780bc4cef1f36b30b2e613b090b','[\"*\"]','2026-06-22 06:36:53','2026-06-22 06:47:53','2026-06-22 06:32:53','2026-06-22 06:36:53'),(3,'App\\Models\\User','019eee05-3f83-72e1-bf62-96a9befa0c8e','access','61365c1388aaaf6d15d27aa75ba14e2b2c24f9d93a969f1787d5a1c1c51fbe15','[\"*\"]',NULL,'2026-06-22 06:54:43','2026-06-22 06:39:43','2026-06-22 06:39:43'),(4,'App\\Models\\User','019eee08-0bf4-7213-86f5-7b5ec5938755','access','e5edf5919339b554322cb4c4ff2d169c9c382c8eb52955626ca654e15af515c7','[\"*\"]','2026-06-22 06:55:04','2026-06-22 06:55:20','2026-06-22 06:40:20','2026-06-22 06:55:04'),(7,'App\\Models\\User','019eee08-0bf4-7213-86f5-7b5ec5938755','access','bb1c6a9f468f21a44c4c1bf710df33d6c990150ef66a9833294a2314b27075b5','[\"*\"]','2026-06-22 07:00:53','2026-06-22 07:13:59','2026-06-22 06:58:59','2026-06-22 07:00:53'),(8,'App\\Models\\User','019eee08-0bf4-7213-86f5-7b5ec5938755','access','a1fa9c2659d19b74808dacb6119eca6deb597d2fd56348d514be3853ff0bd4bc','[\"*\"]','2026-06-22 07:39:16','2026-06-22 07:49:33','2026-06-22 07:34:33','2026-06-22 07:39:16'),(9,'App\\Models\\User','019eee08-0bf4-7213-86f5-7b5ec5938755','access','52038bd1843c313b90fb3761aa64b685195e3ecfc0a6726a6471757f9a7becd9','[\"*\"]','2026-06-22 07:59:19','2026-06-22 07:59:30','2026-06-22 07:44:30','2026-06-22 07:59:19'),(10,'App\\Models\\User','019eee08-0bf4-7213-86f5-7b5ec5938755','access','cba0fe902fc4f77364661f67936483e67f335560f6a5fee79d08992d969b5e26','[\"*\"]','2026-06-22 08:14:42','2026-06-22 08:16:10','2026-06-22 08:01:10','2026-06-22 08:14:42'),(11,'App\\Models\\User','019eee08-0bf4-7213-86f5-7b5ec5938755','access','f5c1d73871739abcc8dc9d25218d4c92c1616d6fd785c80762c17196f7e2fd54','[\"*\"]','2026-06-22 08:54:03','2026-06-22 08:54:17','2026-06-22 08:39:17','2026-06-22 08:54:03'),(12,'App\\Models\\User','019eee08-0bf4-7213-86f5-7b5ec5938755','access','bdfdaa566d4bb7fad80c393b41780d785095c806a4555c96eb22dabe39d9c788','[\"*\"]','2026-06-22 09:11:15','2026-06-22 09:12:05','2026-06-22 08:57:05','2026-06-22 09:11:15');
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
INSERT INTO `project_members` VALUES ('019eee06-aea5-7379-a9e1-2a644c49ba2e','019eee06-ae97-736d-acc4-a52252afd487','019eee05-3f83-72e1-bf62-96a9befa0c8e','admin','2026-06-22 06:31:15'),('019eee0f-4452-7068-be7f-dad110e4eb5a','019eee06-ae97-736d-acc4-a52252afd487','019eee08-0bf4-7213-86f5-7b5ec5938755','member','2026-06-22 06:40:38'),('019eee0f-4472-7324-a5df-ff90b985ab59','019eee06-ae97-736d-acc4-a52252afd487','019eee05-403c-73cb-80be-46e4e79e2577','member','2026-06-22 06:40:38'),('019eee0f-44c5-73d8-9419-2736a79b195a','019eee06-ae97-736d-acc4-a52252afd487','019eee05-40f4-7379-bc0c-547bf006d433','member','2026-06-22 06:40:38'),('019eee1b-c013-72e1-9564-561ec997fbf5','019eee06-ae97-736d-acc4-a52252afd487','019eee1b-5f37-732b-87c9-439e4b65c8de','member','2026-06-22 06:54:16'),('019eee1b-c068-7371-828e-ad3f1c808865','019eee06-ae97-736d-acc4-a52252afd487','019eee1a-facb-70fd-9bc7-067a7613ac6a','member','2026-06-22 06:54:16');
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
INSERT INTO `project_task_counters` VALUES ('019eee06-ae97-736d-acc4-a52252afd487',9);
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
INSERT INTO `projects` VALUES ('019eee06-ae97-736d-acc4-a52252afd487','CRM CAMCOM','crm-camcom',NULL,'019eee05-3f83-72e1-bf62-96a9befa0c8e',NULL,'2026-06-22 06:31:15',NULL,NULL,NULL,NULL);
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
INSERT INTO `refresh_tokens` VALUES ('019eee06-5576-7202-a8e1-802871a8121f','019eee05-3f83-72e1-bf62-96a9befa0c8e','bfc7b80ec6c307f06da661fe40987f88437e50a37958161d0c5c9d151b81fdaa','2026-06-29 06:30:53','2026-06-22 06:32:49','2026-06-22 06:30:53'),('019eee08-2a65-7382-8075-aedaeea91651','019eee08-0bf4-7213-86f5-7b5ec5938755','abfb96631d861f2c0cd62536f8000f9a6b720eae97ff4f73ca62894fa00164b0','2026-06-29 06:32:53','2026-06-22 08:57:19','2026-06-22 06:32:53'),('019eee0e-6c35-70da-84d6-b8b671867c17','019eee05-3f83-72e1-bf62-96a9befa0c8e','4e2f431a936a95fbc478df4fca4653fb352be7fdd4f974c68dc9f992c3ac2288','2026-06-29 06:39:43',NULL,'2026-06-22 06:39:43'),('019eee0e-ff07-7208-a7e5-e6661dcd29b5','019eee08-0bf4-7213-86f5-7b5ec5938755','4cd456a432e514b0aeb6d960b89e3f844a44606345b9b295c6b8b64823c4707b','2026-06-29 06:40:20','2026-06-22 06:55:20','2026-06-22 06:40:20'),('019eee1c-b904-7360-8351-4afd059ef396','019eee08-0bf4-7213-86f5-7b5ec5938755','f69dde08e06227cd0b846c0eda2783ae712c9ce91df9b53957c63231b23c9429','2026-06-29 06:55:20','2026-06-22 06:55:54','2026-06-22 06:55:20'),('019eee1d-493f-708b-aff3-8ba68ddc1154','019eee1b-5f37-732b-87c9-439e4b65c8de','d9057e3c75e6fd2bd9fd6c08158075b6952f44fb5b6095e13ab3b6905b21cdd7','2026-06-29 06:55:57','2026-06-22 06:58:56','2026-06-22 06:55:57'),('019eee20-12e9-70ac-9b40-770e8b046337','019eee08-0bf4-7213-86f5-7b5ec5938755','f66b6f4d647bebd68d45a4017795e6b698ebb57317771b59849c2912e82d1f16','2026-06-29 06:58:59','2026-06-22 08:57:21','2026-06-22 06:58:59'),('019eee40-a1ae-72c0-a229-9b10d359c769','019eee08-0bf4-7213-86f5-7b5ec5938755','316c421935fcd128dca8e4cb587ab1660752b4cfab8c775ae33769089a934ae7','2026-06-29 07:34:33','2026-06-22 08:57:21','2026-06-22 07:34:33'),('019eee49-be27-72fc-846f-63b13ff23aab','019eee08-0bf4-7213-86f5-7b5ec5938755','cad161b48f9ac0d412c69e480dbc6d1b9d0a2791b2c59bed54a4c51f9be41e82','2026-06-29 07:44:30','2026-06-22 08:57:21','2026-06-22 07:44:30'),('019eee59-00db-70f7-bda6-68e1dbcea597','019eee08-0bf4-7213-86f5-7b5ec5938755','2d2367555f7a871ab1101ff483e6cf29774876958fa87ed206a64dc15aab9969','2026-06-29 08:01:10','2026-06-22 08:57:21','2026-06-22 08:01:10'),('019eee7b-e4c3-731d-9946-69fcd3b5c6b2','019eee08-0bf4-7213-86f5-7b5ec5938755','1769bfa1d21383ade195013192ea050d4361d7cfee294548f4a0f413e4559d1f','2026-06-29 08:39:17','2026-06-22 08:57:21','2026-06-22 08:39:17'),('019eee8c-3134-71c3-8b9e-1f1bffa50fc1','019eee08-0bf4-7213-86f5-7b5ec5938755','131e7cdae68f100779c03a417ce8a3a6ca882245dc3efab2e0cdd9b5afd9eba0','2026-06-29 08:57:05','2026-06-22 08:57:21','2026-06-22 08:57:05');
/*!40000 ALTER TABLE `refresh_tokens` ENABLE KEYS */;
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
INSERT INTO `roles` VALUES ('019eee05-3e82-704d-8c44-6b0fb718439c','owner','Owner',NULL,1,'[\"manage_users\", \"manage_roles\", \"create_project\", \"edit_project\", \"delete_project\", \"create_sprint\", \"assign_tasks\", \"create_task\", \"update_own_task\", \"approve_task\", \"view_reports\", \"billing_access\", \"invite_client\", \"view_pages\", \"view_all_projects\"]',0,'2026-06-22 06:29:41'),('019eee05-3e90-71b7-a0f1-e7f76299f503','admin','Admin',NULL,1,'[\"manage_users\", \"manage_roles\", \"create_project\", \"edit_project\", \"delete_project\", \"create_sprint\", \"assign_tasks\", \"create_task\", \"update_own_task\", \"approve_task\", \"view_reports\", \"invite_client\", \"view_pages\"]',1,'2026-06-22 06:29:41'),('019eee05-3e9c-701c-b577-5e91ff4c9ca6','pm','PM',NULL,1,'[\"create_project\", \"edit_project\", \"create_sprint\", \"assign_tasks\", \"create_task\", \"update_own_task\", \"approve_task\", \"view_reports\", \"invite_client\", \"view_pages\"]',2,'2026-06-22 06:29:41'),('019eee05-3ea5-7310-b940-05a176ef9758','team_lead','Team Lead',NULL,1,'[\"edit_project\", \"create_sprint\", \"assign_tasks\", \"create_task\", \"update_own_task\", \"approve_task\", \"view_reports\", \"view_pages\"]',3,'2026-06-22 06:29:41'),('019eee05-3eb0-7299-a578-75299b9761ac','member','Member',NULL,1,'[\"create_task\", \"update_own_task\", \"view_reports\", \"view_pages\"]',4,'2026-06-22 06:29:41'),('019eee05-3eb6-7168-88de-de50d7506f30','client','Client',NULL,1,'[\"view_reports\", \"view_pages\"]',5,'2026-06-22 06:29:41');
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
  `reporter_id` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `due_date` date DEFAULT NULL,
  `estimated_hours` decimal(6,2) DEFAULT NULL,
  `logged_hours` decimal(6,2) NOT NULL DEFAULT '0.00',
  `story_points` int DEFAULT NULL,
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
  FULLTEXT KEY `tasks_title_description_fulltext` (`title`,`description`),
  CONSTRAINT `tasks_assignee_id_foreign` FOREIGN KEY (`assignee_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tasks_column_id_foreign` FOREIGN KEY (`column_id`) REFERENCES `columns` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tasks_parent_task_id_foreign` FOREIGN KEY (`parent_task_id`) REFERENCES `tasks` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tasks_project_id_foreign` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tasks_reporter_id_foreign` FOREIGN KEY (`reporter_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tasks_sprint_id_foreign` FOREIGN KEY (`sprint_id`) REFERENCES `sprints` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tasks`
--

LOCK TABLES `tasks` WRITE;
/*!40000 ALTER TABLE `tasks` DISABLE KEYS */;
INSERT INTO `tasks` VALUES ('019eee18-6a3a-736f-a31a-12a1be25db48','019eee06-ae97-736d-acc4-a52252afd487','019eee06-aea2-7152-b0d9-f3ed6d060b9e',NULL,'Update UI/UX màn lead',NULL,'task','medium','in_review','019eee08-0bf4-7213-86f5-7b5ec5938755','019eee08-0bf4-7213-86f5-7b5ec5938755',NULL,NULL,16.00,NULL,1,NULL,1,NULL,NULL,'2026-06-22 06:50:38','2026-06-22 08:12:16',NULL),('019eee19-0b4b-70e1-92b9-dac37c9b62a0','019eee06-ae97-736d-acc4-a52252afd487','019eee06-ae9e-70b0-a22c-8d2b0643b7e6',NULL,'Webhook security check',NULL,'task','medium','todo','019eee1a-facb-70fd-9bc7-067a7613ac6a','019eee08-0bf4-7213-86f5-7b5ec5938755',NULL,NULL,0.00,NULL,1,NULL,2,NULL,NULL,'2026-06-22 06:51:19','2026-06-22 06:54:34',NULL),('019eee19-2db6-7053-a2fe-112493694042','019eee06-ae97-736d-acc4-a52252afd487','019eee06-aea0-7370-8e22-a5c9e9010ec0',NULL,'Implement Candidates Page (Leads)',NULL,'task','medium','in_progress','019eee1b-5f37-732b-87c9-439e4b65c8de','019eee08-0bf4-7213-86f5-7b5ec5938755',NULL,NULL,0.00,NULL,2,NULL,3,NULL,NULL,'2026-06-22 06:51:28','2026-06-22 06:56:09',NULL),('019eee19-4481-7228-9494-aeccc27ce9b3','019eee06-ae97-736d-acc4-a52252afd487','019eee06-aea0-7370-8e22-a5c9e9010ec0',NULL,'Send a message Lead',NULL,'task','medium','in_progress','019eee05-40f4-7379-bc0c-547bf006d433','019eee08-0bf4-7213-86f5-7b5ec5938755',NULL,NULL,0.00,NULL,1,NULL,4,NULL,NULL,'2026-06-22 06:51:33','2026-06-22 06:54:52',NULL),('019eee19-5965-7391-979c-9fa938981bee','019eee06-ae97-736d-acc4-a52252afd487','019eee06-aea0-7370-8e22-a5c9e9010ec0',NULL,'API update status màn Lead',NULL,'task','medium','in_progress','019eee05-403c-73cb-80be-46e4e79e2577','019eee08-0bf4-7213-86f5-7b5ec5938755',NULL,NULL,0.00,NULL,2,NULL,5,NULL,NULL,'2026-06-22 06:51:39','2026-06-22 06:57:37',NULL),('019eee19-742b-7188-92e4-57dde8ab0771','019eee06-ae97-736d-acc4-a52252afd487','019eee06-aea2-7152-b0d9-f3ed6d060b9e',NULL,'API update status màn Job applications',NULL,'task','medium','in_review','019eee05-3f83-72e1-bf62-96a9befa0c8e','019eee08-0bf4-7213-86f5-7b5ec5938755',NULL,NULL,0.00,NULL,1,NULL,6,NULL,NULL,'2026-06-22 06:51:46','2026-06-22 06:54:54',NULL),('019eee21-0967-71c0-ac81-ae8f08a8a3c4','019eee06-ae97-736d-acc4-a52252afd487','019eee06-ae9e-70b0-a22c-8d2b0643b7e6',NULL,'Cập nhật UI/UX màn Job Applications để hiển thị trạng thái mới',NULL,'task','medium','todo',NULL,'019eee08-0bf4-7213-86f5-7b5ec5938755',NULL,NULL,0.00,NULL,1,'019eee18-6a3a-736f-a31a-12a1be25db48',7,NULL,NULL,'2026-06-22 07:00:03','2026-06-22 07:00:28',NULL),('019eee40-f8cb-70bc-a9c0-4405d08b7622','019eee06-ae97-736d-acc4-a52252afd487','019eee06-aea0-7370-8e22-a5c9e9010ec0',NULL,'sub task 1',NULL,'task','medium','in_progress',NULL,'019eee08-0bf4-7213-86f5-7b5ec5938755',NULL,NULL,0.00,NULL,4,'019eee18-6a3a-736f-a31a-12a1be25db48',8,NULL,NULL,'2026-06-22 07:34:55','2026-06-22 07:34:55',NULL),('019eee4a-8062-709c-9be3-34516a6b611f','019eee06-ae97-736d-acc4-a52252afd487','019eee06-aea0-7370-8e22-a5c9e9010ec0',NULL,'Hiển thị danh sách job đang apply khi chuyển sang Start Work',NULL,'task','medium','in_progress',NULL,'019eee08-0bf4-7213-86f5-7b5ec5938755',NULL,NULL,0.00,NULL,5,'019eee18-6a3a-736f-a31a-12a1be25db48',9,NULL,NULL,'2026-06-22 07:45:20','2026-06-22 07:45:20',NULL);
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
  `role` enum('admin','manager','member','viewer') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'member',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `role_id` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `language` varchar(5) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'en',
  `appearance` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'light',
  `timezone` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Asia/Ho_Chi_Minh',
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
INSERT INTO `users` VALUES ('019eee05-3f83-72e1-bf62-96a9befa0c8e','admin@taskboard.dev','$2y$12$iciW0GpGukin4Vsi2UQGz..eZym2Yn/b8vUEkniPGcL4ZfSXAq9Ey','Admin',NULL,'admin',1,'019eee05-3e90-71b7-a0f1-e7f76299f503','en','midnight','Asia/Ho_Chi_Minh','2026-06-22 07:33:26',0,NULL,'2026-06-22 06:29:41'),('019eee05-403c-73cb-80be-46e4e79e2577','manager@taskboard.dev','$2y$12$p6ASxB1Ncp.mLw2K5I/mzu98qyjseNzIgkCIeZqngj3nmC5aFtUG.','Manager',NULL,'manager',1,'019eee05-3e9c-701c-b577-5e91ff4c9ca6','en','midnight','Asia/Ho_Chi_Minh','2026-06-22 07:33:27',0,NULL,'2026-06-22 06:29:42'),('019eee05-40f4-7379-bc0c-547bf006d433','member@taskboard.dev','$2y$12$0dCKwbC31vCWALWXRekkCObjhOpnP3UezbI/zQL84I6muAX0Bc3Li','Member',NULL,'member',1,'019eee05-3eb0-7299-a578-75299b9761ac','en','midnight','Asia/Ho_Chi_Minh','2026-06-22 07:33:27',0,NULL,'2026-06-22 06:29:42'),('019eee08-0bf4-7213-86f5-7b5ec5938755','b1dung@sougo-career-vietnam.com','$2y$12$e7UfhvcizTnvI.9AgztQ0O51CO6VAuXuWPoynwoCjRsYXGP48/Lce','Bùi Mạnh Dũng','/uploads/avatars/863e1bbb-0a71-44bf-813b-b0f58edd9bf2.jpg','member',1,'019eee05-3e82-704d-8c44-6b0fb718439c','en','light','Asia/Ho_Chi_Minh','2026-06-22 06:32:45',0,NULL,'2026-06-22 06:32:45'),('019eee1a-facb-70fd-9bc7-067a7613ac6a','t1quan@sougo-career-vietnam.com','$2y$12$HoZr9jMpHFgdqyMmyQyixOeuyqer7H2lGfiHHdr91wu99pJFVE/7.','Trần Đức Quân',NULL,'member',1,'019eee05-3eb0-7299-a578-75299b9761ac','en','light','Asia/Ho_Chi_Minh','2026-06-22 06:53:26',0,NULL,'2026-06-22 06:53:26'),('019eee1b-5f37-732b-87c9-439e4b65c8de','l1linh@sougo-career-vietnam.com','$2y$12$GrXn425LMeypWo4KyZKeIOqlXacBxEgzio3dActwoVjMuzkYbg5He','Lê Duy Linh',NULL,'member',1,'019eee05-3eb0-7299-a578-75299b9761ac','en','light','Asia/Ho_Chi_Minh','2026-06-22 06:53:51',0,NULL,'2026-06-22 06:53:51');
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
INSERT INTO `working_hours` VALUES ('019eee1c-b954-7096-8233-02fd15aefa29','019eee18-6a3a-736f-a31a-12a1be25db48','019eee08-0bf4-7213-86f5-7b5ec5938755',16.00,'2026-06-22',NULL,'2026-06-22 06:55:20');
/*!40000 ALTER TABLE `working_hours` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping events for database 'taskboard'
--

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

-- Dump completed on 2026-06-22  9:36:01
