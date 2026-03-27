-- ====================================================================
-- GREENPLUM 6: ДЕМОНСТРАЦИЯ РАЗЛИЧИЙ МЕЖДУ DISTRIBUTION И PARTITION
-- ====================================================================

-- Очистка
DROP TABLE IF EXISTS public.sales_random CASCADE;
DROP TABLE IF EXISTS public.sales_by_region CASCADE;
DROP TABLE IF EXISTS public.sales_by_id CASCADE;
DROP TABLE IF EXISTS public.sales_by_date CASCADE;

-- ====================================================================
-- СЦЕНАРИЙ 1: DISTRIBUTED RANDOMLY
-- ====================================================================
CREATE TABLE public.sales_random (
    id INT,
    region VARCHAR(10),
    sale_date DATE,
    amount DECIMAL(10,2)
)
DISTRIBUTED RANDOMLY
PARTITION BY RANGE (sale_date)
(
    PARTITION q1_2024 START ('2024-01-01') END ('2024-04-01'),
    PARTITION q2_2024 START ('2024-04-01') END ('2024-07-01')
);

-- Вставка тестовых данных (20 строк)
INSERT INTO public.sales_random VALUES
(1, 'EU', '2024-01-05', 100.00),
(2, 'NA', '2024-01-10', 150.00),
(3, 'EU', '2024-01-15', 200.00),
(4, 'ASIA', '2024-01-20', 175.00),
(5, 'SA', '2024-01-25', 225.00),
(6, 'NA', '2024-02-03', 300.00),
(7, 'EU', '2024-02-12', 250.00),
(8, 'ASIA', '2024-02-18', 125.00),
(9, 'SA', '2024-03-05', 180.00),
(10, 'NA', '2024-03-22', 210.00),
(11, 'EU', '2024-04-02', 190.00),
(12, 'ASIA', '2024-04-08', 160.00),
(13, 'SA', '2024-04-15', 240.00),
(14, 'NA', '2024-04-28', 220.00),
(15, 'EU', '2024-05-05', 195.00),
(16, 'ASIA', '2024-05-12', 270.00),
(17, 'SA', '2024-05-20', 185.00),
(18, 'NA', '2024-06-01', 230.00),
(19, 'EU', '2024-06-15', 205.00),
(20, 'ASIA', '2024-06-28', 215.00);

-- Показать распределение данных по сегментам и партициям
SELECT 
    gp_segment_id AS segment,
    tableoid::regclass AS partition_name,
    id,
    region,
    sale_date
FROM public.sales_random
ORDER BY partition_name, segment, id;

-- Агрегация: количество строк на каждом сегменте в каждой партиции
SELECT 
    tableoid::regclass AS partition_name,
    gp_segment_id AS segment,
    COUNT(*) as row_count
FROM public.sales_random
GROUP BY partition_name, segment
ORDER BY partition_name, segment;


-- ====================================================================
-- СЦЕНАРИЙ 2: DISTRIBUTED BY (region)
-- ====================================================================
CREATE TABLE public.sales_by_region (
    id INT,
    region VARCHAR(10),
    sale_date DATE,
    amount DECIMAL(10,2)
)
DISTRIBUTED BY (region)
PARTITION BY RANGE (sale_date)
(
    PARTITION q1_2024 START ('2024-01-01') END ('2024-04-01'),
    PARTITION q2_2024 START ('2024-04-01') END ('2024-07-01')
);

-- Вставка тех же данных
INSERT INTO public.sales_by_region VALUES
(1, 'EU', '2024-01-05', 100.00),
(2, 'NA', '2024-01-10', 150.00),
(3, 'EU', '2024-01-15', 200.00),
(4, 'ASIA', '2024-01-20', 175.00),
(5, 'SA', '2024-01-25', 225.00),
(6, 'NA', '2024-02-03', 300.00),
(7, 'EU', '2024-02-12', 250.00),
(8, 'ASIA', '2024-02-18', 125.00),
(9, 'SA', '2024-03-05', 180.00),
(10, 'NA', '2024-03-22', 210.00),
(11, 'EU', '2024-04-02', 190.00),
(12, 'ASIA', '2024-04-08', 160.00),
(13, 'SA', '2024-04-15', 240.00),
(14, 'NA', '2024-04-28', 220.00),
(15, 'EU', '2024-05-05', 195.00),
(16, 'ASIA', '2024-05-12', 270.00),
(17, 'SA', '2024-05-20', 185.00),
(18, 'NA', '2024-06-01', 230.00),
(19, 'EU', '2024-06-15', 205.00),
(20, 'ASIA', '2024-06-28', 215.00);

