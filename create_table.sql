-- 创建数据库Schema
CREATE SCHEMA IF NOT EXISTS `e_commerce_db` DEFAULT CHARACTER SET utf8mb4;
USE `e_commerce_db`;
-- E-commerce Database Schema v1.0
-- 包含完整表结构、触发器、视图及关系说明

-- ----------------------------
-- 用户表（含角色区分）
-- ----------------------------
CREATE TABLE IF NOT EXISTS users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('boss', 'product_manager', 'transaction_manager', 'customer') NOT NULL,
    email VARCHAR(100),
    phone VARCHAR(20),
    address TEXT,
    total_spent DECIMAL(15, 2) DEFAULT 0.00,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- 商品表
-- ----------------------------
CREATE TABLE IF NOT EXISTS products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    status ENUM('active', 'inactive') DEFAULT 'active',
    created_by INT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- 库存表（与商品1:1关系）
-- ----------------------------
CREATE TABLE IF NOT EXISTS inventory (
    product_id INT PRIMARY KEY,
    quantity INT NOT NULL DEFAULT 0,
    low_stock_threshold INT DEFAULT 10,
    last_restocked DATETIME,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- 交易表（含完整状态跟踪）
-- ----------------------------
CREATE TABLE IF NOT EXISTS transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    payment_status ENUM('pending', 'completed', 'refunded') DEFAULT 'pending',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- 交易明细表（支持数据分析）
-- ----------------------------
CREATE TABLE IF NOT EXISTS transaction_details (
    detail_id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    discount_applied DECIMAL(5, 2) DEFAULT 0.00,
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- 补贴政策表（面向商家）
-- ----------------------------
CREATE TABLE IF NOT EXISTS subsidy_policies (
    policy_id INT AUTO_INCREMENT PRIMARY KEY,
    policy_name VARCHAR(100) NOT NULL,
    threshold DECIMAL(15, 2) NOT NULL,
    subsidy_amount DECIMAL(10, 2) NOT NULL,
    cycle_type ENUM('once', 'monthly'),
    start_date DATE NOT NULL,
    end_date DATE,
    created_by INT NOT NULL,
    FOREIGN KEY (created_by) REFERENCES users(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- 折扣政策表（面向客户）
-- ----------------------------
CREATE TABLE IF NOT EXISTS discount_policies (
    policy_id INT AUTO_INCREMENT PRIMARY KEY,
    policy_name VARCHAR(100) NOT NULL,
    threshold DECIMAL(15, 2) NOT NULL,
    discount_rate DECIMAL(5, 2) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    created_by INT NOT NULL,
    FOREIGN KEY (created_by) REFERENCES users(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- 审计日志表
-- ----------------------------
CREATE TABLE IF NOT EXISTS audit_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    action_type ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    table_name VARCHAR(50) NOT NULL,
    record_id INT NOT NULL,
    old_value JSON,
    new_value JSON,
    performed_by VARCHAR(50) NOT NULL,
    action_time DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- 数据分析视图
-- ----------------------------
CREATE OR REPLACE VIEW sales_analysis_view AS
SELECT 
    p.product_id,
    p.product_name,
    SUM(td.quantity) AS total_sold,
    SUM(td.quantity * td.unit_price) AS total_revenue,
    AVG(td.unit_price) AS avg_selling_price
FROM transaction_details td
JOIN products p USING (product_id)
GROUP BY p.product_id;

-- ----------------------------
-- 触发器定义
-- ----------------------------
DELIMITER //

CREATE TRIGGER update_inventory_after_purchase
AFTER INSERT ON transaction_details
FOR EACH ROW
BEGIN
    UPDATE inventory 
    SET quantity = quantity - NEW.quantity,
        last_restocked = IF(quantity - NEW.quantity < low_stock_threshold, NOW(), last_restocked)
    WHERE product_id = NEW.product_id;
END//

CREATE TRIGGER update_user_spending
AFTER UPDATE ON transactions
FOR EACH ROW
BEGIN
    IF NEW.payment_status = 'completed' AND OLD.payment_status != 'completed' THEN
        UPDATE users
        SET total_spent = total_spent + NEW.total_amount
        WHERE user_id = NEW.user_id;
    END IF;
END//

CREATE TRIGGER audit_price_changes
AFTER UPDATE ON products
FOR EACH ROW
BEGIN
    IF OLD.price != NEW.price THEN
        INSERT INTO audit_logs (action_type, table_name, record_id, old_value, new_value, performed_by)
        VALUES ('UPDATE', 'products', NEW.product_id,
               JSON_OBJECT('price', OLD.price),
               JSON_OBJECT('price', NEW.price),
               CURRENT_USER());
    END IF;
END//

DELIMITER ;

-- ----------------------------
-- 关系说明注释
-- ----------------------------
/*
1. 核心业务关系：
   - 商品 ←→ 库存 (1:1)
   - 用户 → 交易 (1:N)
   - 交易 → 交易明细 (1:N)

2. 政策管理：
   - 补贴政策 → 用户（创建者）
   - 折扣政策 → 用户（创建者）

3. 审计跟踪：
   - 所有价格变更记录到审计日志
   - 自动库存预警更新
   - 消费金额自动累计
*/

-- 初始化提交版本：v1.0-base-schema