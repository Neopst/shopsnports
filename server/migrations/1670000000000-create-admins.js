/* node-pg-migrate migration to create admins table
   id: timestamped prefix
*/

exports.shorthands = undefined;

exports.up = (pgm) => {
  pgm.createTable('admins', {
    firebase_uid: { type: 'text', primaryKey: true },
    role: { type: 'text', notNull: true, default: 'admin' },
    created_at: { type: 'timestamp', notNull: true, default: pgm.func('current_timestamp') }
  });
};

exports.down = (pgm) => {
  pgm.dropTable('admins');
};