-- Показать распределение данных по сегментам и партициям
SELECT 
    gp_segment_id AS segment,
    tableoid::regclass AS partition_name,
    id,
    region,
    sale_date
FROM public.sales_by_region
ORDER BY region, partition_name, segment;

-- Агрегация: количество строк на каждом сегменте в каждой партиции
SELECT 
    tableoid::regclass AS partition_name,
    gp_segment_id AS segment,
    COUNT(*) as row_count
FROM public.sales_by_region
GROUP BY partition_name, segment
ORDER BY partition_name, segment;


-- ====================================================================
-- СЦЕНАРИЙ 3: DISTRIBUTED BY (id)
-- ====================================================================
CREATE TABLE public.sales_by_id (
    id INT,
    region VARCHAR(10),
    sale_date DATE,
    amount DECIMAL(10,2)
)
DISTRIBUTED BY (id)
PARTITION BY RANGE (sale_date)
(
    PARTITION q1_2024 START ('2024-01-01') END ('2024-04-01'),
    PARTITION q2_2024 START ('2024-04-01') END ('2024-07-01')
);

-- Вставка тех же данных
INSERT INTO public.sales_by_id VALUES
(1, 'EU', '2024-01-05', 100.00),
(2, 'NA', '2024-01-10', 150.00),
(3, 'EU', '2024-01-15', 200.00),
(4, 'ASIA', '2024-01-20', 175.00),
(5, 'SA', '2024-01-25', 225.00),
(6, 'NA', '2024-02-03', 300.00),
(7, 'EU', '2024-02-12', 250.00),
(8, 'ASIA', '2024-02-18', 125.00),
(9, 'SA', '2024-03-05', 180.00),
(10, 'NA', '2024-03-22', 210.00),
(11, 'EU', '2024-04-02', 190.00),
(12, 'ASIA', '2024-04-08', 160.00),
(13, 'SA', '2024-04-15', 240.00),
(14, 'NA', '2024-04-28', 220.00),
(15, 'EU', '2024-05-05', 195.00),
(16, 'ASIA', '2024-05-12', 270.00),
(17, 'SA', '2024-05-20', 185.00),
(18, 'NA', '2024-06-01', 230.00),
(19, 'EU', '2024-06-15', 205.00),
(20, 'ASIA', '2024-06-28', 215.00);

-- Показать распределение данных по сегментам и партициям
SELECT 
    gp_segment_id AS segment,
    tableoid::regclass AS partition_name,
    id,
    region,
    sale_date
FROM public.sales_by_id
ORDER BY partition_name, segment, id;

-- Агрегация: количество строк на каждом сегменте в каждой партиции
SELECT 
    tableoid::regclass AS partition_name,
    gp_segment_id AS segment,
    COUNT(*) as row_count
FROM public.sales_by_id
GROUP BY partition_name, segment
ORDER BY partition_name, segment;


-- ====================================================================
-- СЦЕНАРИЙ 4: DISTRIBUTED BY (quarter) + PARTITION BY (quarter) - АНТИПАТТЕРН!
-- ====================================================================
-- ⚠️ ПРОБЛЕМА: Ключ распределения совпадает с ключом партиционирования
-- Все строки одной партиции попадут на ОДИН сегмент → data skew!
-- ====================================================================
CREATE TABLE public.sales_by_date (
    id INT,
    region VARCHAR(10),
    quarter VARCHAR(2),
    sale_date DATE,
    amount DECIMAL(10,2)
)
DISTRIBUTED BY (quarter)
PARTITION BY LIST (quarter)
(
    PARTITION q1_2024 VALUES ('Q1'),
    PARTITION q2_2024 VALUES ('Q2')
);

