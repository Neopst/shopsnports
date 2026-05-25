-- Migration: Create admin management tables
-- Description: Multi-admin support with roles and activity logging

-- Admin users table
CREATE TABLE IF NOT EXISTS admin_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Firebase Auth UID
  firebase_uid VARCHAR(255) UNIQUE NOT NULL,
  
  -- Profile
  email VARCHAR(255) UNIQUE NOT NULL,
  display_name VARCHAR(255) NOT NULL,
  phone_number VARCHAR(50),
  profile_photo_url TEXT,
  
  -- Role
  role VARCHAR(50) NOT NULL DEFAULT 'admin' CHECK (role IN (
    'super_admin', 'admin', 'finance_admin', 'support_admin', 'content_admin', 'viewer'
  )),
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  is_email_verified BOOLEAN DEFAULT false,
  last_login_at TIMESTAMP,
  
  -- Security
  two_factor_enabled BOOLEAN DEFAULT false,
  
  -- Audit
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID,
  deactivated_at TIMESTAMP,
  deactivated_by UUID
);

-- Admin roles and permissions table
CREATE TABLE IF NOT EXISTS admin_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  role_name VARCHAR(50) UNIQUE NOT NULL,
  display_name VARCHAR(100) NOT NULL,
  description TEXT,
  
  -- Permissions (JSON array of permission strings)
  permissions JSONB NOT NULL DEFAULT '[]'::jsonb,
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  is_system_role BOOLEAN DEFAULT false,  -- Cannot be deleted
  
  -- Audit
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID
);

-- Admin activity logs table
CREATE TABLE IF NOT EXISTS admin_activity_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Admin who performed action
  admin_id UUID NOT NULL REFERENCES admin_users(id),
  admin_email VARCHAR(255) NOT NULL,
  
  -- Action details
  action_type VARCHAR(100) NOT NULL,  -- e.g., 'create_vendor', 'approve_product', 'process_payout'
  action_category VARCHAR(50) NOT NULL,  -- e.g., 'vendor_management', 'financial', 'shipping'
  
  -- Target entity
  entity_type VARCHAR(50),  -- e.g., 'vendor', 'product', 'payout'
  entity_id UUID,
  
  -- Details
  description TEXT NOT NULL,
  metadata JSONB,  -- Additional context (old values, new values, etc.)
  
  -- Request info
  ip_address VARCHAR(45),
  user_agent TEXT,
  
  -- Timestamp
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Admin sessions table (for security tracking)
CREATE TABLE IF NOT EXISTS admin_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  admin_id UUID NOT NULL REFERENCES admin_users(id),
  
  -- Session details
  session_token VARCHAR(255) UNIQUE NOT NULL,
  ip_address VARCHAR(45),
  user_agent TEXT,
  location_info JSONB,  -- Country, city, etc.
  
  -- Timestamps
  started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_activity_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  ended_at TIMESTAMP,
  
  -- Status
  is_active BOOLEAN DEFAULT true
);

-- Indexes
CREATE INDEX idx_admin_users_firebase_uid ON admin_users(firebase_uid);
CREATE INDEX idx_admin_users_email ON admin_users(email);
CREATE INDEX idx_admin_users_role ON admin_users(role);
CREATE INDEX idx_admin_users_active ON admin_users(is_active);
CREATE INDEX idx_admin_activity_admin ON admin_activity_logs(admin_id);
CREATE INDEX idx_admin_activity_type ON admin_activity_logs(action_type);
CREATE INDEX idx_admin_activity_entity ON admin_activity_logs(entity_type, entity_id);
CREATE INDEX idx_admin_activity_created ON admin_activity_logs(created_at DESC);
CREATE INDEX idx_admin_sessions_admin ON admin_sessions(admin_id);
CREATE INDEX idx_admin_sessions_active ON admin_sessions(is_active);

-- Insert default roles
INSERT INTO admin_roles (role_name, display_name, description, permissions, is_system_role) VALUES
('super_admin', 'Super Administrator', 'Full system access with all permissions', 
 '["*"]'::jsonb, true),
 
('admin', 'Administrator', 'General admin access to most features',
 '["manage_vendors", "manage_products", "manage_orders", "manage_customers", "manage_shipping", "view_analytics"]'::jsonb, true),
 
('finance_admin', 'Finance Administrator', 'Financial operations only',
 '["manage_payouts", "manage_commissions", "manage_taxes", "view_transactions", "view_analytics"]'::jsonb, true),
 
('support_admin', 'Support Administrator', 'Customer and order support',
 '["manage_orders", "manage_customers", "manage_shipping", "send_notifications"]'::jsonb, true),
 
('content_admin', 'Content Administrator', 'Content and marketing management',
 '["manage_content", "manage_news", "send_notifications", "manage_categories"]'::jsonb, true),
 
('viewer', 'Viewer', 'Read-only access to dashboards and reports',
 '["view_analytics", "view_orders", "view_vendors", "view_customers"]'::jsonb, true);

COMMENT ON TABLE admin_users IS 'Admin user accounts with Firebase authentication';
COMMENT ON TABLE admin_roles IS 'Admin role definitions with permissions';
COMMENT ON TABLE admin_activity_logs IS 'Audit trail of all admin actions';
COMMENT ON TABLE admin_sessions IS 'Active admin sessions for security tracking';
