const express = require("express");
const router = express.Router();
const exerciseController = require("../controllers/exerciseController");
const auth = require("../middleware/auth");

// All routes are protected
router.use(auth);

// Create a new exercise
router.post("/", exerciseController.createExercise);

// Generate exercises using AI
router.post("/generate", exerciseController.generateExercises);

// Get all exercises for the logged-in user
router.get("/", exerciseController.getExercises);

// Get exercises by symptom ID
router.get("/symptom/:symptomId", exerciseController.getExercisesBySymptom);

// Get a single exercise by ID
router.get("/:id", exerciseController.getExerciseById);

// Update an exercise
router.put("/:id", exerciseController.updateExercise);

// Delete an exercise
router.delete("/:id", exerciseController.deleteExercise);

module.exports = router;
