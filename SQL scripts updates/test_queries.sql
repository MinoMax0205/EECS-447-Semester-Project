-- =====================================================================
-- test_queries.sql 
-- Library Management System 
-- =====================================================================

-- =====================================================================
-- Parameter block derived from current dataset
--    Using SELECT expressions keeps tests in sync with populate_data.sql
-- =====================================================================
SET @TargetAuthorName := (
    SELECT FullName FROM AuthorCreator WHERE AuthorID = 5
);

SET @TargetPublicationYear := (
    SELECT PublicationYear FROM Item
    WHERE ItemType = 'Book'
    ORDER BY ItemID
    LIMIT 1 OFFSET 4   -- ItemID 5 (Curated Book 05) => 2005
);

SET @TargetClientID := 1; -- Client 01 always exists in seeded data

SET @TargetGenre := (
    SELECT Genre FROM Item
    WHERE ItemType = 'Book' AND Genre IS NOT NULL
    ORDER BY ItemID
    LIMIT 1
);

-- =====================================================================
-- 1. List all books by a specific author
-- =====================================================================
SELECT 
    ac.FullName AS Author,
    i.Title AS BookTitle,
    i.PublicationYear,
    b.Publisher
FROM Item i
JOIN Book b ON i.ItemID = b.ItemID
JOIN ItemAuthor ia ON i.ItemID = ia.ItemID
JOIN AuthorCreator ac ON ia.AuthorID = ac.AuthorID
WHERE ac.FullName = @TargetAuthorName;

-- =====================================================================
-- 2. Find books by publication year
-- =====================================================================
SELECT 
    i.ItemID,
    i.Title,
    b.ISBN,
    i.PublicationYear,
    b.Publisher
FROM Item i
JOIN Book b ON i.ItemID = b.ItemID
WHERE i.PublicationYear = @TargetPublicationYear;

-- =====================================================================
-- 3. Check membership status of a specific client
-- =====================================================================
SELECT
    c.ClientID,
    c.FullName AS ClientName,
    mt.Name AS MembershipType,
    c.AccountStatus
FROM Client c
JOIN MembershipType mt ON c.MembershipTypeID = mt.MembershipTypeID
WHERE c.ClientID = @TargetClientID;

-- =====================================================================
-- 4. Book availability by genre
-- =====================================================================
SELECT 
    ItemID,
    Title,
    Genre,
    AvailabilityStatus
FROM Item
WHERE ItemType = 'Book'
  AND Genre = @TargetGenre
  AND AvailabilityStatus = 'Available';

-- =====================================================================
-- 5. Fine calculation: total late fees charged to each member
-- =====================================================================
SELECT
    c.ClientID,
    c.FullName AS ClientName,
    SUM(l.LateFeeCharged) AS TotalLateFees
FROM Client c
JOIN Loan l ON c.ClientID = l.ClientID
GROUP BY c.ClientID, ClientName
ORDER BY TotalLateFees DESC;

-- =====================================================================
-- 6. Frequent borrowers of a genre in the last year
-- =====================================================================
SELECT 
    c.ClientID,
    c.FullName AS ClientName,
    COUNT(l.LoanID) AS BorrowCount
FROM Loan l
JOIN Client c ON l.ClientID = c.ClientID
JOIN Item i ON l.ItemID = i.ItemID
WHERE i.Genre = 'Fiction'
  AND YEAR(l.CheckedOutAt) = YEAR(CURDATE())
GROUP BY c.ClientID, ClientName
ORDER BY BorrowCount DESC;

-- =====================================================================
-- 7. Books due within the next week
-- =====================================================================
SELECT
    l.LoanID,
    i.Title,
    c.ClientID,
    c.FullName AS ClientName,
    l.DueAt
FROM Loan l
JOIN Item i ON l.ItemID = i.ItemID
JOIN Client c ON l.ClientID = c.ClientID
WHERE l.DueAt BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 7 DAY)
  AND l.Status = 'Open'
ORDER BY l.DueAt;

-- =====================================================================
-- 8. Members with overdue books
-- =====================================================================
SELECT
    c.ClientID,
    c.FullName AS ClientName,
    i.Title AS OverdueItem,
    l.DueAt,
    DATEDIFF(NOW(), l.DueAt) AS DaysOverdue
FROM Loan l
JOIN Client c ON l.ClientID = c.ClientID
JOIN Item i ON l.ItemID = i.ItemID
WHERE l.Status = 'Overdue';

-- =====================================================================
-- 9. Average borrowing time for a specific genre
-- =====================================================================
SELECT
    i.Genre,
    AVG(DATEDIFF(l.ReturnedAt, l.CheckedOutAt)) AS AvgBorrowDays
FROM Loan l
JOIN Item i ON l.ItemID = i.ItemID
WHERE l.ReturnedAt IS NOT NULL
  AND i.Genre = 'Technology'
