-- СУБД: MySQL
-- Задача 1
SELECT 
    c.name,
    c.email,
    c.phone,
    COUNT(b.ID_booking) AS total_bookings,           -- общее количество бронирований
    GROUP_CONCAT(DISTINCT h.name ORDER BY h.name SEPARATOR ', ') AS hotels,  -- уникальные отели клиента
    ROUND(AVG(DATEDIFF(b.check_out_date, b.check_in_date)), 4) AS avg_stay  -- средняя длительность пребывания
FROM Customer c
JOIN Booking b ON c.ID_customer = b.ID_customer
JOIN Room r ON b.ID_room = r.ID_room
JOIN Hotel h ON r.ID_hotel = h.ID_hotel
GROUP BY c.ID_customer, c.name, c.email, c.phone
HAVING COUNT(DISTINCT h.ID_hotel) > 1               -- бронировал в более чем одном отеле
   AND COUNT(b.ID_booking) > 2                     -- более двух бронирований
ORDER BY total_bookings DESC;

-- Задача 2
SELECT
    c.ID_customer,
    c.name,
    COUNT(b.ID_booking) AS total_bookings,       -- общее количество бронирований
    SUM(r.price) AS total_spent,                 -- общая сумма, потраченная на бронирования (без умножения на дни)
    COUNT(DISTINCT r.ID_hotel) AS unique_hotels  -- количество уникальных отелей
FROM Customer c
JOIN Booking b ON c.ID_customer = b.ID_customer
JOIN Room r ON b.ID_room = r.ID_room
GROUP BY c.ID_customer, c.name
HAVING COUNT(b.ID_booking) > 2                 -- более двух бронирований
   AND COUNT(DISTINCT r.ID_hotel) > 1         -- бронировал в более чем одном отеле
   AND SUM(r.price) > 500                      -- потратил больше 500 долларов
ORDER BY total_spent ASC;

-- Задача 3
SELECT
    c.ID_customer,
    c.name,
    CASE
        WHEN SUM(hotel_category = 'Дорогой') > 0 THEN 'Дорогой'    -- если есть хотя бы один дорогой отель
        WHEN SUM(hotel_category = 'Средний') > 0 THEN 'Средний'     -- если нет дорогих, но есть средние
        ELSE 'Дешевый'                                              -- иначе дешёвый
    END AS preferred_hotel_type,
    GROUP_CONCAT(DISTINCT h.name ORDER BY h.name SEPARATOR ', ') AS visited_hotels  -- уникальные посещённые отели
FROM Customer c
JOIN Booking b ON c.ID_customer = b.ID_customer
JOIN Room r ON b.ID_room = r.ID_room
JOIN Hotel h ON r.ID_hotel = h.ID_hotel
JOIN (
    SELECT
        h.ID_hotel,
        CASE
            WHEN AVG(r.price) < 175 THEN 'Дешевый'
            WHEN AVG(r.price) BETWEEN 175 AND 300 THEN 'Средний'
            ELSE 'Дорогой'
        END AS hotel_category
    FROM Hotel h
    JOIN Room r ON h.ID_hotel = r.ID_hotel
    GROUP BY h.ID_hotel
) hc ON h.ID_hotel = hc.ID_hotel
GROUP BY c.ID_customer, c.name
ORDER BY 
    FIELD(
        CASE
            WHEN SUM(hotel_category = 'Дорогой') > 0 THEN 'Дорогой'
            WHEN SUM(hotel_category = 'Средний') > 0 THEN 'Средний'
            ELSE 'Дешевый'
        END,
        'Дешевый', 'Средний', 'Дорогой'
    );  -- сортировка по приоритету: дешёвый → средний → дорогой
