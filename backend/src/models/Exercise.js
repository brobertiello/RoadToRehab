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
  duration: {
    type: String,
    required: true,
    trim: true,
  },
  difficulty: {
    type: Number,
    required: true,
    min: 1,
    max: 5,
  },
  precautions: {
    type: String,
    required: true,
    trim: true,
  },
  date: {
    type: Date,
    default: Date.now,
  },
  scheduledDate: {
    type: Date,
    default: null,
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
});

const Exercise = mongoose.model("Exercise", exerciseSchema);

module.exports = Exercise;
