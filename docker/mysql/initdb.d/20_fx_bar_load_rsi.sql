CREATE TABLE `fx_bar_load_rsi` (
  `symbol` varchar(6) NOT NULL COMMENT '通貨ペア',
  `rsi_range` int(11) NOT NULL COMMENT 'RSI期間',
  `bar_date_time` datetime NOT NULL COMMENT '日時',
  `rsi_value` decimal(10,5) NOT NULL COMMENT 'RSI値',
  `rsi_ma` decimal(10,5) NOT NULL COMMENT 'SMA値',
  PRIMARY KEY (`symbol`,`rsi_range`,`bar_date_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='足データLoad_RSI_情報';