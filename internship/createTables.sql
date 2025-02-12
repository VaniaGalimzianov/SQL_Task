-- Таблица для чеков
CREATE TABLE receipts (
    receipt_id UUID PRIMARY KEY,
    terminalid VARCHAR(255),
    warehouseid INT,
    doc_type VARCHAR(10) CHECK (doc_type IN ('sale', 'return')),
    date TIMESTAMP,
    items_count INT
);

-- Таблица для строк чеков
CREATE TABLE receipt_lines (
    line_id UUID PRIMARY KEY,
    receipt_id UUID REFERENCES receipts(receipt_id),
    itemid INT,
    discount_name VARCHAR(255),
    quantity INT,
    pricebase DECIMAL(10, 2),
    pricesale DECIMAL(10, 2),
    discount DECIMAL(10, 2),
    amount DECIMAL(10, 2),
    cogs DECIMAL(10, 2)
);

-- Таблица для возвратов
CREATE TABLE returns (
    id UUID PRIMARY KEY,
    warehouse_id INT,
    docnum VARCHAR(255),
    docdate TIMESTAMP,
    supplier_id INT,
    amount DECIMAL(10, 2),
    status INT,
    status_name VARCHAR(255)
);

-- Таблица для строк возвратов
CREATE TABLE return_lines (
    line_id UUID PRIMARY KEY,
    return_id UUID REFERENCES returns(id),
    item_id INT,
    quantity INT,
    price DECIMAL(10, 2),
    amount DECIMAL(10, 2),
    expir_date DATE
);

-- Таблица для приходов
CREATE TABLE income (
    id UUID PRIMARY KEY,
    warehouse_id INT,
    docdate TIMESTAMP,
    supplier_id INT,
    amount DECIMAL(10, 2),
    status VARCHAR(10) CHECK (status IN ('accept', 'draft'))
);

-- Таблица для строк приходов
CREATE TABLE income_lines (
    item_id INT,
    quantity INT,
    price DECIMAL(10, 2),
    amount DECIMAL(10, 2),
    income_id UUID REFERENCES income(id)
);

-- Таблица для перемещений
CREATE TABLE movegoods (
    id UUID PRIMARY KEY,
    src_warehouse_id INT,
    dst_warehouse_id INT,
    amount DECIMAL(10, 2),
    status INT,
    status_name VARCHAR(255),
    created_date TIMESTAMP
);

-- Таблица для строк перемещений
CREATE TABLE movegood_lines (
    line_id UUID PRIMARY KEY,
    movegood_id UUID REFERENCES movegoods(id),
    item_id INT,
    quantity INT,
    price DECIMAL(10, 2),
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
    item_id INT,
    quantity INT,
    price DECIMAL(10, 2),
    cogs DECIMAL(10, 2)
);
