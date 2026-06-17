CREATE TABLE `fx_bar_load_sma` (
  `symbol` varchar(6) NOT NULL COMMENT '通貨ペア',
  `sma_range` int(11) NOT NULL COMMENT 'SMA期間',
  `bar_date_time` datetime NOT NULL COMMENT '日時',
  `sma_price` decimal(10,5) NOT NULL COMMENT 'SMA値',
  `sma_cross` bit(1) NOT NULL DEFAULT b'0' COMMENT 'sma交差',
  PRIMARY KEY (`symbol`,`sma_range`,`bar_date_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='足データLoad_sma_情報';