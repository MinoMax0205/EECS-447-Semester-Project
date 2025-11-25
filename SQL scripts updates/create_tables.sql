-- Drop existing triggers (so script can be rerun safely)
DROP TRIGGER IF EXISTS trg_loan_before_insert;
DROP TRIGGER IF EXISTS trg_loan_before_update;
DROP TRIGGER IF EXISTS trg_reservation_before_insert;
DROP TRIGGER IF EXISTS trg_reservation_after_update;
DROP TRIGGER IF EXISTS trg_item_status_after_reservation;

-- Drop existing tables to avoid conflicts (for development use)
DROP TABLE IF EXISTS Notification;
DROP TABLE IF EXISTS Payment;
DROP TABLE IF EXISTS Loan;
DROP TABLE IF EXISTS Reservation;
DROP TABLE IF EXISTS ItemAuthor;
DROP TABLE IF EXISTS AuthorCreator;
DROP TABLE IF EXISTS Book;
DROP TABLE IF EXISTS Magazine;
DROP TABLE IF EXISTS DigitalMedia;
DROP TABLE IF EXISTS Item;
DROP TABLE IF EXISTS Client;
DROP TABLE IF EXISTS MembershipType;

-- =====================================================================
-- 1. MembershipType
-- =====================================================================
CREATE TABLE MembershipType (
    MembershipTypeID INT PRIMARY KEY,
    Name             VARCHAR(50) NOT NULL,
    MaxConcurrentLoans INT NOT NULL CHECK (MaxConcurrentLoans >= 0),
    LoanDurationDays INT NOT NULL CHECK (LoanDurationDays >= 1),
    DailyLateFee     DECIMAL(6,2) NOT NULL CHECK (DailyLateFee >= 0),
    ReservationLimit INT NOT NULL CHECK (ReservationLimit >= 0)
);

-- =====================================================================
-- 2. Client
-- =====================================================================
CREATE TABLE Client (
    ClientID        INT PRIMARY KEY,
    FullName        VARCHAR(120) NOT NULL,
    Email           VARCHAR(120) UNIQUE NOT NULL,
    Phone           VARCHAR(25),
    Address         VARCHAR(255),
    JoinDate        DATE,
    AccountStatus   ENUM('Active','Suspended','Closed') NOT NULL DEFAULT 'Active',
    MembershipTypeID INT NOT NULL,
    
    CONSTRAINT fk_client_membership
        FOREIGN KEY (MembershipTypeID) REFERENCES MembershipType(MembershipTypeID)
);

-- =====================================================================
-- 3. Item (supertype)
-- =====================================================================
CREATE TABLE Item (
    ItemID            INT PRIMARY KEY,
    Title             VARCHAR(255) NOT NULL,
    Genre             VARCHAR(60),
    PublicationYear   INT,
    AvailabilityStatus ENUM('Available','OnLoan','Reserved','Lost','Damaged') 
                          NOT NULL DEFAULT 'Available',
    Price             DECIMAL(6,2),
    StockQuantity     INT NOT NULL CHECK (StockQuantity >= 0),
    ItemType          ENUM('Book','DigitalMedia','Magazine') NOT NULL
);

-- =====================================================================
-- 4. Book (subtype)
-- =====================================================================
CREATE TABLE Book (
    ItemID    INT PRIMARY KEY,
    ISBN      VARCHAR(17) UNIQUE,
    Publisher VARCHAR(120),
    
    CONSTRAINT fk_book_item
        FOREIGN KEY (ItemID) REFERENCES Item(ItemID)
        ON DELETE CASCADE
);

-- =====================================================================
-- 5. Magazine (subtype)
-- =====================================================================
CREATE TABLE Magazine (
    ItemID    INT PRIMARY KEY,
    IssueDate DATE,
    Publisher VARCHAR(120),
    
    CONSTRAINT fk_magazine_item
        FOREIGN KEY (ItemID) REFERENCES Item(ItemID)
        ON DELETE CASCADE
);

