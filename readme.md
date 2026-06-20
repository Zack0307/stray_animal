### 📄 手冊核心層級與權限架構摘要

1. **📌 一、 系統核心資料表結構 (DDL Schema)**
   * 詳細記錄 `Animal`、`Adopt`、`Adoption_Application` 、`Audit_Log`、`Medical Record`、`shelter`、`staff` 總共七大資料表，紀錄來自政府資料公開平台的流浪動物收容數據，分別記錄動物的各項特徵、認養人、認養人申請、動物每天記錄表、收容所所在地、員工以及動物醫療紀錄
2. **🔐 二、 三大核心角色權限控管矩陣 (RBAC Matrix)**
   * 用一張一目了然的 **Markdown 表格**，橫向對比三大角色對於所有資料表的「新增、刪除、修改、查詢（CRUD）」權限界線。
3. **👑 1. 第一層級：大波士超級管理員 (Admin Level)**
   * 審核認養人許可。
   * 全台園區飽和度儀表板（不受 `shelter_id` 束縛的宏觀視野）。
   * 員工停權與離職手動操作。
   > globaladmin_ActivatestaffRight.sql --啟動員工各項權利
   > globaladmin_determine_adopter.sql --審核認養人資格
   > globaladmin_searchauditlog.sql --查閱動物紀錄
4. **🛠️ 2. 第二層級：地方收容所志工 (Volunteer Level)**
   * 實作**多租戶資料隔離 (Multi-tenancy Isolation)**。
   * **身分與角色雙重驗證**：上架時利用操作者姓名動態綁定自身收容所，防呆係數拉滿。
   * **跨區修改之五道防線聯合阻斷**：核對「志工園區」與「目標毛孩園區」UUID，不符當場噴紅字警告。
   > volunteer_addnew_animal.sql --上架新收容動物
   > volunteer_fix_othershelter.sql  --修改其他收容所動物
   > volunteer_owner_animal.sql --志工所屬收容所動物
5. **🔍 3. 第三層級：一般民眾 / 認養人 (Adopter Level)**
   * 前台全台公開瀏覽（強制 `status = N'開放'` 防線，讓醫療中毛孩自動隱形）。
   * 線上提交認養單（狀態後端強制鎖定 `'審核中'`，防止民眾偷改）。
   * 會員中心個人隱私進度隔離（嚴格執行 `WHERE adopter_id = @我自己的ID`）。
   > adopter_list_all_animal.sql --查詢全台動物
   > adopter_applicaton_create.sql --認養人申請資料表創建


