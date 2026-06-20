from flask import Flask, jsonify, render_template, request, session, redirect, url_for
import pyodbc
import math

app = Flask(__name__)
app.secret_key = 'stray_animal_super_secret_key_2026'

CONN_STR = (
    r'DRIVER={ODBC Driver 17 for SQL Server};'
    r'SERVER=DESKTOP-B6AAASG\SQLEXPRESS;'
    r'DATABASE=stray_animal;'
    r'Trusted_Connection=yes;'
)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/register')
def register_page():
    return render_template('register.html')

@app.route('/login')
def login_page():
    return render_template('login.html')

@app.route('/animal/<animal_id>')
def animal_detail(animal_id):
    return render_template('detail.html', animal_id=animal_id)

@app.route('/management/dashboard')
def admin_dashboard():
    if session.get('staff_role') != '管理員':
        return "<h1>❌ 錯誤 403：您的權限不足，只有超級管理員允許進駐此後台！</h1>", 403
    return render_template('admin_dashboard.html')

# 下拉選單：撈出真實收容所
@app.route('/api/shelters')
def get_shelters():
    try:
        conn = pyodbc.connect(CONN_STR)
        cursor = conn.cursor()
        cursor.execute("SELECT id, name FROM Shelter ORDER BY name")
        shelters = [{"id": str(row[0]), "name": row[1]} for row in cursor.fetchall()]
        cursor.close()
        conn.close()
        return jsonify({"success": True, "shelters": shelters})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)})

# 下拉選單：動態撈出不重複品種
@app.route('/api/varieties')
def get_varieties():
    try:
        kind = request.args.get('kind', 'all')
        conn = pyodbc.connect(CONN_STR)
        cursor = conn.cursor()
        if kind != 'all':
            cursor.execute("SELECT DISTINCT variety FROM Animal WHERE kind = ? AND variety IS NOT NULL AND variety <> '' ORDER BY variety", (kind,))
        else:
            cursor.execute("SELECT DISTINCT variety FROM Animal WHERE variety IS NOT NULL AND variety <> '' ORDER BY variety")
        varieties = [row[0] for row in cursor.fetchall()]
        cursor.close()
        conn.close()
        return jsonify({"success": True, "varieties": varieties})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)})

# 列表 API：多條件複合分頁查詢
@app.route('/api/animals')
def get_animals():
    try:
        page = int(request.args.get('page', 1))
        limit = int(request.args.get('limit', 12))
        offset = (page - 1) * limit

        kind = request.args.get('kind', 'all')          
        variety_raw = request.args.get('variety', 'all')    
        shelter_raw = request.args.get('shelter_id', 'all') 
        sex = request.args.get('sex', 'all')            
        age = request.args.get('age', 'all')            
        district = request.args.get('district', '')     

        where_clauses = ["stg.album_file IS NOT NULL AND stg.album_file <> ''", "A.is_deleted = 0"]
        params = []

        if kind != 'all':
            where_clauses.append("A.kind = ?")
            params.append(kind)
        if variety_raw and variety_raw != 'all' and variety_raw != '':
            varieties = variety_raw.split(',')
            placeholders = ",".join(["?"] * len(varieties))
            where_clauses.append(f"A.variety IN ({placeholders})")
            params.extend(varieties)
        if shelter_raw and shelter_raw != 'all' and shelter_raw != '':
            shelters = shelter_raw.split(',')
            placeholders = ",".join(["CAST(? AS UNIQUEIDENTIFIER)"] * len(shelters))
            where_clauses.append(f"A.shelter_id IN ({placeholders})")
            params.extend(shelters)
        if sex != 'all':
            where_clauses.append("A.sex = ?")
            params.append(sex)
        if age != 'all':
            where_clauses.append("A.age = ?")
            params.append(age)
        if district:
            where_clauses.append("A.found_place LIKE ?")
            params.append(f"%{district}%")

        where_str = " AND ".join(where_clauses)
        conn = pyodbc.connect(CONN_STR)
        cursor = conn.cursor()

        count_query = f"SELECT COUNT(*) FROM Animal A JOIN animal_stage stg ON A.gov_animal_id = stg.animal_id WHERE {where_str}"
        cursor.execute(count_query, params)
        total_records = cursor.fetchone()[0]
        total_pages = math.ceil(total_records / limit)

        data_query = f"""
            SELECT 
                A.gov_animal_id, A.kind, A.variety, A.colour, A.status, A.sex,
                A.age, A.is_sterilized, A.is_vaccinated, A.found_place,
                stg.album_file, S.name AS shelter_name
            FROM Animal A
            JOIN Shelter S ON A.shelter_id = S.id
            JOIN animal_stage stg ON A.gov_animal_id = stg.animal_id
            WHERE {where_str}
            ORDER BY A.gov_animal_id
            OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
        """
        cursor.execute(data_query, params + [offset, limit])
        
        data = []
        for row in cursor.fetchall():
            data.append({
                "animal_id": row[0], "kind": row[1], "variety": row[2], 
                "colour": row[3], "status": row[4], "sex": row[5],
                "age": row[6], "is_sterilized": row[7], "is_vaccinated": row[8],
                "found_place": row[9], "album_file": row[10], "shelter_name": row[11]
            })
        cursor.close()
        conn.close()
        return jsonify({"success": True, "data": data, "pagination": {"current_page": page, "total_pages": total_pages, "total_records": total_records}})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)})

