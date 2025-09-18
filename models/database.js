const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const config = require('../config');

class Database {
    constructor() {
        this.db = null;
    }

    async init() {
        return new Promise((resolve, reject) => {
            this.db = new sqlite3.Database(config.DB_PATH, async (err) => {
                if (err) {
                    console.error('Ошибка подключения к базе данных:', err.message);
                    reject(err);
                } else {
                    console.log('✅ Подключение к базе данных установлено');
                    try {
                        // Проверяем целостность БД
                        await this.checkIntegrity();
                        await this.setPragmas();
                        await this.createTables();
                        await this.createIndices();
                        await this.createFts();
                        await this.optimize();
                        resolve();
                    } catch (error) {
                        reject(error);
                    }
                }
            });
        });
    }

    async checkIntegrity() {
        try {
            const result = await this.get('PRAGMA integrity_check;');
            if (result && result.integrity_check !== 'ok') {
                console.warn('⚠️ Обнаружено повреждение БД при проверке целостности');
                await this.recoverDatabase();
            }
        } catch (error) {
            if (error.code === 'SQLITE_CORRUPT') {
                console.warn('⚠️ БД повреждена, восстанавливаю...');
                await this.recoverDatabase();
            } else {
                throw error;
            }
        }
    }

    async setPragmas() {
        const isWindows = process.platform === 'win32';
        const journalMode = isWindows ? 'DELETE' : 'WAL';
        const pragmas = [
            `PRAGMA journal_mode=${journalMode};`,
            'PRAGMA foreign_keys=ON;',
            'PRAGMA synchronous=NORMAL;',
            'PRAGMA temp_store=MEMORY;',
            'PRAGMA cache_size=-20000;',
            'PRAGMA busy_timeout=5000;'
        ];

        for (const p of pragmas) {
            try {
                await this.run(p);
            } catch (_) {
                // ignore pragma errors for portability
            }
        }
    }

    async optimize() {
        try {
            await this.run('PRAGMA optimize;');
        } catch (_) {}
    }

    async createTables() {
        const tables = [
            // Categories table
            `CREATE TABLE IF NOT EXISTS categories (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                key TEXT UNIQUE NOT NULL,
                name_ru TEXT NOT NULL,
                name_uz TEXT NOT NULL,
                name_en TEXT NOT NULL,
                is_alcoholic BOOLEAN DEFAULT 0,
                order_index INTEGER DEFAULT 0,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )`,

            // Subcategories table
            `CREATE TABLE IF NOT EXISTS subcategories (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                category_id INTEGER NOT NULL,
                key TEXT NOT NULL,
                name_ru TEXT NOT NULL,
                name_uz TEXT NOT NULL,
                name_en TEXT NOT NULL,
                order_index INTEGER DEFAULT 0,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
            )`,

            // Dishes table
            `CREATE TABLE IF NOT EXISTS dishes (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name_ru TEXT NOT NULL,
                name_uz TEXT NOT NULL,
                name_en TEXT NOT NULL,
                category_key TEXT NOT NULL,
                subcategory_key TEXT,
                price INTEGER NOT NULL,
                order_index INTEGER DEFAULT 0,
                image TEXT,
                images TEXT, -- JSON array of image URLs
                composition_ru TEXT,
                composition_uz TEXT,
                composition_en TEXT,
                weight TEXT,
                cooking_time TEXT,
                in_stock BOOLEAN DEFAULT 1,
                is_alcoholic BOOLEAN DEFAULT 0,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (category_key) REFERENCES categories (key) ON DELETE CASCADE
            )`,

            // Settings table
            `CREATE TABLE IF NOT EXISTS settings (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                key TEXT UNIQUE NOT NULL,
                value TEXT NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )`,

            // Admin users table
            `CREATE TABLE IF NOT EXISTS admin_users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT UNIQUE NOT NULL,
                password_hash TEXT NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )`
        ];

        for (const table of tables) {
            await this.run(table);
        }

        // Insert default settings
        await this.insertDefaultSettings();

        // Insert default admin user
        await this.insertDefaultAdmin();
    }

