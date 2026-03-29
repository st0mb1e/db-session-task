-- СУБД: MySQL
-- Задача 1
WITH RECURSIVE Subordinates AS (
    -- выбираем Ивана Иванова
    SELECT e.EmployeeID, e.Name, e.ManagerID, e.DepartmentID, e.RoleID
    FROM Employees e
    WHERE e.EmployeeID = 1

    UNION ALL

    -- выбираем всех сотрудников, подчиненных найденным выше
    SELECT e.EmployeeID, e.Name, e.ManagerID, e.DepartmentID, e.RoleID
    FROM Employees e
    INNER JOIN Subordinates s ON e.ManagerID = s.EmployeeID
)
SELECT 
    s.EmployeeID,
    s.Name AS EmployeeName,
    s.ManagerID,
    d.DepartmentName,
    r.RoleName,
    GROUP_CONCAT(DISTINCT p.ProjectName ORDER BY p.ProjectName SEPARATOR ', ') AS ProjectNames, -- проекты сотрудника
    GROUP_CONCAT(DISTINCT t.TaskName ORDER BY t.TaskName SEPARATOR ', ') AS TaskNames        -- задачи сотрудника
FROM Subordinates s
LEFT JOIN Departments d ON s.DepartmentID = d.DepartmentID
LEFT JOIN Roles r ON s.RoleID = r.RoleID
LEFT JOIN Projects p ON p.DepartmentID = s.DepartmentID                                         -- проекты по отделу
LEFT JOIN Tasks t ON t.AssignedTo = s.EmployeeID                                                -- задачи, назначенные сотруднику
GROUP BY s.EmployeeID, s.Name, s.ManagerID, d.DepartmentName, r.RoleName
ORDER BY s.Name;

-- Задача 2
WITH RECURSIVE Subordinates AS (
    -- выбираем Ивана Иванова
    SELECT e.EmployeeID, e.Name, e.ManagerID, e.DepartmentID, e.RoleID
    FROM Employees e
    WHERE e.EmployeeID = 1

    UNION ALL

    -- выбираем всех сотрудников, подчиненных найденным выше
    SELECT e.EmployeeID, e.Name, e.ManagerID, e.DepartmentID, e.RoleID
    FROM Employees e
    INNER JOIN Subordinates s ON e.ManagerID = s.EmployeeID
)
SELECT 
    s.EmployeeID,
    s.Name AS EmployeeName,
    s.ManagerID,
    d.DepartmentName,
    r.RoleName,
    GROUP_CONCAT(DISTINCT p.ProjectName ORDER BY p.ProjectName SEPARATOR ', ') AS ProjectNames,   -- проекты сотрудника
    GROUP_CONCAT(DISTINCT t.TaskName ORDER BY t.TaskName SEPARATOR ', ') AS TaskNames,           -- задачи сотрудника
    COUNT(DISTINCT t.TaskID) AS TotalTasks,                                                      -- количество задач
    (SELECT COUNT(*) FROM Employees e2 WHERE e2.ManagerID = s.EmployeeID) AS TotalSubordinates   -- количество прямых подчинённых
FROM Subordinates s
LEFT JOIN Departments d ON s.DepartmentID = d.DepartmentID
LEFT JOIN Roles r ON s.RoleID = r.RoleID
LEFT JOIN Projects p ON p.DepartmentID = s.DepartmentID                                         -- проекты по отделу
LEFT JOIN Tasks t ON t.AssignedTo = s.EmployeeID                                                -- задачи сотрудника
GROUP BY s.EmployeeID, s.Name, s.ManagerID, d.DepartmentName, r.RoleName
ORDER BY s.Name;

-- Задача 3
WITH RECURSIVE AllSubordinates AS (
    -- Каждому сотруднику сопоставляем его подчинённых (всех уровней)
    SELECT EmployeeID AS ManagerID, EmployeeID AS SubordinateID
    FROM Employees
    WHERE EmployeeID IS NOT NULL

    UNION ALL

    SELECT s.ManagerID, e.EmployeeID
    FROM Employees e
    INNER JOIN AllSubordinates s ON e.ManagerID = s.SubordinateID
),
ManagerSubordinates AS (
    -- Подсчет общего числа подчинённых для каждого менеджера
    SELECT ManagerID, COUNT(DISTINCT SubordinateID) AS TotalSubordinates
    FROM AllSubordinates
    WHERE ManagerID <> SubordinateID -- исключаем самого менеджера
    GROUP BY ManagerID
)
SELECT 
    e.EmployeeID,
    e.Name AS EmployeeName,
    e.ManagerID,
    d.DepartmentName,
    r.RoleName,
    GROUP_CONCAT(DISTINCT p.ProjectName ORDER BY p.ProjectName SEPARATOR ', ') AS ProjectNames, -- проекты сотрудника
    GROUP_CONCAT(DISTINCT t.TaskName ORDER BY t.TaskName SEPARATOR ', ') AS TaskNames,           -- задачи сотрудника
    ms.TotalSubordinates                                                                        -- общее число подчинённых
FROM Employees e
INNER JOIN Roles r ON e.RoleID = r.RoleID
LEFT JOIN Departments d ON e.DepartmentID = d.DepartmentID
LEFT JOIN Projects p ON p.DepartmentID = e.DepartmentID
LEFT JOIN Tasks t ON t.AssignedTo = e.EmployeeID
LEFT JOIN ManagerSubordinates ms ON e.EmployeeID = ms.ManagerID
WHERE r.RoleName = 'Менеджер'
  AND ms.TotalSubordinates > 0
GROUP BY e.EmployeeID, e.Name, e.ManagerID, d.DepartmentName, r.RoleName, ms.TotalSubordinates
ORDER BY e.EmployeeID;