# 獲取「單一毛孩」詳細頁面 API
@app.route('/api/animal/<animal_id>')
def get_single_animal(animal_id):
    try:
        conn = pyodbc.connect(CONN_STR)
        cursor = conn.cursor()
        query = """
            SELECT 
                A.gov_animal_id, A.kind, A.variety, A.colour, A.status, A.sex, A.age, A.found_place, A.gov_subid,
                stg.album_file, S.name AS shelter_name, stg.animal_opendate, 
                COALESCE(stg.animal_title, '---') AS animal_title, 
                COALESCE(stg.shelter_tel, '---') AS shelter_tel, 
                COALESCE(stg.shelter_address, '---') AS shelter_address,
                COALESCE(stg.animal_remark, '---') AS animal_remark, 
                '無' AS animal_collar, 
                A.body_type, A.is_sterilized,
                DATEDIFF(day, TRY_CAST(stg.animal_opendate AS DATE), GETDATE()) AS days_in_shelter,
                CAST(A.shelter_id AS NVARCHAR(36)) AS shelter_id
            FROM Animal A
            JOIN Shelter S ON A.shelter_id = S.id
            JOIN animal_stage stg ON A.gov_animal_id = stg.animal_id
            WHERE A.gov_animal_id = ? AND A.is_deleted = 0
        """
        cursor.execute(query, (animal_id,))
        row = cursor.fetchone()
        
        if not row:
            return jsonify({"success": False, "error": "找不到該動物資料"})
            
        data = {
            "animal_id": row[0], "kind": row[1], "variety": row[2], "colour": row[3], "status": row[4], 
            "sex": row[5], "age": row[6], "found_place": row[7], "gov_subid": row[8], "album_file": row[9], 
            "shelter_name": row[10], "open_date": row[11], "animal_title": row[12], "shelter_tel": row[13], 
            "shelter_address": row[14], "remark": row[15], "collar": row[16], "body_type": row[17], 
            "sterilized": row[18] and '已絕育' or '未確定', "days_in_shelter": row[19] or 1,
            "shelter_id": row[20]
        }
        cursor.close()
        conn.close()
        return jsonify({"success": True, "data": data})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)})

# 志工註冊 API
@app.route('/api/register_staff', methods=['POST'])
def register_staff():
    try:
        req_data = request.get_json()
        name = req_data.get('name')
        email = req_data.get('email')
        role = req_data.get('role')
        shelter_id = req_data.get('shelter_id')
        password = req_data.get('password')
        
        conn = pyodbc.connect(CONN_STR)
        cursor = conn.cursor()
        insert_query = """
            INSERT INTO Staff (shelter_id, role, name, email, password)
            VALUES (CAST(? AS UNIQUEIDENTIFIER), ?, ?, ?, ?)
        """
        cursor.execute(insert_query, (shelter_id, role, name, email, password))
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({"success": True, "message": "志工帳號註冊成功！"})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)})

