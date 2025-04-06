const mongoose = require("mongoose");

const exerciseSchema = new mongoose.Schema({
  exerciseType: {
    type: String,
    required: true,
    trim: true,
  },
  description: {
    type: String,
    required: true,
    trim: true,
  },
  scheduledDate: {
    type: Date,
    required: true,
  },
  duration: {
    type: String,
    trim: true,
  },
  sets: {
    type: Number,
    min: 0,
  },
  repetitions: {
    type: Number,
    min: 0,
  },
  completed: {
    type: Boolean,
    default: false,
  },
  symptom: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Symptom",
    required: true,
  },
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
  },
  difficulty: {
    type: Number,
    min: 1,
    max: 5,
    default: 1,
  },
  notes: {
    type: String,
    trim: true,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

const Exercise = mongoose.model("Exercise", exerciseSchema);

module.exports = Exercise;
