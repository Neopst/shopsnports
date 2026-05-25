-- Migration: Create news_ticker table
-- Description: News ticker items (migrated from Firestore)

CREATE TABLE IF NOT EXISTS news_ticker (
  id VARCHAR(50) PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  image_url VARCHAR(500),
  priority INT DEFAULT 0, -- Higher number = higher priority
  status VARCHAR(20) DEFAULT 'draft', -- draft, published, archived
  expires_at TIMESTAMP,
  view_count INT DEFAULT 0,
  created_by VARCHAR(50), -- Admin UID from Firebase
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  published_at TIMESTAMP
);

-- Indexes
CREATE INDEX idx_news_status ON news_ticker(status);
CREATE INDEX idx_news_priority ON news_ticker(priority DESC);
CREATE INDEX idx_news_created_at ON news_ticker(created_at DESC);
CREATE INDEX idx_news_published_at ON news_ticker(published_at DESC);

-- Seed test news items
INSERT INTO news_ticker (id, title, content, image_url, priority, status, view_count, created_by, published_at) VALUES
('news_001', 'New Product Arrivals!', 'Check out our latest collection of electronics and accessories.', 'https://via.placeholder.com/600x200', 10, 'published', 1250, 'admin_uid_1', CURRENT_TIMESTAMP),
('news_002', 'Flash Sale - 50% OFF', 'Limited time offer on selected items. Shop now!', 'https://via.placeholder.com/600x200', 20, 'published', 3500, 'admin_uid_1', CURRENT_TIMESTAMP),
('news_003', 'Free Shipping Weekend', 'Get free shipping on all orders this weekend only.', 'https://via.placeholder.com/600x200', 15, 'published', 890, 'admin_uid_1', CURRENT_TIMESTAMP),
('news_004', 'Upcoming Maintenance', 'Scheduled maintenance on Sunday 2AM-4AM EST.', NULL, 5, 'published', 450, 'admin_uid_1', CURRENT_TIMESTAMP),
('news_005', 'Draft News Item', 'This is a draft news item not yet published.', NULL, 0, 'draft', 0, 'admin_uid_1', NULL);

COMMENT ON TABLE news_ticker IS 'News ticker items for homepage and announcements';
