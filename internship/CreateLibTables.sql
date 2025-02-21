CREATE TABLE dbo.GoodGroups (
    id INT PRIMARY KEY,
    name NVARCHAR(255) NOT NULL,
    parent_id INT NULL,
    not_show_in_shop BIT NOT NULL,
    created_date DATETIME NOT NULL,
    last_update_date DATETIME NOT NULL
);