GROUP BY i.Genre;

-- =====================================================================
-- 10. Most popular author last month
-- =====================================================================
SELECT
    ac.FullName AS AuthorName,
    COUNT(l.LoanID) AS LoansLastMonth
FROM Loan l
JOIN ItemAuthor ia ON l.ItemID = ia.ItemID
JOIN AuthorCreator ac ON ia.AuthorID = ac.AuthorID
WHERE l.CheckedOutAt >= DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 1 MONTH), '%Y-%m-01')
  AND l.CheckedOutAt < DATE_FORMAT(NOW(), '%Y-%m-01')
GROUP BY ac.FullName
ORDER BY LoansLastMonth DESC
LIMIT 1;

-- =====================================================================
-- 11. Monthly fees report (by membership type)
-- =====================================================================
SELECT
    mt.Name AS MembershipType,
    DATE_FORMAT(p.PaidAt, '%Y-%m') AS YearMonth,
    SUM(p.Amount) AS TotalFees
FROM Payment p
JOIN Client c ON p.ClientID = c.ClientID
JOIN MembershipType mt ON c.MembershipTypeID = mt.MembershipTypeID
WHERE p.PaidAt >= DATE_SUB(DATE_FORMAT(CURDATE(), '%Y-%m-01'), INTERVAL 1 MONTH)
  AND p.PaidAt < DATE_FORMAT(CURDATE(), '%Y-%m-01')
GROUP BY mt.Name, YearMonth
ORDER BY mt.Name;

-- =====================================================================
-- 12. Clients who exceeded borrowing limits
-- =====================================================================
SELECT
    c.ClientID,
    c.FullName AS ClientName,
    mt.Name AS MembershipType,
    mt.MaxConcurrentLoans,
    SUM(CASE WHEN l.Status IN ('Open','Overdue') THEN 1 ELSE 0 END) AS ActiveLoans
FROM Client c
JOIN MembershipType mt ON c.MembershipTypeID = mt.MembershipTypeID
LEFT JOIN Loan l ON c.ClientID = l.ClientID
GROUP BY c.ClientID, ClientName, mt.Name, mt.MaxConcurrentLoans
HAVING ActiveLoans > MaxConcurrentLoans;

-- =====================================================================
-- 13. Most frequently borrowed items by membership type
-- =====================================================================
SELECT
    mt.Name AS MembershipType,
    i.Title,
    COUNT(l.LoanID) AS BorrowCount
FROM Loan l
JOIN Client c ON l.ClientID = c.ClientID
JOIN MembershipType mt ON c.MembershipTypeID = mt.MembershipTypeID
JOIN Item i ON l.ItemID = i.ItemID
GROUP BY mt.Name, i.Title
ORDER BY mt.Name, BorrowCount DESC;

-- =====================================================================
-- 14. Clients who never returned an item late
-- =====================================================================
SELECT
    c.ClientID,
    c.FullName AS ClientName
FROM Client c
WHERE c.ClientID NOT IN (
    SELECT ClientID
    FROM Loan
    WHERE Status = 'Overdue'
);

-- =====================================================================
-- 15. Average loan duration overall
-- =====================================================================
SELECT
    AVG(DATEDIFF(ReturnedAt, CheckedOutAt)) AS AvgLoanDays
FROM Loan
WHERE ReturnedAt IS NOT NULL;

-- =====================================================================
-- 16. Monthly summary report
-- =====================================================================
SELECT
    monthly.YearMonth,
    monthly.TotalLoans,
    COALESCE(fees.TotalFees, 0) AS TotalFees,
    (SELECT i.Title
     FROM Item i
     WHERE i.ItemID = (
         SELECT l2.ItemID
         FROM Loan l2
         WHERE DATE_FORMAT(l2.CheckedOutAt, '%Y-%m') = monthly.YearMonth
         GROUP BY l2.ItemID
         ORDER BY COUNT(*) DESC, l2.ItemID ASC
         LIMIT 1
     )
    ) AS MostPopularItem
FROM (
    SELECT 
        DATE_FORMAT(CheckedOutAt, '%Y-%m') AS YearMonth,
        COUNT(*) AS TotalLoans
    FROM Loan
    GROUP BY DATE_FORMAT(CheckedOutAt, '%Y-%m')
) AS monthly
LEFT JOIN (
    SELECT 
        DATE_FORMAT(PaidAt, '%Y-%m') AS YearMonth,
        SUM(Amount) AS TotalFees
    FROM Payment
    GROUP BY DATE_FORMAT(PaidAt, '%Y-%m')
) AS fees ON monthly.YearMonth = fees.YearMonth
ORDER BY monthly.YearMonth;