-- Вставка тех же данных + колонка quarter
INSERT INTO public.sales_by_date VALUES
(1, 'EU', 'Q1', '2024-01-05', 100.00),
(2, 'NA', 'Q1', '2024-01-10', 150.00),
(3, 'EU', 'Q1', '2024-01-15', 200.00),
(4, 'ASIA', 'Q1', '2024-01-20', 175.00),
(5, 'SA', 'Q1', '2024-01-25', 225.00),
(6, 'NA', 'Q1', '2024-02-03', 300.00),
(7, 'EU', 'Q1', '2024-02-12', 250.00),
(8, 'ASIA', 'Q1', '2024-02-18', 125.00),
(9, 'SA', 'Q1', '2024-03-05', 180.00),
(10, 'NA', 'Q1', '2024-03-22', 210.00),
(11, 'EU', 'Q2', '2024-04-02', 190.00),
(12, 'ASIA', 'Q2', '2024-04-08', 160.00),
(13, 'SA', 'Q2', '2024-04-15', 240.00),
(14, 'NA', 'Q2', '2024-04-28', 220.00),
(15, 'EU', 'Q2', '2024-05-05', 195.00),
(16, 'ASIA', 'Q2', '2024-05-12', 270.00),
(17, 'SA', 'Q2', '2024-05-20', 185.00),
(18, 'NA', 'Q2', '2024-06-01', 230.00),
(19, 'EU', 'Q2', '2024-06-15', 205.00),
(20, 'ASIA', 'Q2', '2024-06-28', 215.00);

-- Показать распределение данных по сегментам и партициям
SELECT 
    gp_segment_id AS segment,
    tableoid::regclass AS partition_name,
    id,
    region,
    quarter,
    sale_date
FROM public.sales_by_date
ORDER BY partition_name, segment, id;

-- Агрегация: количество строк на каждом сегменте в каждой партиции
-- ⚠️ ЗДЕСЬ ВИДНА ПРОБЛЕМА: Все строки Q1 на одном сегменте, все Q2 на другом!
SELECT 
    tableoid::regclass AS partition_name,
    gp_segment_id AS segment,
    COUNT(*) as row_count
FROM public.sales_by_date
GROUP BY partition_name, segment
ORDER BY partition_name, segment;


-- ====================================================================
-- КЛЮЧЕВЫЕ НАБЛЮДЕНИЯ ДЛЯ ДЕМОНСТРАЦИИ:
-- ====================================================================
-- 1. PARTITION (по sale_date): Логическое разделение данных
--    - Строка с id=1, date='2024-01-05' → ВСЕГДА в партиции q1_2024
--    - Строка с id=11, date='2024-04-02' → ВСЕГДА в партиции q2_2024
--    - Партиционирование НЕ ЗАВИСИТ от того, на каком сегменте хранится строка
--
-- 2. DISTRIBUTION: Физическое размещение данных по сегментам
--    - RANDOM: Одна и та же строка попадает на разные сегменты при каждой вставке
--    - BY region: Строки с одинаковым регионом → на одном сегменте (EU вместе, NA вместе)
--    - BY id: Строки распределяются по хешу от значения id
--    - BY sale_date: Строки с одинаковой датой → на одном сегменте
--
-- 3. В НОРМЕ: Партиции "размазаны" по сегментам
--    - Строка из партиции 'q1_2024' может быть на сегменте 0 или 1
--    - Ключ распределения определяет, на КАКОМ сегменте внутри партиции лежит строка
--    - Partition pruning работает независимо от стратегии распределения
--    - Distribution влияет на параллелизм запросов и колокацию данных
--
-- 4. ⚠️ АНТИПАТТЕРН: Совпадение ключей (DISTRIBUTED BY sale_date + PARTITION BY sale_date)
--    - ВСЕ строки одной партиции попадают на ОДИН сегмент
--    - Нет параллелизма внутри партиции
--    - Data skew: неравномерная нагрузка на сегменты
--    - Потеря преимуществ MPP архитектуры, запрос работает со скоростью самого медленного сегмента
-- ====================================================================
