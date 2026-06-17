CREATE TABLE `fx_bar_load` (
  `symbol` varchar(6) NOT NULL COMMENT '通貨ペア',
  `bar_date_time` datetime NOT NULL COMMENT '日時',
  `open_price` decimal(10,5) NOT NULL COMMENT '始値',
  `high_price` decimal(10,5) NOT NULL COMMENT '高値',
  `low_price` decimal(10,5) NOT NULL COMMENT '安値',
  `close_price` decimal(10,5) NOT NULL COMMENT '終値',
  `volume` int(11) NOT NULL COMMENT '出来高',
  PRIMARY KEY (`symbol`,`bar_date_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='足データLoad情報';
