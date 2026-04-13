const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');

const incidentRoutes = require('./routes/incidentRoutes');

const app = express();
const PORT = process.env.PORT || 8080;

app.use(cors());
app.use(express.json());

// Firebase Admin init: place serviceAccountKey.json in backend root.
try {
  const serviceAccount = require('./serviceAccountKey.json');

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });

  console.log('Firebase Admin initialized.');
} catch (error) {
  console.warn(
    'Firebase Admin not initialized. Add backend/serviceAccountKey.json to enable Firestore access.'
  );
}

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    service: 'cargomind-backend',
    timestamp: new Date().toISOString(),
  });
});

app.use('/api', incidentRoutes);

app.listen(PORT, () => {
  console.log(`CargoMind backend listening on port ${PORT}`);
});
