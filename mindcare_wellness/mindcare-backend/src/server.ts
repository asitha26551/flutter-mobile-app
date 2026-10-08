import express from 'express';

import './config/firebase.js';

const app = express();

const PORT = process.env.PORT ?? 3000;

app.use(express.json());

app.get('/health', (_req, res) => {
  res.status(200).json({
    status: 'ok',
    service: 'mindcare-backend',
  });
});

app.listen(PORT, () => {
  console.log(`Mindcare backend running on port ${PORT}`);
});
