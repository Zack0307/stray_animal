USE stray_animal;
GO

-- 1️⃣ 寫入第一筆：台北的林志明
INSERT INTO Adopter (id, name, phone, email, address, created_at, updated_at)
VALUES (
    NEWID(), 
    N'林志明', 
    '0912-345678', 
    'jimmy@email.com', 
    N'台北市信義區信義路一段1號', 
    GETDATE(), 
    GETDATE()
);

-- 2️⃣ 寫入第二筆：屏東的陳大同
INSERT INTO Adopter (id, name, phone, email, address, created_at, updated_at)
VALUES (
    NEWID(), 
    N'陳大同', 
    '0922-111222', 
    'datong@email.com', 
    N'屏東市自由路100號', 
    GETDATE(), 
    GETDATE()
);

-- 3️⃣ 寫入第三筆：台中的王曉婷
INSERT INTO Adopter (id, name, phone, email, address, created_at, updated_at)
VALUES (
    NEWID(), 
    N'王曉婷', 
    '0933-555666', 
    'ting@email.com', 
    N'台中市西屯區台灣大道三段99號', 
    GETDATE(), 
    GETDATE()
);

PRINT N'🎉 成功！3 筆認養人基本資料已寫入 Adopter 資料表。';
GO