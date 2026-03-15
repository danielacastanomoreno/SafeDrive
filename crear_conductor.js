const admin = require("firebase-admin");

if (!admin.apps.length) {
  const serviceAccount = require("./serviceAccountKey.json");
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}

const auth = admin.auth();
const db   = admin.firestore();

async function crearConductor() {
  const conductor = {
    email:    "pedro.ramirez@gmail.com",
    password: "SafeDrive2026*",
    name:     "Pedro Ramírez Torres",
    cedula:   "1045678901",
    role:     "driver",
  };

  // 1. Crear en Firebase Auth
  const userRecord = await auth.createUser({
    email:       conductor.email,
    password:    conductor.password,
    displayName: conductor.name,
  });

  // 2. Crear en Firestore
  await db.collection("users").doc(userRecord.uid).set({
    name:      conductor.name,
    cedula:    conductor.cedula,
    email:     conductor.email,
    role:      conductor.role,
    createdAt: admin.firestore.Timestamp.now(),
  });

  console.log("✅ Conductor creado exitosamente\n");
  console.log("   Nombre:     " + conductor.name);
  console.log("   Cédula:     " + conductor.cedula);
  console.log("   Email:      " + conductor.email);
  console.log("   Contraseña: " + conductor.password);
  console.log("\nUsa la cédula para invitarlo desde la app de empresa.");

  process.exit(0);
}

crearConductor().catch(err => {
  console.error("❌ Error:", err.message);
  process.exit(1);
});
