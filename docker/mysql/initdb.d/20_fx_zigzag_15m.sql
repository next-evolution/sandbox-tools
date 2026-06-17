CREATE TABLE `fx_zigzag_15m` (
  `symbol` varchar(6) NOT NULL COMMENT '通貨ペア',
  `depth` int NOT NULL COMMENT 'ZigZag Depth',
  `bar_date_time` datetime NOT NULL COMMENT '日時',

  `resistance` decimal(10,5) NOT NULL COMMENT '戻り高値',
  `resistance_fractal` decimal(10,5) NOT NULL COMMENT '戻り高値(Fractal)',
  `support` decimal(10,5) NOT NULL COMMENT '押し安値',
  `support_fractal` decimal(10,5) NOT NULL COMMENT '押し安値(Fractal)',
  `high` decimal(10,5) NOT NULL COMMENT '高値',
  `low` decimal(10,5) NOT NULL COMMENT '安値',
  `backstep_high` decimal(10,5) NOT NULL COMMENT 'backstep高値',
  `backstep_low` decimal(10,5) NOT NULL COMMENT 'backstep安値',

  `fractal_high` decimal(10,5) NOT NULL COMMENT 'fractal高値',
  `fractal_low` decimal(10,5) NOT NULL COMMENT 'fractal安値',

  `resistance_bar_date_time` datetime NOT NULL COMMENT '日時',
  `resistance_fractal_bar_date_time` datetime NOT NULL COMMENT '日時',
  `support_bar_date_time` datetime NOT NULL COMMENT '日時',
  `support_fractal_bar_date_time` datetime NOT NULL COMMENT '日時',
  `high_bar_date_time` datetime NOT NULL COMMENT '日時',
  `low_bar_date_time` datetime NOT NULL COMMENT '日時',
  `backstep_high_bar_date_time` datetime NOT NULL COMMENT '日時',
  `backstep_low_bar_date_time` datetime NOT NULL COMMENT '日時',

  `backstep_up` tinyint NOT NULL COMMENT 'backstep_up',
  `backstep_down` tinyint NOT NULL COMMENT 'backstep_down',
  `wave` tinyint(4) NOT NULL COMMENT '波数',
  `up_trend` bit(1) NOT NULL DEFAULT b'0' COMMENT 'TRUE:上昇トレンド、FALSE:下降トレンド',
  `break_resistance` bit(1) NOT NULL DEFAULT b'0' COMMENT 'TRUE:上抜け',
  `break_support` bit(1) NOT NULL DEFAULT b'0' COMMENT 'TRUE:下抜け',
  PRIMARY KEY (`symbol`,`depth`,`bar_date_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='15分足ZigZag情報';
