/**
 * SEED — SafeDrive AI
 * 
 * Crea en Firebase:
 *   - 2 empresas de prueba (con sus cuentas en Authentication)
 *   - 1 conductor de prueba  (con su cuenta en Authentication)
 *   - 2 vínculos activos conductor ↔ empresa en `company_drivers`
 * 
 * REQUISITOS:
 *   node >= 18
 *   npm install firebase-admin
 * 
 * CÓMO OBTENER serviceAccountKey.json:
 *   Firebase Console → Configuración del proyecto →
 *   Cuentas de servicio → Generar nueva clave privada
 * 
 * USO:
 *   node seed_test_data.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json'); // ← coloca el archivo aquí

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const auth = admin.auth();
const db   = admin.firestore();

// ── Datos de prueba ────────────────────────────────────────────────────────────

const EMPRESA_1 = {
  email:               'empresa1.prueba@safedrive.com',
  password:            'SafeDrive123*',
  name:                'Transportes del Valle S.A.',
  nit:                 '900123456-1',
  representativeName:  'Carlos Pérez',
};

const EMPRESA_2 = {
  email:               'empresa2.prueba@safedrive.com',
  password:            'SafeDrive123*',
  name:                'Logística Andina Ltda.',
  nit:                 '900654321-2',
  representativeName:  'María González',
};

const CONDUCTOR = {
  email:    'conductor.prueba@safedrive.com',
  password: 'SafeDrive123*',
  name:     'Juan Prueba',
  cedula:   '1234567890',
  cargo:    'Conductor',
  phone:    '3001234567',
};

// ── Helpers ────────────────────────────────────────────────────────────────────

async function createOrGetUser(email, password) {
  try {
    const existing = await auth.getUserByEmail(email);
    console.log(`  ↩  Usuario ya existe: ${email} (uid: ${existing.uid})`);
    return existing.uid;
  } catch {
    const created = await auth.createUser({ email, password });
    console.log(`  ✓  Usuario creado:    ${email} (uid: ${created.uid})`);
    return created.uid;
  }
}

async function seedEmpresa(empresa) {
  const uid = await createOrGetUser(empresa.email, empresa.password);

  await db.collection('companies').doc(uid).set({
    name:                empresa.name,
    nit:                 empresa.nit,
    email:               empresa.email,
    representativeName:  empresa.representativeName,
    role:                'company',
    createdAt:           admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  console.log(`  ✓  Firestore companies/${uid} → ${empresa.name}`);
  return uid;
}

async function seedConductor(conductor) {
  const uid = await createOrGetUser(conductor.email, conductor.password);

  await db.collection('users').doc(uid).set({
    name:      conductor.name,
    cedula:    conductor.cedula,
    email:     conductor.email,
    role:      'driver',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  console.log(`  ✓  Firestore users/${uid} → ${conductor.name}`);
  return uid;
}

async function seedVinculo(driverId, companyId, companyName, cargo, phone) {
  const query = await db.collection('company_drivers')
    .where('driverId',  '==', driverId)
    .where('companyId', '==', companyId)
    .where('status',    '==', 'active')
    .limit(1)
    .get();

  if (!query.empty) {
    console.log(`  ↩  Vínculo ya existe: conductor → ${companyName}`);
    return;
  }

  const ref = await db.collection('company_drivers').add({
    driverId:  driverId,
    companyId: companyId,
    cargo:     cargo,
    phone:     phone,
    status:    'active',
    linkedAt:  admin.firestore.FieldValue.serverTimestamp(),
    unlinkedAt: null,
  });

  console.log(`  ✓  Vínculo creado (${ref.id}): conductor → ${companyName}`);
}

// ── Main ───────────────────────────────────────────────────────────────────────

async function main() {
  console.log('\n🌱  Iniciando seed de SafeDrive AI...\n');

  console.log('📦  Empresa 1:');
  const empresa1Id = await seedEmpresa(EMPRESA_1);

  console.log('\n📦  Empresa 2:');
  const empresa2Id = await seedEmpresa(EMPRESA_2);

  console.log('\n🚗  Conductor:');
  const conductorId = await seedConductor(CONDUCTOR);

  console.log('\n🔗  Vínculos:');
  await seedVinculo(conductorId, empresa1Id, EMPRESA_1.name, CONDUCTOR.cargo, CONDUCTOR.phone);
  await seedVinculo(conductorId, empresa2Id, EMPRESA_2.name, CONDUCTOR.cargo, CONDUCTOR.phone);

  console.log('\n✅  Seed completado.\n');
  console.log('──────────────────────────────────────────');
  console.log('  CREDENCIALES PARA PROBAR EN LA APP:');
  console.log('──────────────────────────────────────────');
  console.log(`  Conductor:  ${CONDUCTOR.email}`);
  console.log(`  Contraseña: ${CONDUCTOR.password}`);
  console.log('──────────────────────────────────────────\n');

  process.exit(0);
}

main().catch((err) => {
  console.error('\n❌  Error en el seed:', err);
  process.exit(1);
});
