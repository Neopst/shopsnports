-- Migration: Create notifications table
-- Description: User notifications and system alerts

CREATE TABLE IF NOT EXISTS notifications (
  id VARCHAR(50) PRIMARY KEY,
  user_id VARCHAR(50), -- Firebase UID (null for broadcast)
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  type VARCHAR(50) DEFAULT 'info', -- info, success, warning, error, order, product
  action_url VARCHAR(500),
  data JSONB, -- Additional notification data
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  read_at TIMESTAMP
);

-- Indexes
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX idx_notifications_type ON notifications(type);

-- Seed test notifications
INSERT INTO notifications (id, user_id, title, message, type, action_url, is_read) VALUES
('notif_001', 'uid_customer_1', 'Order Shipped', 'Your order #ORD-2025-001 has been shipped!', 'order', '/orders/order_001', true),
('notif_002', 'uid_customer_1', 'Order Delivered', 'Your order has been delivered successfully.', 'success', '/orders/order_001', false),
('notif_003', 'uid_vendor_1', 'New Order Received', 'You have a new order to process.', 'order', '/vendor/orders/order_001', false),
('notif_004', 'uid_customer_2', 'Flash Sale Alert', '50% off on electronics - Limited time!', 'info', '/products?sale=true', false),
('notif_005', NULL, 'System Maintenance', 'Scheduled maintenance this Sunday.', 'warning', NULL, false);

COMMENT ON TABLE notifications IS 'User notifications and system alerts';