-- =====================================================================
-- 6. DigitalMedia (subtype)
-- =====================================================================
CREATE TABLE DigitalMedia (
    ItemID    INT PRIMARY KEY,
    MediaType VARCHAR(40),
    Publisher VARCHAR(120),
    
    CONSTRAINT fk_digitalmedia_item
        FOREIGN KEY (ItemID) REFERENCES Item(ItemID)
        ON DELETE CASCADE
);

-- =====================================================================
-- 7. AuthorCreator
-- =====================================================================
CREATE TABLE AuthorCreator (
    AuthorID    INT PRIMARY KEY,
    FullName    VARCHAR(120) NOT NULL,
    BirthYear   INT,
    Country     VARCHAR(60)
);

-- =====================================================================
-- 8. ItemAuthor (many-to-many relationship between Item and AuthorCreator)
-- =====================================================================
CREATE TABLE ItemAuthor (
    ItemID   INT NOT NULL,
    AuthorID INT NOT NULL,
    Role     ENUM('Author','Editor','Narrator','Director','Other') DEFAULT 'Author',
    
    PRIMARY KEY (ItemID, AuthorID),
    
    CONSTRAINT fk_itemauthor_item
        FOREIGN KEY (ItemID) REFERENCES Item(ItemID)
        ON DELETE CASCADE,
    CONSTRAINT fk_itemauthor_author
        FOREIGN KEY (AuthorID) REFERENCES AuthorCreator(AuthorID)
        ON DELETE CASCADE
);

-- =====================================================================
-- 9. Loan
-- =====================================================================
CREATE TABLE Loan (
    LoanID         INT PRIMARY KEY,
    ClientID       INT NOT NULL,
    ItemID         INT NOT NULL,
    CheckedOutAt   DATETIME NOT NULL,
    DueAt          DATETIME NOT NULL,
    ReturnedAt     DATETIME,
    LateFeeCharged DECIMAL(8,2) NOT NULL DEFAULT 0.00 CHECK (LateFeeCharged >= 0),
    Status         ENUM('Open','Closed','Overdue') NOT NULL DEFAULT 'Open',
    
    CHECK (DueAt > CheckedOutAt),
    CHECK (ReturnedAt IS NULL OR ReturnedAt >= CheckedOutAt),
    CHECK (Status <> 'Overdue' OR LateFeeCharged > 0),
    
    CONSTRAINT fk_loan_client
        FOREIGN KEY (ClientID) REFERENCES Client(ClientID),
    CONSTRAINT fk_loan_item
        FOREIGN KEY (ItemID) REFERENCES Item(ItemID)
);

-- =====================================================================
-- 10. Reservation
-- =====================================================================
CREATE TABLE Reservation (
    ReservationID INT PRIMARY KEY,
    ClientID      INT NOT NULL,
    ItemID        INT NOT NULL,
    PlacedAt      DATETIME NOT NULL,
    FulfilledAt   DATETIME,
    Status        ENUM('Active','Cancelled','Fulfilled','Expired') 
                      NOT NULL DEFAULT 'Active',
    QueuePosition INT NOT NULL CHECK (QueuePosition >= 1),
    CHECK (FulfilledAt IS NULL OR FulfilledAt >= PlacedAt),
    
    CONSTRAINT fk_reservation_client
        FOREIGN KEY (ClientID) REFERENCES Client(ClientID),
    CONSTRAINT fk_reservation_item
        FOREIGN KEY (ItemID) REFERENCES Item(ItemID)
);

-- =====================================================================
-- 11. Payment
-- =====================================================================
CREATE TABLE Payment (
    PaymentID INT PRIMARY KEY,
    ClientID  INT NOT NULL,
    Amount    DECIMAL(8,2) NOT NULL CHECK (Amount > 0),
    PaidAt    DATETIME NOT NULL,
    Method    ENUM('Cash','Card','Online') NOT NULL,
    
    CONSTRAINT fk_payment_client
        FOREIGN KEY (ClientID) REFERENCES Client(ClientID)
);

