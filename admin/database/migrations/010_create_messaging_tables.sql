-- Migration: Create messaging tables
-- Description: Chat/messaging system for customer support

CREATE TABLE IF NOT EXISTS conversations (
  id VARCHAR(50) PRIMARY KEY,
  participants VARCHAR(50)[], -- Array of Firebase UIDs
  type VARCHAR(20) DEFAULT 'direct', -- direct, support, group
  title VARCHAR(255),
  last_message TEXT,
  last_message_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS messages (
  id VARCHAR(50) PRIMARY KEY,
  conversation_id VARCHAR(50),
  sender_id VARCHAR(50) NOT NULL, -- Firebase UID
  sender_name VARCHAR(255),
  content TEXT NOT NULL,
  attachments JSONB, -- Array of file URLs
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
);

-- Indexes
CREATE INDEX idx_conversations_participants ON conversations USING GIN(participants);
CREATE INDEX idx_conversations_updated_at ON conversations(updated_at DESC);
CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_created_at ON messages(created_at DESC);

-- Seed test conversations
INSERT INTO conversations (id, participants, type, title, last_message, last_message_at) VALUES
('conv_001', ARRAY['uid_customer_1', 'admin_uid_1'], 'support', 'Order Support - ORD-2025-001', 'Thank you for your help!', CURRENT_TIMESTAMP),
('conv_002', ARRAY['uid_vendor_1', 'admin_uid_1'], 'support', 'Product Approval Request', 'When will my product be approved?', CURRENT_TIMESTAMP),
('conv_003', ARRAY['uid_customer_2', 'uid_vendor_2'], 'direct', 'Product Inquiry', 'Is this item in stock?', CURRENT_TIMESTAMP);

-- Seed test messages
INSERT INTO messages (id, conversation_id, sender_id, sender_name, content, is_read) VALUES
('msg_001', 'conv_001', 'uid_customer_1', 'John Doe', 'Hi, I have a question about my order.', true),
('msg_002', 'conv_001', 'admin_uid_1', 'Support Team', 'Hello! How can I help you today?', true),
('msg_003', 'conv_001', 'uid_customer_1', 'John Doe', 'When will my order be delivered?', true),
('msg_004', 'conv_001', 'admin_uid_1', 'Support Team', 'Your order is expected to arrive by Friday.', true),
('msg_005', 'conv_001', 'uid_customer_1', 'John Doe', 'Thank you for your help!', false),
('msg_006', 'conv_002', 'uid_vendor_1', 'TechGear', 'When will my product be approved?', false),
('msg_007', 'conv_003', 'uid_customer_2', 'Jane Smith', 'Is this item in stock?', false);

COMMENT ON TABLE conversations IS 'Chat conversations between users';
COMMENT ON TABLE messages IS 'Individual messages within conversations';
