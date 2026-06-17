CREATE TABLE `fx_bar_4h_sma` (
  `symbol` varchar(6) NOT NULL COMMENT '通貨ペア',
  `bar_date_time` datetime NOT NULL COMMENT '日時',
  `sma_range` int(11) NOT NULL COMMENT 'SMA期間',
  `sma_price` decimal(10,5) NOT NULL COMMENT 'SMA値',
  `sma_cross` bit(1) NOT NULL DEFAULT b'0' COMMENT 'sma交差',
  PRIMARY KEY (`symbol`,`bar_date_time`,`sma_range`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='SMA4H情報';
