const mongoose = require('mongoose');

const exerciseSchema = new mongoose.Schema({
  exerciseType: {
    type: String,
    required: true,
    trim: true
  },
  date: {
    type: Date,
    default: Date.now
  },
  completed: {
    type: Boolean,
    default: false
  },
  symptom: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Symptom',
    required: true
  },
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  }
});

const Exercise = mongoose.model('Exercise', exerciseSchema);

module.exports = Exercise; 