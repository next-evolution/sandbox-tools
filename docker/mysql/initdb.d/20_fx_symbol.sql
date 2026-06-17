CREATE TABLE `fx_symbol` (
  `symbol` varchar(16) NOT NULL COMMENT '銘柄コード',
  `symbol_type` varchar(8) NOT NULL COMMENT '銘柄種別(FX|INDEX|CRYPTO|STOCK)',
  `name` varchar(64) NOT NULL COMMENT '銘柄名称',
  `valid_scale` smallint(6) NOT NULL COMMENT '有効桁数',
  `target_volatility` decimal(10,5) NOT NULL COMMENT '変動値',
  `sort_order` smallint(6) NOT NULL COMMENT 'ソート順',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '削除フラグ',
  `created_at` datetime NOT NULL DEFAULT current_timestamp() COMMENT 'レコード作成日時',
  `created_by` varchar(128) NOT NULL COMMENT 'レコード作成者情報',
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'レコード更新日時',
  `updated_by` varchar(128) NOT NULL COMMENT 'レコード更新者情報',
  PRIMARY KEY (`symbol`),
  KEY (`symbol_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='銘柄コード情報';