-- =====================================================================
-- 12. Notification
-- =====================================================================
CREATE TABLE Notification (
    NotificationID INT PRIMARY KEY,
    ClientID       INT NOT NULL,
    Type           ENUM('DueSoon','Overdue','ReservationAvailable') NOT NULL,
    Message        TEXT,
    
    CONSTRAINT fk_notification_client
        FOREIGN KEY (ClientID) REFERENCES Client(ClientID)
);

-- =====================================================================
-- Triggers to enforce business rules
-- =====================================================================
DELIMITER $$

CREATE TRIGGER trg_loan_before_insert
BEFORE INSERT ON Loan
FOR EACH ROW
BEGIN
    DECLARE v_max_loans INT;
    DECLARE v_active_loans INT;
    DECLARE v_stock INT;
    DECLARE v_current_on_loan INT;
    DECLARE v_daily_fee DECIMAL(6,2);
    DECLARE v_effective_return DATETIME;
    DECLARE v_days_overdue INT;

    -- Membership context & daily fee
    SELECT mt.MaxConcurrentLoans, mt.DailyLateFee
        INTO v_max_loans, v_daily_fee
    FROM Client c
        JOIN MembershipType mt ON mt.MembershipTypeID = c.MembershipTypeID
    WHERE c.ClientID = NEW.ClientID;

    IF NEW.ReturnedAt IS NULL THEN
        -- Membership loan limit enforcement
        SELECT COUNT(*)
            INTO v_active_loans
        FROM Loan
        WHERE ClientID = NEW.ClientID
          AND Status IN ('Open','Overdue');

        IF v_active_loans + 1 > v_max_loans THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Borrowing limit exceeded for membership type.';
        END IF;

        -- Stock enforcement per item (only matters for active loans)
        SELECT StockQuantity INTO v_stock
        FROM Item
        WHERE ItemID = NEW.ItemID
        FOR UPDATE;

        IF v_stock IS NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Item does not exist.';
        END IF;

        SELECT COUNT(*)
            INTO v_current_on_loan
        FROM Loan
        WHERE ItemID = NEW.ItemID
          AND Status IN ('Open','Overdue');

        IF v_current_on_loan + 1 > v_stock THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'All copies of this item are already on loan.';
        END IF;
    ELSE
        -- Ensure referenced item exists even for historical records
        SELECT COUNT(*)
            INTO v_stock
        FROM Item
        WHERE ItemID = NEW.ItemID;

        IF v_stock = 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Item does not exist.';
        END IF;
    END IF;

    -- Default status and fee calculations
    IF NEW.ReturnedAt IS NOT NULL THEN
        SET NEW.Status = 'Closed';
        IF NEW.ReturnedAt > NEW.DueAt THEN
            SET v_effective_return = NEW.ReturnedAt;
            SET v_days_overdue = GREATEST(DATEDIFF(v_effective_return, NEW.DueAt), 0);
            SET NEW.LateFeeCharged = ROUND(v_days_overdue * v_daily_fee, 2);
        ELSE
            SET NEW.LateFeeCharged = 0;
        END IF;
    ELSE
        IF NEW.DueAt <= NEW.CheckedOutAt THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Due date must be after checkout date.';
        END IF;

        IF NEW.DueAt < NOW() THEN
            SET v_effective_return = NOW();
            SET v_days_overdue = GREATEST(DATEDIFF(v_effective_return, NEW.DueAt), 0);
            IF v_days_overdue > 0 THEN
                SET NEW.Status = 'Overdue';
                SET NEW.LateFeeCharged = ROUND(v_days_overdue * v_daily_fee, 2);
            END IF;
        ELSE
            SET NEW.Status = 'Open';
            SET NEW.LateFeeCharged = 0;
        END IF;
    END IF;

    -- Mark item as on loan for active loans
    IF NEW.ReturnedAt IS NULL THEN
        UPDATE Item
        SET AvailabilityStatus = 'OnLoan'
        WHERE ItemID = NEW.ItemID;
    END IF;
END$$

