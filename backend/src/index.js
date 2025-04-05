require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const userRoutes = require('./routes/userRoutes');
const symptomRoutes = require('./routes/symptomRoutes');
const exerciseRoutes = require('./routes/exerciseRoutes');
const geminiRoutes = require('./routes/geminiRoutes');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('admin'));

// Add request logging middleware
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  if (req.body && Object.keys(req.body).length > 0) {
    // Log request body but mask password
    const logBody = {...req.body};
    if (logBody.password) logBody.password = '********';
    console.log('Request Body:', JSON.stringify(logBody));
  }
  
  // Capture the original send function
  const originalSend = res.send;
  
  // Override the send function
  res.send = function(body) {
    console.log(`[${new Date().toISOString()}] Response:`, typeof body === 'object' ? JSON.stringify(body) : body);
    return originalSend.apply(this, arguments);
  };
  
  next();
});

// Routes
app.use('/api/users', userRoutes);
app.use('/api/symptoms', symptomRoutes);
app.use('/api/exercises', exerciseRoutes);
app.use('/api/gemini', geminiRoutes);

// MongoDB Connection
mongoose.connect(process.env.MONGODB_URI)
  .then(() => {
    console.log('Connected to MongoDB');
    // Start server
    const PORT = process.env.PORT || 3001;
    app.listen(PORT, () => {
      console.log(`Server is running on port ${PORT}`);
    });
  })
  .catch((error) => {
    console.error('MongoDB connection error:', error);
  }); 