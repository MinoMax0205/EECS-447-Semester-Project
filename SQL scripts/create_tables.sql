-- =====================================================================
-- Library Management System - Physical Database Schema
-- =====================================================================

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
