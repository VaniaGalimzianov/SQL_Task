
ALTER PROCEDURE [dbo].[sp_report_1]        
    @date_from DATE,        
    @date_to DATE,        
    @good_group_name NVARCHAR(MAX)        
AS        
BEGIN        
    DECLARE @date_from_int INT;        
    DECLARE @date_to_int INT;      
      
    SET @date_from_int = (SELECT TOP 1 did FROM dbo.dim_date WHERE d = @date_from);        
    SET @date_to_int = (SELECT TOP 1 did FROM dbo.dim_date WHERE d = @date_to);        
        
    SELECT       
        d.td AS [Дата],
        s.store_name AS [Название аптеки],
        g.group_name AS [Группа товаров],
        SUM(f.sale_net) AS [Общая стоимость товаров, с НДС],        
        SUM(f.quantity) AS [Общее количество товаров],    
        SUM(f.cost_grs * f.quantity) / NULLIF(SUM(f.quantity), 0) AS [Средняя цена закупки руб., без НДС],    
        SUM(f.sale_grs * f.quantity) - SUM(f.cost_grs * f.quantity) AS [Маржа руб., без НДС],    
        CASE     
            WHEN SUM(f.cost_grs * f.quantity) = 0 THEN NULL     
            ELSE ((SUM(f.sale_grs * f.quantity) - SUM(f.cost_grs * f.quantity)) / SUM(f.cost_grs * f.quantity)) * 100     
        END AS [Наценка %, без НДС],
        CASE 
            WHEN SUM(f.sale_net) = 0 THEN 0 
            ELSE (SUM(f.sale_net) / NULLIF(SUM(f.sale_grs * f.quantity), 0)) * 100 
        END AS [Доля продаж, с НДС %]
    FROM       
        [dbo].[fct_cheque] AS f        
    INNER JOIN       
        dim_goods AS g ON g.good_id = f.good_id        
    INNER JOIN       
        dbo.dim_stores AS s ON s.store_id = f.store_id
    INNER JOIN       
        dbo.dim_date AS d ON d.did = f.date_id
    WHERE       
        f.date_id BETWEEN @date_from_int AND @date_to_int        
        AND g.group_name IN (SELECT Value FROM dbo.SplitString(@good_group_name, ', '))        
    GROUP BY 
        d.td,
        s.store_name,
        g.group_name
    ORDER BY 
        [Доля продаж, с НДС %] DESC;
END;