# 驗證密碼進行登入
@app.route('/api/login_staff', methods=['POST'])
def login_staff():
    try:
        req_data = request.get_json()
        email = req_data.get('email')
        password = req_data.get('password')
        
        conn = pyodbc.connect(CONN_STR)
        cursor = conn.cursor()
        cursor.execute("SELECT name, role, status FROM Staff WHERE email = ? AND password = ?", (email, password))
        row = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if row:
            db_name, db_role, db_status = row[0], row[1], row[2]
            if db_status == '審核中':
                return jsonify({"success": False, "error": "您的帳號還在【審核中】，請聯絡超級管理員核准啟用！"})
            elif db_status == '已停權':
                return jsonify({"success": False, "error": "您的帳號已被【停權封鎖】，拒絕登入！"})
                
            session['staff_name'] = db_name
            session['staff_role'] = db_role
            return jsonify({"success": True, "message": f"歡迎回來，{db_name}！"})
        else:
            return jsonify({"success": False, "error": "帳號或密碼輸入錯誤，請重新確認！"})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)})

# 供首頁前端動態查詢目前是誰登入
@app.route('/api/check_session')
def check_session():
    if 'staff_name' in session:
        return jsonify({"logged_in": True, "name": session['staff_name'], "role": session['staff_role']})
    return jsonify({"logged_in": False})

# 登出
@app.route('/api/logout')
def logout():
    session.clear()
    return redirect(url_for('index'))

# 管理員管理志工列表
@app.route('/api/admin/staff_list')
def admin_staff_list():
    if session.get('staff_role') != '管理員': return jsonify({"success": False, "error": "權限不足！"})
    try:
        conn = pyodbc.connect(CONN_STR)
        cursor = conn.cursor()
        cursor.execute("SELECT ST.id, ST.name, ST.email, ST.role, ST.status, SH.name AS shelter_name FROM Staff ST JOIN Shelter SH ON ST.shelter_id = SH.id ORDER BY ST.created_at DESC")
        list_data = [{"id": str(row[0]), "name": row[1], "email": row[2], "role": row[3], "status": row[4], "shelter_name": row[5]} for row in cursor.fetchall()]
        cursor.close()
        conn.close()
        return jsonify({"success": True, "staff": list_data})
    except Exception as e: return jsonify({"success": False, "error": str(e)})

# 管理員更新志工
@app.route('/api/admin/update_staff', methods=['POST'])
def admin_update_staff():
    if session.get('staff_role') != '管理員': return jsonify({"success": False, "error": "權限不足！"})
    try:
        req_data = request.get_json()
        target_id, action, new_value = req_data.get('id'), req_data.get('action'), req_data.get('value')
        conn = pyodbc.connect(CONN_STR)
        cursor = conn.cursor()
        if action == 'approve': cursor.execute("UPDATE Staff SET status = N'已啟用' WHERE id = CAST(? AS UNIQUEIDENTIFIER)", (target_id,))
        elif action == 'suspend': cursor.execute("UPDATE Staff SET status = N'已停權' WHERE id = CAST(? AS UNIQUEIDENTIFIER)", (target_id,))
        elif action == 'change_role': cursor.execute("UPDATE Staff SET role = ? WHERE id = CAST(? AS UNIQUEIDENTIFIER)", (new_value, target_id))
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({"success": True, "message": "資料庫資料異動修改成功！"})
    except Exception as e: return jsonify({"success": False, "error": str(e)})

