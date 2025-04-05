const mongoose = require('mongoose');

const RecoveryWeekSchema = new mongoose.Schema({
  weekNumber: {
    type: Number,
    required: true
  },
  focus: {
    type: String,
    required: true
  },
  exercises: [{
    exercise: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Exercise'
    },
    isCompleted: {
      type: Boolean,
      default: false
    }
  }]
});

const RecoveryPlanSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  title: {
    type: String,
    required: true
  },
  description: {
    type: String,
    required: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  weeks: [RecoveryWeekSchema]
});

module.exports = mongoose.model('RecoveryPlan', RecoveryPlanSchema); 