CREATE TABLE `fx_zigzag_wave_1d` (
  `symbol` varchar(6) NOT NULL COMMENT '通貨ペア',
  `depth` int NOT NULL COMMENT 'ZigZag Depth',
  `wave_start` datetime NOT NULL COMMENT 'WAVE開始日時',
  `wave_end` datetime NOT NULL COMMENT 'WAVE終了日時',
  `wave` tinyint(4) NOT NULL COMMENT '波数',
  `resistance` decimal(10,5) NOT NULL COMMENT '戻り高値(確定値)',
  `support` decimal(10,5) NOT NULL COMMENT '押し安値(確定値)',
  `previous_wave_start` datetime NOT NULL COMMENT 'WAVE開始日時',
  `previous_wave` tinyint(4) NOT NULL DEFAULT 0 COMMENT '波数',
  `wave_memo` varchar(64) NULL COMMENT 'memo',
  PRIMARY KEY (`symbol`,`depth`,`wave_start`),
  KEY I1 (`symbol`,`depth`,`wave_start`,`wave_end`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='日足ZigZagWave情報';