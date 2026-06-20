USE stray_animal;
GO

DECLARE @DeleteID INT = 2026060210; 

BEGIN TRANSACTION;

BEGIN TRY

   
    DELETE FROM animal_stage
    WHERE animal_id = @DeleteID;

   
    DELETE FROM Animal
    WHERE gov_animal_id = @DeleteID;

   
    COMMIT TRANSACTION;
    PRINT N'💥 硬刪除成功！該毛孩的所有資料已從資料庫中徹底蒸發、不留痕跡。';

END TRY
BEGIN CATCH
    
    ROLLBACK TRANSACTION;
    PRINT N'❌ 刪除失敗！錯誤原因：' + ERROR_MESSAGE();
END CATCH;
GO