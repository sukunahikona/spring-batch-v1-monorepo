-- ユーザーテストデータ
INSERT INTO users (name, email, status) VALUES
('田中太郎', 'tanaka@example.com', 'ACTIVE'),
('佐藤花子', 'sato@example.com', 'ACTIVE'),
('鈴木一郎', 'suzuki@example.com', 'INACTIVE'),
('高橋美咲', 'takahashi@example.com', 'ACTIVE'),
('渡辺健太', 'watanabe@example.com', 'ACTIVE')
ON CONFLICT (email) DO NOTHING;

-- 商品テストデータ
INSERT INTO products (product_code, product_name, price, stock_quantity, is_available) VALUES
('P001', 'ノートパソコン', 89800.00, 50, true),
('P002', 'ワイヤレスマウス', 2980.00, 200, true),
('P003', 'USBメモリ 64GB', 1280.00, 150, true),
('P004', 'モニター 24インチ', 25800.00, 30, true),
('P005', 'キーボード', 5980.00, 80, false)
ON CONFLICT (product_code) DO NOTHING;

-- 注文テストデータ
INSERT INTO orders (user_id, product_id, quantity, total_amount, order_status) VALUES
(1, 1, 1, 89800.00, 'COMPLETED'),
(1, 2, 2, 5960.00, 'COMPLETED'),
(2, 3, 3, 3840.00, 'PENDING'),
(3, 4, 1, 25800.00, 'CANCELLED'),
(4, 1, 1, 89800.00, 'SHIPPED'),
(5, 2, 1, 2980.00, 'PENDING')
ON CONFLICT DO NOTHING;