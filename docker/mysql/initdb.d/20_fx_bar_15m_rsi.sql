CREATE TABLE `fx_bar_15m_rsi` (
  `symbol` varchar(6) NOT NULL COMMENT '通貨ペア',
  `bar_date_time` datetime NOT NULL COMMENT '日時',
  `rsi_range` int(11) NOT NULL COMMENT 'RSI期間',
  `rsi_value` decimal(10,5) NOT NULL COMMENT 'RSI値',
  `rsi_ma` decimal(10,5) NOT NULL  COMMENT 'RSI-MA値',
  PRIMARY KEY (`symbol`,`bar_date_time`,`rsi_range`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='RSI15m情報';
