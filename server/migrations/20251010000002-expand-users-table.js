/* Expand users table to support comprehensive user management
   - Add user_type (user, shipper, vendor, affiliate)
   - Add email, phone, first_name, last_name
   - Add status (active, inactive, suspended)
   - Add profile_data jsonb for flexible additional fields
   - Add updated_at timestamp
   - Add indexes for performance
*/

exports.shorthands = undefined;

exports.up = (pgm) => {
  // Add new columns to users table
  pgm.addColumns('users', {
    user_type: {
      type: 'text',
      notNull: true,
      default: 'user',
      check: "user_type IN ('user', 'shipper', 'vendor', 'affiliate')"
    },
    email: { type: 'text', unique: true },
    phone: { type: 'text' },
    first_name: { type: 'text' },
    last_name: { type: 'text' },
    status: {
      type: 'text',
      notNull: true,
      default: 'active',
      check: "status IN ('active', 'inactive', 'suspended')"
    },
    profile_data: { type: 'jsonb', default: '{}' },
    updated_at: {
      type: 'timestamp',
      notNull: true,
      default: pgm.func('current_timestamp')
    }
  });

  // Create indexes for better query performance
  pgm.createIndex('users', 'user_type');
  pgm.createIndex('users', 'status');
  pgm.createIndex('users', 'email');
  pgm.createIndex('users', ['user_type', 'status']);

  // Update trigger for updated_at
  pgm.sql(`
    CREATE OR REPLACE FUNCTION update_updated_at_column()
    RETURNS TRIGGER AS $$
    BEGIN
      NEW.updated_at = current_timestamp;
      RETURN NEW;
    END;
    $$ language 'plpgsql';
  `);

  pgm.createTrigger('users', 'update_users_updated_at', {
    when: 'BEFORE',
    operation: 'UPDATE',
    function: 'update_updated_at_column',
    level: 'ROW'
  });
};

exports.down = (pgm) => {
  // Remove trigger and function
  pgm.dropTrigger('users', 'update_users_updated_at');
  pgm.sql('DROP FUNCTION IF EXISTS update_updated_at_column();');

  // Drop indexes
  pgm.dropIndex('users', ['user_type', 'status']);
  pgm.dropIndex('users', 'email');
  pgm.dropIndex('users', 'status');
  pgm.dropIndex('users', 'user_type');

  // Drop columns
  pgm.dropColumns('users', [
    'user_type',
    'email',
    'phone',
    'first_name',
    'last_name',
    'status',
    'profile_data',
    'updated_at'
  ]);
};