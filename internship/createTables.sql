-- Таблица для чеков
CREATE TABLE receipts (
    receipt_id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    terminalid VARCHAR(255),
    warehouseid INT,
    doc_type VARCHAR(10) CHECK (doc_type IN ('sale', 'return')),
    date DATETIME2,
    items_count INT
);

-- Таблица для строк чеков
CREATE TABLE receipt_lines (
    line_id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    receipt_id UNIQUEIDENTIFIER REFERENCES receipts(receipt_id),
    itemid INT,
    quantity DECIMAL(10, 3),
    pricebase DECIMAL(10, 2),
    pricesale DECIMAL(10, 2),
    discount DECIMAL(10, 2),
    amount DECIMAL(10, 2),
    cogs DECIMAL(10, 2)
);

-- Таблица для возвратов
CREATE TABLE returns (
    id INT PRIMARY KEY,
    warehouse_id INT,
    docnum VARCHAR(255),
    docdate DATETIME2,
    supplier_id INT,
    amount DECIMAL(10, 2),
    status VARCHAR(255),
    status_name VARCHAR(255)
);

-- Таблица строк возвратов
CREATE TABLE return_lines (
    line_id INT PRIMARY KEY,
    return_id INT REFERENCES returns(id) ON DELETE CASCADE, -- Автоудаление строк при удалении возврата
    item_id INT,
    quantity DECIMAL(10, 3),
    price DECIMAL(10, 2),
    amount DECIMAL(10, 2),
    expir_date DATE
);

-- Таблица для приходов
CREATE TABLE income (
    id INT PRIMARY KEY,
    warehouse_id INT,
    docdate DATETIME2,
    supplier_id INT,
    amount DECIMAL(10, 2),
    status VARCHAR(50)
);

-- Таблица для строк приходов
CREATE TABLE income_lines (
    item_id INT,
    quantity DECIMAL(10, 2),
    price DECIMAL(10, 2),
    amount DECIMAL(10, 2),
    income_id INT REFERENCES income(id)
);

-- Таблица для перемещений
CREATE TABLE movegoods (
    id INT PRIMARY KEY,
    src_warehouse_id INT,
    dst_warehouse_id INT,
    amount DECIMAL(10, 2),
    status VARCHAR(255),
    status_name VARCHAR(255),
    created_date DATETIME2
);

-- Таблица для строк перемещений
CREATE TABLE movegood_lines (
    line_id INT PRIMARY KEY,
    movegood_id INT REFERENCES movegoods(id),
    item_id INT,
    quantity DECIMAL(10, 3),
    price DECIMAL(10, 4),
    amount DECIMAL(10, 2)
);

-- Таблица для текущих остатков
CREATE TABLE stock (
    id INT PRIMARY KEY,
);

-- Таблица для строк остатков
CREATE TABLE stock_lines (
    id INT PRIMARY KEY,
    stock_id INT REFERENCES stock(id),
    quantity INT,
    cogs DECIMAL(10, 2)
);
