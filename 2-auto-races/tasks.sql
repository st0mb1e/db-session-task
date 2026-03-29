-- Задача 1
SELECT 
    c.name AS car_name,
    c.class AS car_class,
    AVG(r.position) AS average_position,
    COUNT(r.race) AS race_count
FROM Cars c
JOIN Results r ON c.name = r.car
GROUP BY c.name, c.class
HAVING AVG(r.position) = (
    SELECT MIN(avg_pos)
    FROM (
        SELECT 
            c2.name,
            c2.class,
            AVG(r2.position) AS avg_pos
        FROM Cars c2
        JOIN Results r2 ON c2.name = r2.car
        WHERE c2.class = c.class
        GROUP BY c2.name, c2.class
    ) sub
)
ORDER BY average_position;

-- Задача 2
SELECT 
    c.name AS car_name,
    c.class AS car_class,
    AVG(r.position) AS average_position,
    COUNT(*) AS race_count,
    cl.country AS car_country
FROM Cars c
JOIN Results r ON c.name = r.car
JOIN Classes cl ON c.class = cl.class
GROUP BY c.name, c.class, cl.country
ORDER BY average_position, car_name
LIMIT 1;

-- Задача 3
WITH ClassAvg AS (
    -- вычисляем среднюю позицию для каждого класса
    SELECT 
        c.class,
        AVG(r.position) AS class_avg_position
    FROM Cars c
    JOIN Results r ON c.name = r.car
    GROUP BY c.class
), MinClasses AS (
    -- выбираем классы с минимальной средней позицией
    SELECT class
    FROM ClassAvg
    WHERE class_avg_position = (SELECT MIN(class_avg_position) FROM ClassAvg)
), ClassRaceCount AS (
    -- считаем общее количество гонок для каждого класса
    SELECT c.class, COUNT(*) AS total_races
    FROM Cars c
    JOIN Results r ON c.name = r.car
    GROUP BY c.class
)
SELECT 
    c.name AS car_name,
    c.class AS car_class,
    AVG(r.position) AS average_position,
    COUNT(*) AS race_count,
    cl.country AS car_country,
    crc.total_races
FROM Cars c
JOIN Results r ON c.name = r.car
JOIN Classes cl ON c.class = cl.class
JOIN MinClasses mc ON c.class = mc.class            -- оставляем только автомобили из классов с минимальной средней позицией
JOIN ClassRaceCount crc ON c.class = crc.class     -- добавляем общее количество гонок по классу
GROUP BY c.name, c.class, cl.country, crc.total_races
ORDER BY average_position, car_name;

-- Задача 4
WITH CarStats AS (
    -- считаем среднюю позицию и количество гонок для каждого автомобиля
    SELECT 
        c.name,
        c.class,
        AVG(r.position) AS average_position,  -- средняя позиция конкретного автомобиля
        COUNT(*) AS race_count                -- количество гонок для автомобиля
    FROM Cars c
    JOIN Results r ON c.name = r.car
    GROUP BY c.name, c.class
),
ClassStats AS (
    -- считаем среднюю позицию и количество автомобилей в каждом классе
    -- учитываем только классы с минимум 2 автомобилями
    SELECT 
        c.class,
        AVG(r.position) AS class_avg,        -- средняя позиция по классу
        COUNT(*) AS car_count                 -- количество автомобилей в классе
    FROM Cars c
    JOIN Results r ON c.name = r.car
    GROUP BY c.class
    HAVING COUNT(*) >= 2                     -- фильтр по минимальному количеству автомобилей в классе
)
SELECT 
    cs.name AS car_name,
    cs.class AS car_class,
    cs.average_position,
    cs.race_count,
    cl.country AS car_country
FROM CarStats cs
JOIN ClassStats cls ON cs.class = cls.class
JOIN Classes cl ON cs.class = cl.class
WHERE cs.average_position < cls.class_avg   -- выбираем автомобили с лучшей средней позицией, чем средняя по классу
ORDER BY cs.class, cs.average_position;    -- сортировка по классу и по позиции

-- Задача 5
WITH CarStats AS (
    -- считаем среднюю позицию и количество гонок для каждого автомобиля
    SELECT 
        c.name,
        c.class,
        AVG(r.position) AS average_position,
        COUNT(*) AS race_count
    FROM Cars c
    JOIN Results r ON c.name = r.car
    GROUP BY c.name, c.class
),
ClassRaceCount AS (
    -- считаем общее количество гонок для каждого класса
    SELECT 
        c.class,
        COUNT(*) AS total_races
    FROM Cars c
    JOIN Results r ON c.name = r.car
    GROUP BY c.class
),
LowPositionCounts AS (
    -- считаем количество автомобилей с низкой средней позицией (>3.0) для каждого класса
    SELECT 
        cs.class,
        COUNT(*) AS low_position_count
    FROM CarStats cs
    WHERE cs.average_position > 3.0
    GROUP BY cs.class
)
SELECT 
    cs.name AS car_name,
    cs.class AS car_class,
    cs.average_position,
    cs.race_count,
    cl.country AS car_country,
    crc.total_races,
    lpc.low_position_count
FROM CarStats cs
JOIN LowPositionCounts lpc ON cs.class = lpc.class       -- оставляем только классы с автомобилями с низкой средней позицией
JOIN Classes cl ON cs.class = cl.class
JOIN ClassRaceCount crc ON cs.class = crc.class          -- добавляем общее количество гонок класса
WHERE cs.average_position > 3.0                          -- оставляем только автомобили с "низкой" средней позицией
ORDER BY lpc.low_position_count DESC;                   -- сортируем по количеству автомобилей с низкой позицией
