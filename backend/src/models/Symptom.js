const mongoose = require("mongoose");

const severitySchema = new mongoose.Schema({
  value: {
    type: Number,
    required: true,
    min: 0,
    max: 10,
  },
  date: {
    type: Date,
    default: Date.now,
  },
  notes: {
    type: String,
    trim: true,
  },
});

const symptomSchema = new mongoose.Schema({
  bodyPart: {
    type: String,
    required: true,
    trim: true,
  },
  notes: {
    type: String,
    trim: true,
  },
  severities: [severitySchema],
  exercises: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Exercise",
    },
  ],
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
  },
});

const Symptom = mongoose.model("Symptom", symptomSchema);

module.exports = Symptom;
