const admin = require("firebase-admin");

if (!admin.apps.length) {
  const serviceAccount = require("./serviceAccountKey.json");
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}

const auth = admin.auth();
const db   = admin.firestore();

async function crearUsuarioPrueba() {
  const EMAIL    = "luis.manuel.rojas71@gmail.com";
  const PASSWORD = "SafeDrive2026*";

  // ── Conductor ──────────────────────────────────────────────────
  let driverUid;
  try {
    const driverRecord = await auth.createUser({
      email:       EMAIL,
      password:    PASSWORD,
      displayName: "Luis Manuel Rojas",
    });
    driverUid = driverRecord.uid;
    console.log("✅ Usuario Auth creado:", EMAIL);
  } catch (err) {
    if (err.code === "auth/email-already-exists") {
      const existing = await auth.getUserByEmail(EMAIL);
      driverUid = existing.uid;
      console.log("⚠️  Usuario Auth ya existe, usando uid:", driverUid);
    } else {
      throw err;
    }
  }

  // Crear como conductor en Firestore
  await db.collection("users").doc(driverUid).set({
    name:      "Luis Manuel Rojas",
    cedula:    "1234567890",
    email:     EMAIL,
    role:      "driver",
    createdAt: admin.firestore.Timestamp.now(),
  }, { merge: true });
  console.log("✅ Perfil conductor creado en Firestore");

  console.log("\n══════════════════════════════════════════");
  console.log("✅ USUARIO DE PRUEBA LISTO");
  console.log("══════════════════════════════════════════");
  console.log("  Email:      " + EMAIL);
  console.log("  Contraseña: " + PASSWORD);
  console.log("  Rol:        conductor");
  console.log("\n  Para probar recuperación de contraseña:");
  console.log("  1. Abre la app → Login conductor");
  console.log("  2. Toca '¿Olvidaste tu contraseña?'");
  console.log("  3. Ingresa: " + EMAIL);
  console.log("  4. Revisa tu bandeja de entrada");
  console.log("══════════════════════════════════════════");

  process.exit(0);
}

crearUsuarioPrueba().catch(err => {
  console.error("❌ Error:", err.message);
  process.exit(1);
});
