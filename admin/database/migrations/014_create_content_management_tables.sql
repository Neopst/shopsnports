-- Migration: Create content management tables
-- Description: Banners, announcements, and promotional content

-- Content posts table (for ads, banners, announcements)
CREATE TABLE IF NOT EXISTS content_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Content type
  content_type VARCHAR(50) NOT NULL CHECK (content_type IN (
    'banner', 'announcement', 'promotion', 'ad', 'notification_template'
  )),
  
  -- Basic info
  title VARCHAR(255) NOT NULL,
  subtitle VARCHAR(255),
  description TEXT,
  
  -- Media
  image_url TEXT,
  video_url TEXT,
  thumbnail_url TEXT,
  
  -- Link/action
  action_type VARCHAR(50),  -- 'url', 'product', 'category', 'vendor', 'none'
  action_value TEXT,  -- The URL, product ID, category ID, etc.
  
  -- Display settings
  position VARCHAR(50),  -- 'home_top', 'home_middle', 'category_page', etc.
  display_order INTEGER DEFAULT 0,
  
  -- Targeting
  target_audience VARCHAR(50) DEFAULT 'all' CHECK (target_audience IN (
    'all', 'customers', 'vendors', 'affiliates', 'shippers'
  )),
  
  -- Scheduling
  start_date TIMESTAMP,
  end_date TIMESTAMP,
  
  -- Status
  status VARCHAR(50) NOT NULL DEFAULT 'draft' CHECK (status IN (
    'draft', 'pending_approval', 'approved', 'published', 'expired', 'archived'
  )),
  
  -- Metrics
  view_count INTEGER DEFAULT 0,
  click_count INTEGER DEFAULT 0,
  
  -- Audit
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID,
  approved_by UUID,
  approved_at TIMESTAMP,
  published_at TIMESTAMP
);

-- Notification templates table
CREATE TABLE IF NOT EXISTS notification_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Template identity
  template_key VARCHAR(100) UNIQUE NOT NULL,  -- e.g., 'order_shipped', 'payout_processed'
  template_name VARCHAR(255) NOT NULL,
  category VARCHAR(50) NOT NULL,  -- 'order', 'shipping', 'payout', 'account', etc.
  
  -- Content
  subject VARCHAR(255),
  body_template TEXT NOT NULL,  -- Supports placeholders like {{customer_name}}, {{order_number}}
  push_title VARCHAR(255),
  push_body TEXT,
  
  -- Channels
  supports_email BOOLEAN DEFAULT false,
  supports_push BOOLEAN DEFAULT false,
  supports_sms BOOLEAN DEFAULT false,
  supports_in_app BOOLEAN DEFAULT false,
  
  -- Targeting
  recipient_type VARCHAR(50) NOT NULL,  -- 'customer', 'vendor', 'affiliate', 'shipper', 'admin'
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  
  -- Audit
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID
);

-- Sent notifications log (for tracking)
CREATE TABLE IF NOT EXISTS sent_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Notification details
  template_id UUID REFERENCES notification_templates(id),
  template_key VARCHAR(100),
  
  -- Recipient
  recipient_type VARCHAR(50) NOT NULL,
  recipient_id UUID NOT NULL,
  recipient_email VARCHAR(255),
  recipient_phone VARCHAR(50),
  
  -- Channel used
  channel VARCHAR(20) NOT NULL CHECK (channel IN ('email', 'push', 'sms', 'in_app')),
  
  -- Content sent
  subject VARCHAR(255),
  body TEXT,
  
  -- Status
  status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN (
    'pending', 'sent', 'delivered', 'failed', 'bounced'
  )),
  
  -- Metadata
  sent_at TIMESTAMP,
  delivered_at TIMESTAMP,
  read_at TIMESTAMP,
  error_message TEXT,
  
  -- Reference (what triggered this notification)
  reference_type VARCHAR(50),
  reference_id UUID,
  
  -- Audit
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID
);

-- Indexes
CREATE INDEX idx_content_posts_type ON content_posts(content_type);
CREATE INDEX idx_content_posts_status ON content_posts(status);
CREATE INDEX idx_content_posts_dates ON content_posts(start_date, end_date);
CREATE INDEX idx_content_posts_position ON content_posts(position, display_order);
CREATE INDEX idx_notification_templates_key ON notification_templates(template_key);
CREATE INDEX idx_notification_templates_category ON notification_templates(category);
CREATE INDEX idx_sent_notifications_recipient ON sent_notifications(recipient_type, recipient_id);
CREATE INDEX idx_sent_notifications_status ON sent_notifications(status);
CREATE INDEX idx_sent_notifications_created ON sent_notifications(created_at DESC);

-- Sample notification templates
INSERT INTO notification_templates (
  template_key, template_name, category, subject, body_template, 
  supports_email, supports_push, recipient_type, is_active
) VALUES
('order_placed', 'Order Placed Confirmation', 'order', 
 'Order {{order_number}} Received', 
 'Dear {{customer_name}}, Your order #{{order_number}} has been placed successfully. Total: {{total_amount}}.',
 true, true, 'customer', true),
 
('order_shipped', 'Order Shipped Notification', 'order',
 'Order {{order_number}} Shipped',
 'Your order #{{order_number}} has been shipped. Tracking: {{tracking_number}}',
 true, true, 'customer', true),
 
('shipping_approved', 'Shipping Request Approved', 'shipping',
 'Shipping Request {{request_number}} Approved',
 'Your shipping request #{{request_number}} has been approved. Estimated cost: {{estimated_cost}}',
 true, true, 'shipper', true),
 
('payout_processed', 'Payout Processed', 'payout',
 'Payout {{payout_number}} Completed',
 'Your payout of {{amount}} has been processed and will arrive in 3-5 business days.',
 true, true, 'vendor', true);

-- Sample content posts
INSERT INTO content_posts (
  content_type, title, description, image_url, position, 
  target_audience, status, display_order, start_date
) VALUES
('banner', 'Welcome to ShopsNSports!', 
 'Your one-stop marketplace for products and shipping', 
 '/banners/welcome.jpg', 'home_top', 'all', 'published', 1, CURRENT_TIMESTAMP),
 
('announcement', 'New Shipping Routes Available', 
 'We now offer air and sea shipping to 50+ countries',
 '/announcements/shipping.jpg', 'home_middle', 'all', 'published', 2, CURRENT_TIMESTAMP);

COMMENT ON TABLE content_posts IS 'Banners, announcements, and promotional content';
COMMENT ON TABLE notification_templates IS 'Reusable notification templates with placeholders';
COMMENT ON TABLE sent_notifications IS 'Log of all sent notifications for tracking';