# 【增】上架全新毛孩（雙表對接精簡版）
@app.route('/api/admin/add_animal', methods=['POST'])
def admin_add_animal():
    if session.get('staff_role') != '管理員': 
        return jsonify({"success": False, "error": "權限不足！"})
    try:
        d = request.get_json()
        
        animal_id_val = d['animal_id'].strip()
        if not animal_id_val:
            return jsonify({"success": False, "error": "【系統提示】晶片編號不可為空！"})

        conn = pyodbc.connect(CONN_STR)
        cursor = conn.cursor()

        # 檢查晶片編號是否已存在
        cursor.execute("SELECT COUNT(*) FROM Animal WHERE gov_animal_id = ?", (animal_id_val,))
        if cursor.fetchone()[0] > 0:
            cursor.close()
            conn.close()
            return jsonify({"success": False, "error": f"【系統提示】晶片編號 {animal_id_val} 已存在，請確認是否重複！"})
        
        # 1. 寫入主表 Animal
        cursor.execute("""
            INSERT INTO Animal (
                gov_animal_id, kind, variety, colour, status, sex, age, 
                is_sterilized, is_vaccinated, found_place, shelter_id, is_deleted,
                gov_subid, body_type
            )
            VALUES (?, ?, ?, ?, N'開放', ?, ?, 0, 0, ?, CAST(? AS UNIQUEIDENTIFIER), 0, '---', 'MEDIUM')
        """, (animal_id_val, d['kind'], d['variety'], d['colour'], d['sex'], d['age'], d['found_place'], d['shelter_id']))
        
        # 2. 寫入附表 animal_stage（完整填入所有 NOT NULL 欄位）
        # shelter_name / shelter_address / shelter_tel 存在 animal_stage 本表，不在 Shelter 表
        # 先查出收容所名稱（Shelter 表只有 name）
        cursor.execute("SELECT name FROM Shelter WHERE id = CAST(? AS UNIQUEIDENTIFIER)", (d['shelter_id'],))
        shelter_row = cursor.fetchone()
        s_name = shelter_row[0] if shelter_row else '---'

        cursor.execute("""
            INSERT INTO animal_stage (
                animal_id, animal_subid, animal_area_pkid, animal_shelter_pkid,
                album_file, animal_opendate, animal_title,
                animal_remark, animal_place, animal_kind,
                animal_sex, animal_bodytype,
                animal_sterilization, animal_bacterin, animal_status,
                animal_closeddate, animal_createtime,
                shelter_name, shelter_address, shelter_tel
            )
            VALUES (
                ?, '---', 0, 0,
                ?, GETDATE(), '',
                ?, ?, ?,
                ?, 'MEDIUM',
                ?, N'無', N'開放',
                GETDATE(), GETDATE(),
                ?, '---', '---'
            )
        """, (
            animal_id_val,
            d['album_file'],
            d['remark'], d['found_place'], d['kind'],
            d['sex'],
            '1' if d.get('is_sterilized') else '0',
            s_name
        ))
        
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({"success": True, "message": "🎉 新毛孩上架成功，資料已同步寫入雙表！"})
        
    except Exception as e:
        return jsonify({"success": False, "error": str(e)})
# 【改】修改毛孩規格資料
@app.route('/api/admin/edit_animal', methods=['POST'])
def admin_edit_animal():
    if session.get('staff_role') != '管理員': return jsonify({"success": False, "error": "權限不足！"})
    try:
        d = request.get_json()
        conn = pyodbc.connect(CONN_STR)
        cursor = conn.cursor()
        cursor.execute("""
            UPDATE Animal 
            SET kind=?, variety=?, colour=?, sex=?, age=?, found_place=?, shelter_id=CAST(? AS UNIQUEIDENTIFIER)
            WHERE gov_animal_id=?
        """, (d['kind'], d['variety'], d['colour'], d['sex'], d['age'], d['found_place'], d['shelter_id'], d['animal_id']))
        cursor.execute("""
            UPDATE animal_stage 
            SET album_file=?, animal_remark=?, animal_kind=?, animal_place=?
            WHERE animal_id=?
        """, (d['album_file'], d['remark'], d['kind'], d['found_place'], d['animal_id']))
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({"success": True, "message": "毛孩資料更新成功！"})
    except Exception as e: return jsonify({"success": False, "error": str(e)})

# 【刪】軟刪除下架動物
@app.route('/api/admin/delete_animal', methods=['POST'])
def admin_delete_animal():
    if session.get('staff_role') != '管理員': return jsonify({"success": False, "error": "權限不足！"})
    try:
        d = request.get_json()
        animal_id = d.get('animal_id')
        conn = pyodbc.connect(CONN_STR)
        cursor = conn.cursor()
        cursor.execute("UPDATE Animal SET is_deleted = 1 WHERE gov_animal_id = ?", (animal_id,))
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({"success": True, "message": "⛔ 該毛孩已成功從前台系統火速下架！"})
    except Exception as e: return jsonify({"success": False, "error": str(e)})

if __name__ == '__main__':
    # 🎯 使用全新連接埠 8899，徹底甩開背景舊程式
    app.run(debug=True, port=5000, use_reloader=False)