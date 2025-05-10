import faker
import numpy as np
from simulate_class import product
'''
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,       -- 商品ID（自增主键）
    product_name VARCHAR(100) NOT NULL,              -- 商品名称
    description TEXT,                                -- 商品描述
    price DECIMAL(10, 2) NOT NULL,                   -- 商品价格
    status ENUM('active', 'inactive') DEFAULT 'active', -- 商品状态
    created_by INT NOT NULL,                         -- 创建者（外键到users）
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,   -- 创建时间
    FOREIGN KEY (created_by) REFERENCES users(user_id)'''
#以字典形式返回
def users(role):
    name=faker.name()
    passwd=faker.password()
    email=faker.email()
    phone=faker.phone_number()
    address=faker.address()
    total_spent=0.00
    return {'role':role,'name':name,'password':passwd,'email':email,'phone':phone,'address':address,'total_spent':total_spent}

def products(cargo_id):
    prod_name=product.prod_name()
    price=product.price()
    