-- =====================================================================
-- 17. Statistics breakdown by client type and item category
-- =====================================================================
SELECT
    mt.Name AS MembershipType,
    i.ItemType,
    COUNT(l.LoanID) AS BorrowCount
FROM Loan l
JOIN Client c ON l.ClientID = c.ClientID
JOIN MembershipType mt ON c.MembershipTypeID = mt.MembershipTypeID
JOIN Item i ON l.ItemID = i.ItemID
GROUP BY mt.Name, i.ItemType;

-- =====================================================================
-- 18. Client borrowing report
-- =====================================================================
SELECT
    c.ClientID,
    c.FullName AS ClientName,
    i.Title,
    l.CheckedOutAt,
    l.DueAt,
    l.ReturnedAt,
    l.Status,
    l.LateFeeCharged AS LoanLateFee,
    (SELECT COALESCE(SUM(l2.LateFeeCharged), 0)
     FROM Loan l2
     WHERE l2.ClientID = c.ClientID) AS TotalFeesAccrued,
    r.ReservationID
FROM Client c
LEFT JOIN Loan l ON c.ClientID = l.ClientID
LEFT JOIN Item i ON i.ItemID = l.ItemID
LEFT JOIN Reservation r ON c.ClientID = r.ClientID
ORDER BY c.ClientID;

-- =====================================================================
-- 19. Item availability + last borrowed date
-- =====================================================================
SELECT
    i.ItemID,
    i.Title,
    i.ItemType,
    i.AvailabilityStatus,
    MAX(l.CheckedOutAt) AS LastBorrowedDate,
    CASE
        WHEN MAX(l.CheckedOutAt) IS NULL THEN 'Never Borrowed'
        WHEN MAX(l.CheckedOutAt) < DATE_SUB(NOW(), INTERVAL 6 MONTH)
             THEN 'Stale (6+ months)'
        ELSE 'Recently Borrowed'
    END AS CirculationStatus
FROM Item i
LEFT JOIN Loan l ON l.ItemID = i.ItemID
GROUP BY i.ItemID, i.Title, i.ItemType, i.AvailabilityStatus
ORDER BY CirculationStatus DESC, i.Title;

-- =====================================================================
-- 20. Overdue items report with calculated late fees
-- =====================================================================
SELECT
    l.LoanID,
    i.Title,
    c.FullName AS ClientName,
    l.DueAt,
    DATEDIFF(NOW(), l.DueAt) AS DaysOverdue,
    mt.DailyLateFee,
    DATEDIFF(NOW(), l.DueAt) * mt.DailyLateFee AS CalculatedLateFee,
    l.LateFeeCharged AS ActualLateFee
FROM Loan l
JOIN Client c ON l.ClientID = c.ClientID
JOIN MembershipType mt ON c.MembershipTypeID = mt.MembershipTypeID
JOIN Item i ON l.ItemID = i.ItemID
WHERE l.Status = 'Overdue';

-- =====================================================================
-- 21. Revenue summary by membership type
-- =====================================================================
SELECT
    mt.Name AS MembershipType,
    SUM(p.Amount) AS TotalRevenue
FROM Payment p
JOIN Client c ON p.ClientID = c.ClientID
JOIN MembershipType mt ON c.MembershipTypeID = mt.MembershipTypeID
GROUP BY mt.Name
ORDER BY TotalRevenue DESC;

-- =====================================================================
-- 22. Active reservations with queue information
-- =====================================================================
SELECT
    r.ReservationID,
    c.FullName AS ClientName,
    i.Title AS ItemTitle,
    r.PlacedAt,
    r.QueuePosition,
    r.Status
FROM Reservation r
JOIN Client c ON r.ClientID = c.ClientID
JOIN Item i ON r.ItemID = i.ItemID
WHERE r.Status = 'Active'
ORDER BY r.ItemID, r.QueuePosition;

-- =====================================================================
-- 23. Items by availability status
-- =====================================================================
SELECT
    i.AvailabilityStatus,
    i.ItemType,
    COUNT(*) AS ItemCount,
    SUM(i.StockQuantity) AS TotalStock
FROM Item i
GROUP BY i.AvailabilityStatus, i.ItemType
ORDER BY i.AvailabilityStatus, i.ItemType;

-- =====================================================================
-- 24. Late fee revenue by membership type and item category
-- =====================================================================
SELECT
    mt.Name AS MembershipType,
    i.ItemType,
    SUM(l.LateFeeCharged) AS LateFeeRevenue
FROM Loan l
JOIN Client c ON l.ClientID = c.ClientID
JOIN MembershipType mt ON c.MembershipTypeID = mt.MembershipTypeID
JOIN Item i ON l.ItemID = i.ItemID
GROUP BY mt.Name, i.ItemType
ORDER BY mt.Name, i.ItemType;

-- =====================================================================
-- END OF FILE
-- =====================================================================