    async createIndices() {
        const indices = [
            'CREATE INDEX IF NOT EXISTS idx_dishes_category_key ON dishes(category_key);',
            'CREATE INDEX IF NOT EXISTS idx_dishes_subcategory_key ON dishes(subcategory_key);',
            'CREATE INDEX IF NOT EXISTS idx_dishes_in_stock ON dishes(in_stock);',
            'CREATE INDEX IF NOT EXISTS idx_dishes_is_alcoholic ON dishes(is_alcoholic);',
            'CREATE INDEX IF NOT EXISTS idx_dishes_order_index ON dishes(order_index);',
            'CREATE INDEX IF NOT EXISTS idx_categories_is_alcoholic ON categories(is_alcoholic);',
            'CREATE INDEX IF NOT EXISTS idx_categories_order_index ON categories(order_index);',
            'CREATE INDEX IF NOT EXISTS idx_subcategories_category_id ON subcategories(category_id);'
        ];

        for (const idx of indices) {
            await this.run(idx);
        }
    }

    async createFts() {
        // Пытаемся создать FTS5 виртуальную таблицу для быстрого поиска
        // Если FTS5 не поддерживается сборкой SQLite, ошибки игнорируем
        const statements = [
            `CREATE VIRTUAL TABLE IF NOT EXISTS dishes_fts USING fts5(
                name_ru, name_uz, name_en,
                composition_ru, composition_uz, composition_en,
                content='dishes', content_rowid='id'
            );`,
            // Инициальная синхронизация
            `INSERT INTO dishes_fts(dishes_fts, rowid, name_ru, name_uz, name_en, composition_ru, composition_uz, composition_en)
             SELECT 'insert', id, name_ru, name_uz, name_en, composition_ru, composition_uz, composition_en FROM dishes
             WHERE NOT EXISTS(SELECT 1 FROM dishes_fts WHERE rowid = dishes.id);`,
            // Триггеры синхронизации
            `CREATE TRIGGER IF NOT EXISTS dishes_ai AFTER INSERT ON dishes BEGIN
                INSERT INTO dishes_fts(rowid, name_ru, name_uz, name_en, composition_ru, composition_uz, composition_en)
                VALUES (new.id, new.name_ru, new.name_uz, new.name_en, new.composition_ru, new.composition_uz, new.composition_en);
            END;`,
            `CREATE TRIGGER IF NOT EXISTS dishes_ad AFTER DELETE ON dishes BEGIN
                INSERT INTO dishes_fts(dishes_fts, rowid, name_ru, name_uz, name_en, composition_ru, composition_uz, composition_en)
                VALUES('delete', old.id, old.name_ru, old.name_uz, old.name_en, old.composition_ru, old.composition_uz, old.composition_en);
            END;`,
            `CREATE TRIGGER IF NOT EXISTS dishes_au AFTER UPDATE ON dishes BEGIN
                INSERT INTO dishes_fts(dishes_fts, rowid, name_ru, name_uz, name_en, composition_ru, composition_uz, composition_en)
                VALUES('delete', old.id, old.name_ru, old.name_uz, old.name_en, old.composition_ru, old.composition_uz, old.composition_en);
                INSERT INTO dishes_fts(rowid, name_ru, name_uz, name_en, composition_ru, composition_uz, composition_en)
                VALUES (new.id, new.name_ru, new.name_uz, new.name_en, new.composition_ru, new.composition_uz, new.composition_en);
            END;`
        ];

        for (const stmt of statements) {
            try {
                await this.run(stmt);
            } catch (e) {
                // Игнорируем, если FTS5 недоступен
                break;
            }
        }
    }

