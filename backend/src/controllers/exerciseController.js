const Exercise = require("../models/Exercise");
const Symptom = require("../models/Symptom");
const geminiService = require("../services/geminiService");
const exerciseList = require("../data/exerciseList");

// Create a new exercise
exports.createExercise = async (req, res) => {
  try {
    const { exerciseType, description, scheduledDate, duration, sets, repetitions, difficulty, notes, symptomId } =
      req.body;

    const exercise = new Exercise({
      exerciseType,
      description,
      scheduledDate: new Date(scheduledDate),
      duration,
      sets,
      repetitions,
      difficulty,
      notes,
      symptom: symptomId,
      user: req.user.id,
    });

    await exercise.save();

    // Update the symptom to reference this exercise
    await Symptom.findByIdAndUpdate(symptomId, { $push: { exercises: exercise._id } });

    res.status(201).json(exercise);
  } catch (error) {
    console.error("Create Exercise Error:", error);
    res.status(500).json({ error: error.message });
  }
};

// Get all exercises for the logged-in user
exports.getExercises = async (req, res) => {
  try {
    const exercises = await Exercise.find({ user: req.user.id })
      .populate("symptom", "bodyPart")
      .sort({ scheduledDate: 1 });

    res.json(exercises);
  } catch (error) {
    console.error("Get Exercises Error:", error);
    res.status(500).json({ error: error.message });
  }
};

// Get exercises by symptom ID
exports.getExercisesBySymptom = async (req, res) => {
  try {
    const { symptomId } = req.params;

    const exercises = await Exercise.find({
      user: req.user.id,
      symptom: symptomId,
    }).sort({ scheduledDate: 1 });

    res.json(exercises);
  } catch (error) {
    console.error("Get Exercises By Symptom Error:", error);
    res.status(500).json({ error: error.message });
  }
};

// Get a single exercise by ID
exports.getExerciseById = async (req, res) => {
  try {
    const exercise = await Exercise.findOne({
      _id: req.params.id,
      user: req.user.id,
    }).populate("symptom", "bodyPart");

    if (!exercise) {
      return res.status(404).json({ error: "Exercise not found" });
    }

    res.json(exercise);
  } catch (error) {
    console.error("Get Exercise By ID Error:", error);
    res.status(500).json({ error: error.message });
  }
};

// Update an exercise
exports.updateExercise = async (req, res) => {
  try {
    const { exerciseType, description, scheduledDate, duration, sets, repetitions, difficulty, notes, completed } =
      req.body;

    const exercise = await Exercise.findOneAndUpdate(
      { _id: req.params.id, user: req.user.id },
      {
        $set: {
          exerciseType,
          description,
          scheduledDate: scheduledDate ? new Date(scheduledDate) : undefined,
          duration,
          sets,
          repetitions,
          difficulty,
          notes,
          completed,
        },
      },
      { new: true, runValidators: true }
    );

    if (!exercise) {
      return res.status(404).json({ error: "Exercise not found" });
    }

    res.json(exercise);
  } catch (error) {
    console.error("Update Exercise Error:", error);
    res.status(500).json({ error: error.message });
  }
};

// Delete an exercise
exports.deleteExercise = async (req, res) => {
  try {
    const exercise = await Exercise.findOneAndDelete({
      _id: req.params.id,
      user: req.user.id,
    });

    if (!exercise) {
      return res.status(404).json({ error: "Exercise not found" });
    }

    // Remove the reference from the symptom
    await Symptom.findByIdAndUpdate(exercise.symptom, { $pull: { exercises: exercise._id } });

    res.json({ message: "Exercise removed" });
  } catch (error) {
    console.error("Delete Exercise Error:", error);
    res.status(500).json({ error: error.message });
  }
};

// Generate exercises using AI
exports.generateExercises = async (req, res) => {
  try {
    const { symptomIds, startDate, durationDays } = req.body;

    if (!symptomIds || !symptomIds.length) {
      return res.status(400).json({ error: "Symptom IDs are required" });
    }

    // Get all symptoms data for the AI
    const symptoms = await Symptom.find({
      _id: { $in: symptomIds },
      user: req.user.id,
    });

    if (!symptoms.length) {
      return res.status(404).json({ error: "No valid symptoms found" });
    }

    // Format the data for the AI
    const symptomData = symptoms.map((s) => ({
      id: s._id,
      bodyPart: s.bodyPart,
      notes: s.notes,
      severities: s.severities,
    }));

    // Call the AI service to generate exercises
    const generatedExercises = await geminiService.generateExercises(
      symptomData,
      exerciseList,
      startDate || new Date(),
      durationDays || 14
    );

    // Save the generated exercises to the database
    const savedExercises = [];

    for (const exercise of generatedExercises) {
      const newExercise = new Exercise({
        ...exercise,
        user: req.user.id,
      });

      await newExercise.save();

      // Update the symptom to reference this exercise
      await Symptom.findByIdAndUpdate(exercise.symptom, { $push: { exercises: newExercise._id } });

      savedExercises.push(newExercise);
    }

    res.status(201).json(savedExercises);
  } catch (error) {
    console.error("Generate Exercises Error:", error);
    res.status(500).json({ error: error.message });
  }
};
