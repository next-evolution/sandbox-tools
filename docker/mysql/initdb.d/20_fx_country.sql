CREATE TABLE `fx_country` (
  `code` char(2) NOT NULL COMMENT '国コード',
  `name` varchar(64) NOT NULL COMMENT '国名称',
  `currency_code` char(3) NOT NULL COMMENT '基軸通貨コード',
  `name_en` varchar(64) NOT NULL COMMENT '国名称(ローマ字)',
  `name_short` varchar(8) NOT NULL COMMENT '国名称(略称)',
  `sort_order` smallint(6) NOT NULL COMMENT 'ソート順',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '削除フラグ',
  `created_at` datetime NOT NULL DEFAULT current_timestamp() COMMENT 'レコード作成日時',
  `created_by` varchar(128) NOT NULL COMMENT 'レコード作成者情報',
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'レコード更新日時',
  `updated_by` varchar(128) NOT NULL COMMENT 'レコード更新者情報',
  PRIMARY KEY (`code`),
  KEY (`currency_code`),
  KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='国情報';