CREATE TRIGGER trg_loan_before_update
BEFORE UPDATE ON Loan
FOR EACH ROW
BEGIN
    DECLARE v_daily_fee DECIMAL(6,2);
    DECLARE v_effective_return DATETIME;
    DECLARE v_days_overdue INT;
    DECLARE v_other_open INT;

    SELECT mt.DailyLateFee
        INTO v_daily_fee
    FROM Client c
        JOIN MembershipType mt ON mt.MembershipTypeID = c.MembershipTypeID
    WHERE c.ClientID = NEW.ClientID;

    IF NEW.ReturnedAt IS NOT NULL AND NEW.ReturnedAt < NEW.CheckedOutAt THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Return date cannot precede checkout date.';
    END IF;

    -- Calculate fees when overdue or returned late
    IF (NEW.ReturnedAt IS NULL AND NEW.DueAt < NOW())
        OR (NEW.ReturnedAt IS NOT NULL AND NEW.ReturnedAt > NEW.DueAt)
        OR NEW.Status = 'Overdue' THEN

        SET v_effective_return = COALESCE(NEW.ReturnedAt, NOW());
        SET v_days_overdue = GREATEST(DATEDIFF(v_effective_return, NEW.DueAt), 0);
        SET NEW.LateFeeCharged = ROUND(v_days_overdue * v_daily_fee, 2);

        IF NEW.ReturnedAt IS NULL THEN
            SET NEW.Status = 'Overdue';
        ELSE
            SET NEW.Status = 'Closed';
        END IF;
    ELSEIF NEW.ReturnedAt IS NOT NULL THEN
        SET NEW.LateFeeCharged = 0;
        SET NEW.Status = 'Closed';
    END IF;

    -- Update item availability when loan closes
    IF NEW.ReturnedAt IS NOT NULL THEN
        SELECT COUNT(*)
            INTO v_other_open
        FROM Loan
        WHERE ItemID = NEW.ItemID
          AND LoanID <> NEW.LoanID
          AND Status IN ('Open','Overdue');

        IF v_other_open = 0 THEN
            UPDATE Item
            SET AvailabilityStatus = 'Available'
            WHERE ItemID = NEW.ItemID;
        END IF;
    END IF;
END$$

CREATE TRIGGER trg_reservation_before_insert
BEFORE INSERT ON Reservation
FOR EACH ROW
BEGIN
    DECLARE v_res_limit INT;
    DECLARE v_existing_active INT;

    SELECT mt.ReservationLimit
        INTO v_res_limit
    FROM Client c
        JOIN MembershipType mt ON mt.MembershipTypeID = c.MembershipTypeID
    WHERE c.ClientID = NEW.ClientID;

    SELECT COUNT(*)
        INTO v_existing_active
    FROM Reservation
    WHERE ClientID = NEW.ClientID
      AND Status = 'Active';

    IF v_existing_active + 1 > v_res_limit THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Reservation limit exceeded for membership type.';
    END IF;

    -- Mark item as reserved if not currently on loan
    UPDATE Item
    SET AvailabilityStatus = 'Reserved'
    WHERE ItemID = NEW.ItemID
      AND AvailabilityStatus = 'Available';
END$$

CREATE TRIGGER trg_reservation_after_update
AFTER UPDATE ON Reservation
FOR EACH ROW
BEGIN
    DECLARE v_other_active INT;
    DECLARE v_other_open_loans INT;

    IF NEW.Status IN ('Cancelled','Fulfilled','Expired') THEN
        SELECT COUNT(*)
            INTO v_other_active
        FROM Reservation
        WHERE ItemID = NEW.ItemID
          AND ReservationID <> NEW.ReservationID
          AND Status = 'Active';

        SELECT COUNT(*)
            INTO v_other_open_loans
        FROM Loan
        WHERE ItemID = NEW.ItemID
          AND Status IN ('Open','Overdue');

        IF v_other_active = 0 AND v_other_open_loans = 0 THEN
            UPDATE Item
            SET AvailabilityStatus = 'Available'
            WHERE ItemID = NEW.ItemID;
        END IF;
    END IF;
END$$

DELIMITER ;
