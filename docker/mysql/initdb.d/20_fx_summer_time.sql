CREATE TABLE `fx_summer_time` (
  `target_year` smallint(6) NOT NULL COMMENT '対象年',
  `apply_start` date NOT NULL COMMENT '適用開始日',
  `apply_end` date NOT NULL COMMENT '適用終了日',
  PRIMARY KEY (`target_year`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='夏時間情報';