    async insertDefaultSettings() {
        const settings = [
            { key: 'service_charge', value: '10' },
            { key: 'restaurant_mode', value: 'public' }
        ];

        for (const setting of settings) {
            await this.run(
                'INSERT OR IGNORE INTO settings (key, value) VALUES (?, ?)',
                [setting.key, setting.value]
            );
        }
    }

    async insertDefaultAdmin() {
        const bcrypt = require('bcryptjs');
        const hashedPassword = await bcrypt.hash(config.ADMIN_PASSWORD, 10);

        await this.run(
            'INSERT OR IGNORE INTO admin_users (username, password_hash) VALUES (?, ?)',
            [config.ADMIN_USERNAME, hashedPassword]
        );
    }

    async run(sql, params = []) {
        return new Promise((resolve, reject) => {
            this.db.run(sql, params, async (err) => {
                if (err) {
                    // Если ошибка SQLITE_CORRUPT, попробуем восстановить БД
                    if (err.code === 'SQLITE_CORRUPT') {
                        console.warn('⚠️ Обнаружено повреждение БД, пытаюсь восстановить...');
                        try {
                            await this.recoverDatabase();
                            // Повторяем запрос после восстановления
                            this.db.run(sql, params, (retryErr) => {
                                if (retryErr) {
                                    console.error('❌ Ошибка после восстановления БД:', retryErr.message);
                                    reject(retryErr);
                                } else {
                                    resolve({ id: this.lastID, changes: this.changes });
                                }
                            });
                        } catch (recoverErr) {
                            console.error('❌ Не удалось восстановить БД:', recoverErr.message);
                            reject(err);
                        }
                    } else {
                        reject(err);
                    }
                } else {
                    resolve({ id: this.lastID, changes: this.changes });
                }
            });
        });
    }

    get(sql, params = []) {
        return new Promise((resolve, reject) => {
            this.db.get(sql, params, (err, row) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(row);
                }
            });
        });
    }

    all(sql, params = []) {
        return new Promise((resolve, reject) => {
            this.db.all(sql, params, (err, rows) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(rows);
                }
            });
        });
    }

    async recoverDatabase() {
        const fs = require('fs');
        const path = require('path');

        try {
            // Закрываем текущее соединение
            await this.close();

            const dbPath = config.DB_PATH;
            const backupDir = path.join(__dirname, '..', 'backups');
            const dataDir = path.dirname(dbPath);

            // Ищем самый свежий бэкап
            let latestBackup = null;
            if (fs.existsSync(backupDir)) {
                const backups = fs.readdirSync(backupDir)
                    .filter(f => f.endsWith('.sqlite'))
                    .map(f => ({
                        name: f,
                        path: path.join(backupDir, f),
                        time: fs.statSync(path.join(backupDir, f)).mtime.getTime()
                    }))
                    .sort((a, b) => b.time - a.time);

                if (backups.length > 0) {
                    latestBackup = backups[0];
                }
            }

            if (latestBackup) {
                console.log(`🔄 Восстанавливаю БД из бэкапа: ${latestBackup.name}`);
                fs.copyFileSync(latestBackup.path, dbPath);
            } else {
                console.log('⚠️ Бэкапы не найдены, создаю новую БД');
                if (fs.existsSync(dbPath)) {
                    fs.unlinkSync(dbPath);
                }
            }

            // Пересоздаем соединение
            await this.init();
            console.log('✅ БД восстановлена и переподключена');

        } catch (error) {
            console.error('❌ Ошибка восстановления БД:', error.message);
            throw error;
        }
    }

    close() {
        return new Promise((resolve) => {
            if (this.db) {
                this.db.close((err) => {
                    if (err) {
                        console.error('Ошибка закрытия базы данных:', err.message);
                    } else {
                        console.log('✅ Соединение с базой данных закрыто');
                    }
                    resolve();
                });
            } else {
                resolve();
            }
        });
    }
}

module.exports = new Database();
