CREATE TABLE `fx_economic_indicator` (
  `code` varchar(32) NOT NULL COMMENT '経済指標コード',
  `country_code` char(2) NOT NULL COMMENT '国コード',
  `importance` char(1) NOT NULL COMMENT '重要度',
  `name` varchar(64) NOT NULL COMMENT '経済指標名称',
  `description` varchar(255) DEFAULT NULL COMMENT '説明',
  `unit_of_value` varchar(8) DEFAULT NULL COMMENT '指標値の単位',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '削除フラグ',
  `created_at` datetime NOT NULL DEFAULT current_timestamp() COMMENT 'レコード作成日時',
  `created_by` varchar(128) NOT NULL COMMENT 'レコード作成者情報',
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'レコード更新日時',
  `updated_by` varchar(128) NOT NULL COMMENT 'レコード更新者情報',
  PRIMARY KEY (`code`, `country_code`),
  KEY `fx_economic_indicator_idx1` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='経済指標情報';
