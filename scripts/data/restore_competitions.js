// Script para restaurar competiciones, eventos y participantes en Firestore
// Ejecutar con: node scripts/data/restore_competitions.js

const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

function printMessage(message) {
  console.log(message);
}

function initializeFirebase() {
  if (admin.apps.length) return;

  const serviceAccountPath = path.resolve(
    process.cwd(),
    'firebase-service-account.json',
  );

  if (fs.existsSync(serviceAccountPath)) {
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      databaseURL: 'https://the-final-burger-default-rtdb.firebaseio.com',
    });
    return;
  }

  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    databaseURL: 'https://the-final-burger-default-rtdb.firebaseio.com',
  });
}

initializeFirebase();

const db = admin.firestore();

async function restoreCompetitions() {
  try {
    printMessage('🔄 Iniciando restauración de competiciones y eventos...');

    const competitions = [
      {
        id: 'champions_burger',
        name: 'Champions Burger',
        description: 'La competición de hamburguesas más importante de Europa. ¡Descubre las mejores burgers en distintas ciudades!',
        startDate: new Date('2024-07-01'),
        endDate: new Date('2024-09-30'),
        status: 'active',
        imageUrl: 'assets/images/thechampionsburger.jpg',
        totalEvents: 3,
        currentEventId: null,
        createdAt: new Date(),
        updatedAt: new Date(),
        events: [
          {
            name: 'Champions Burger Madrid',
            location: 'Madrid',
            address: 'Parque Juan Carlos I, Madrid',
            coordinates: { latitude: 40.4695, longitude: -3.5852 },
            startDate: new Date('2024-07-10'),
            endDate: new Date('2024-07-14'),
            status: 'active',
            burgerPrice: 12.5,
            participants: 120,
            maxParticipants: 200,
            imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=80',
            description: '¡Vive la experiencia burger en Madrid!',
            createdAt: new Date(),
            updatedAt: new Date(),
          },
          {
            name: 'Champions Burger Valencia',
            location: 'Valencia',
            address: 'Jardín del Turia, Valencia',
            coordinates: { latitude: 39.4745, longitude: -0.3763 },
            startDate: new Date('2024-08-01'),
            endDate: new Date('2024-08-05'),
            status: 'upcoming',
            burgerPrice: 11.0,
            participants: 80,
            maxParticipants: 150,
            imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80',
            description: '¡Las mejores burgers llegan a Valencia!',
            createdAt: new Date(),
            updatedAt: new Date(),
          },
          {
            name: 'Champions Burger Barcelona',
            location: 'Barcelona',
            address: 'Parc de la Ciutadella, Barcelona',
            coordinates: { latitude: 41.3894, longitude: 2.1833 },
            startDate: new Date('2024-09-10'),
            endDate: new Date('2024-09-15'),
            status: 'upcoming',
            burgerPrice: 13.0,
            participants: 60,
            maxParticipants: 120,
            imageUrl: 'https://images.unsplash.com/photo-1464306076886-debca5e8a6b0?auto=format&fit=crop&w=800&q=80',
            description: '¡Cierra la Champions Burger en Barcelona!',
            createdAt: new Date(),
            updatedAt: new Date(),
          },
        ],
      },
      {
        id: 'burger_fest',
        name: 'Burger Fest',
        description: 'Festival nacional de hamburguesas con foodtrucks, música y concursos.',
        startDate: new Date('2024-06-15'),
        endDate: new Date('2024-08-15'),
        status: 'active',
        imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&h=400&fit=crop',
        totalEvents: 2,
        currentEventId: null,
        createdAt: new Date(),
        updatedAt: new Date(),
        events: [
          {
            name: 'Burger Fest Sevilla',
            location: 'Sevilla',
            address: 'Parque de María Luisa, Sevilla',
            coordinates: { latitude: 37.3686, longitude: -5.9876 },
            startDate: new Date('2024-06-20'),
            endDate: new Date('2024-06-23'),
            status: 'finished',
            burgerPrice: 10.0,
            participants: 200,
            maxParticipants: 200,
            imageUrl: 'https://images.unsplash.com/photo-1519864600265-abb23847ef2c?auto=format&fit=crop&w=800&q=80',
            description: '¡Gran cierre en Sevilla!',
            createdAt: new Date(),
            updatedAt: new Date(),
          },
          {
            name: 'Burger Fest Málaga',
            location: 'Málaga',
            address: 'Muelle Uno, Málaga',
            coordinates: { latitude: 36.7196, longitude: -4.4162 },
            startDate: new Date('2024-07-05'),
            endDate: new Date('2024-07-07'),
            status: 'active',
            burgerPrice: 9.5,
            participants: 150,
            maxParticipants: 180,
            imageUrl: 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=800&q=80',
            description: '¡Burgers y música en la costa!',
            createdAt: new Date(),
            updatedAt: new Date(),
          },
        ],
      },
      {
        id: 'gourmet_burger_week',
        name: 'Gourmet Burger Week',
        description: 'Una semana dedicada a las hamburguesas gourmet en restaurantes selectos.',
        startDate: new Date('2024-10-01'),
        endDate: new Date('2024-10-07'),
        status: 'upcoming',
        imageUrl: 'https://images.unsplash.com/photo-1550547660-d9450f859349?w=800&h=400&fit=crop',
        totalEvents: 2,
        currentEventId: null,
        createdAt: new Date(),
        updatedAt: new Date(),
        events: [
          {
            name: 'Gourmet Burger Madrid',
            location: 'Madrid',
            address: 'Restaurante Gourmet Burger, Madrid',
            coordinates: { latitude: 40.4168, longitude: -3.7038 },
            startDate: new Date('2024-10-01'),
            endDate: new Date('2024-10-03'),
            status: 'upcoming',
            burgerPrice: 15.0,
            participants: 30,
            maxParticipants: 50,
            imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=80',
            description: '¡Solo para los más foodies!',
            createdAt: new Date(),
            updatedAt: new Date(),
          },
          {
            name: 'Gourmet Burger Barcelona',
            location: 'Barcelona',
            address: 'Restaurante Gourmet Burger, Barcelona',
            coordinates: { latitude: 41.3851, longitude: 2.1734 },
            startDate: new Date('2024-10-05'),
            endDate: new Date('2024-10-07'),
            status: 'upcoming',
            burgerPrice: 16.0,
            participants: 20,
            maxParticipants: 40,
            imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80',
            description: '¡Cierra la semana gourmet en Barcelona!',
            createdAt: new Date(),
            updatedAt: new Date(),
          },
        ],
      },
    ];

    let createdCompetitions = 0;
    let createdEvents = 0;
    let createdParticipants = 0;

    for (const comp of competitions) {
      const compRef = db.collection('competitions').doc(comp.id);
      const compDoc = await compRef.get();
      
      if (!compDoc.exists) {
        printMessage(`\n📝 Creando competición: ${comp.name}`);
        await compRef.set({
          name: comp.name,
          description: comp.description,
          startDate: comp.startDate,
          endDate: comp.endDate,
          status: comp.status,
          imageUrl: comp.imageUrl,
          totalEvents: comp.totalEvents,
          currentEventId: comp.currentEventId,
          createdAt: comp.createdAt,
          updatedAt: comp.updatedAt,
        });
        createdCompetitions++;
        printMessage(`   ✅ Competición creada: ${comp.name}`);
      } else {
        printMessage(`\n⚠️  La competición ya existe: ${comp.name}`);
        // Actualizar la competición existente
        await compRef.update({
          name: comp.name,
          description: comp.description,
          startDate: comp.startDate,
          endDate: comp.endDate,
          status: comp.status,
          imageUrl: comp.imageUrl,
          totalEvents: comp.totalEvents,
          updatedAt: new Date(),
        });
        printMessage(`   🔄 Competición actualizada: ${comp.name}`);
      }

      // Crear o actualizar eventos
      for (const event of comp.events) {
        const eventsSnapshot = await compRef.collection('events')
          .where('name', '==', event.name)
          .limit(1)
          .get();

        let eventRef;
        if (eventsSnapshot.empty) {
          eventRef = await compRef.collection('events').add(event);
          createdEvents++;
          printMessage(`   📅 Evento creado: ${event.name}`);
        } else {
          eventRef = eventsSnapshot.docs[0].ref;
          await eventRef.update({
            ...event,
            updatedAt: new Date(),
          });
          printMessage(`   🔄 Evento actualizado: ${event.name}`);
        }

        // Crear participantes de ejemplo para cada evento
        const participantsSnapshot = await eventRef.collection('participants').get();
        if (participantsSnapshot.empty) {
          const participants = [
            {
              restaurantId: 'rest1',
              restaurantName: 'Burger House',
              burgerName: 'La Clásica',
              burgerDescription: 'Carne 100% vacuno, queso cheddar, lechuga, tomate y salsa especial.',
              burgerImageUrl: 'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=800&q=80',
              votes: Math.floor(Math.random() * 200),
              rating: (Math.random() * 2 + 3).toFixed(1),
              totalRatings: Math.floor(Math.random() * 100),
              joinedAt: new Date(),
              updatedAt: new Date(),
            },
            {
              restaurantId: 'rest2',
              restaurantName: 'Smash Bros',
              burgerName: 'Smash Supreme',
              burgerDescription: 'Doble smash, bacon crujiente, cebolla caramelizada y salsa ahumada.',
              burgerImageUrl: 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=800&q=80',
              votes: Math.floor(Math.random() * 200),
              rating: (Math.random() * 2 + 3).toFixed(1),
              totalRatings: Math.floor(Math.random() * 100),
              joinedAt: new Date(),
              updatedAt: new Date(),
            },
            {
              restaurantId: 'rest3',
              restaurantName: 'Vegan Queen',
              burgerName: 'Green Power',
              burgerDescription: 'Hamburguesa vegana de garbanzos, rúcula, tomate seco y alioli vegano.',
              burgerImageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=80',
              votes: Math.floor(Math.random() * 200),
              rating: (Math.random() * 2 + 3).toFixed(1),
              totalRatings: Math.floor(Math.random() * 100),
              joinedAt: new Date(),
              updatedAt: new Date(),
            },
          ];
          
          for (const participant of participants) {
            await eventRef.collection('participants').add(participant);
            createdParticipants++;
          }
          printMessage(`      👥 ${participants.length} participantes creados`);
        } else {
          printMessage(`      ⚠️  El evento ya tiene participantes (${participantsSnapshot.size})`);
        }
      }
    }

    printMessage('\n📊 Resumen de restauración:');
    printMessage(`   🏆 Competiciones: ${createdCompetitions} creadas`);
    printMessage(`   📅 Eventos: ${createdEvents} creados`);
    printMessage(`   👥 Participantes: ${createdParticipants} creados`);
    printMessage('\n✅ Restauración completada exitosamente.');
  } catch (error) {
    printMessage(`\n❌ Error durante la restauración: ${error.message}`);
    printMessage(error.stack);
    throw error;
  }
}

restoreCompetitions()
  .then(() => {
    process.exit(0);
  })
  .catch((e) => {
    console.error('❌ Error fatal:', e);
    process.exit(1);
  });

