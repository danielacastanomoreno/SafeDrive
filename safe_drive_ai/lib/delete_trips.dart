import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('Intentando borrar todos los viajes y limpiar SharedPreferences...');
  
  try {
    // 1. Limpiar SharedPreferences local
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('SharedPreferences limpiado exitosamente.');

    // 2. Limpiar Firestore
    final firestore = FirebaseFirestore.instance;
    final tripsSnapshot = await firestore.collection('trips').get();
    
    int count = 0;
    
    for (final doc in tripsSnapshot.docs) {
      // Borrar subcolección route_points primero si existen muchos
      final routePoints = await doc.reference.collection('route_points').get();
      for (final rp in routePoints.docs) {
        await rp.reference.delete();
      }
      
      await doc.reference.delete();
      count++;
    }
    
    print('Se borraron \$count viajes exitosamente de Firestore.');
  } catch (e) {
    print('Error borrando viajes: \$e');
  }
  
  print('Fin del script. Puedes cerrar esta app y abrir la principal.');
}
