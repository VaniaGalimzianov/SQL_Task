CREATE TABLE dbo.GoodGroups (
    id INT PRIMARY KEY,
    name NVARCHAR(255) NOT NULL,
    parent_id INT NULL,
    not_show_in_shop BIT NOT NULL,
    created_date DATETIME NOT NULL,
    last_update_date DATETIME NOT NULL
);

CREATE TABLE dbo.Goods (
    id INT PRIMARY KEY,
    name NVARCHAR(255) NOT NULL,
    manufacturer_id INT NULL,
    barcodes NVARCHAR(100) NULL,
    vat_percent DECIMAL(5,2) NULL,
    created_date DATETIME NOT NULL,
    last_update_date DATETIME NOT NULL
);

CREATE TABLE dbo.Manufacturers (
    id INT PRIMARY KEY,
    name NVARCHAR(255) NOT NULL,
    created_date DATETIME NOT NULL,
    last_update_date DATETIME NOT NULL
);
