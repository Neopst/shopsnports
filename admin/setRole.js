// admin/setRole.js   <-- NEW FILE

// Node.js script to assign a role to a Firebase user.
// Run: node admin/setRole.js <UID> <ROLE>

const admin = require("firebase-admin");
admin.initializeApp();

async function setRole(uid, role) {
  const allowed = ["admin", "vendor", "shipper", "affiliate"];
  if (!allowed.includes(role)) {
    throw new Error(`Invalid role "${role}". Allowed: ${allowed.join(", ")}`);
  }
  await admin.auth().setCustomUserClaims(uid, { role });
  console.log(`Role "${role}" set for UID: ${uid}`);
}

const [uid, role] = process.argv.slice(2);
if (!uid || !role) {
  console.error("Usage: node admin/setRole.js <UID> <ROLE>");
  process.exit(1);
}

setRole(uid, role)
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });