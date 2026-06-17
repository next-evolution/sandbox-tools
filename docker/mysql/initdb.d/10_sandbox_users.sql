CREATE TABLE `sandbox_user` (
  `id` int NOT NULL auto_increment COMMENT 'ID',
  `user_id` varchar(64) NOT NULL COMMENT 'ユーザID(cognito sub)',
  `email_address` varchar(128) NOT NULL COMMENT 'Emailアドレス',
  `nick_name` varchar(64) NOT NULL COMMENT 'ニックネーム',
  `approved` bit(1) NOT NULL DEFAULT b'0' COMMENT '承認フラグ',
  `approved_at` datetime DEFAULT NULL COMMENT '承認日時',
  `admin` bit(1) NOT NULL DEFAULT b'0' COMMENT '管理者フラグ',
  `blocked` bit(1) NOT NULL DEFAULT b'0' COMMENT 'Blockedフラグ',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '削除フラグ(auth0 blocked)',
  `created_at` datetime NOT NULL DEFAULT current_timestamp() COMMENT 'レコード作成日時',
  `created_by` varchar(128) NOT NULL COMMENT 'レコード作成者情報',
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'レコード更新日時',
  `updated_by` varchar(128) NOT NULL COMMENT 'レコード更新者情報',
  PRIMARY KEY (`id`),
  UNIQUE KEY (`user_id`),
  KEY (`user_id`,`email_address`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='アカウント情報';
