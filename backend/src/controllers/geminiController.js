const geminiService = require("../services/geminiService");
const Exercise = require("../models/Exercise");
const Symptom = require("../models/Symptom");
const RecoveryPlan = require("../models/RecoveryPlan");

exports.chatInteraction = async (req, res) => {
  try {
    const { message, chatHistory } = req.body;
    const response = await geminiService.generateChatResponse(req.user, message, chatHistory);
    res.json({ response });
  } catch (error) {
    console.error("Chat Interaction Error:", error);
    res.status(500).json({ error: error.message });
  }
};

exports.generateRecoveryPlan = async (req, res) => {
  try {
    const { symptomIds, startDate, planDuration } = req.body;

    if (!symptomIds || !Array.isArray(symptomIds) || symptomIds.length === 0) {
      return res.status(400).json({ error: "Please select at least one symptom" });
    }

    // Validate and parse startDate (default to today if invalid)
    let parsedStartDate;
    try {
      parsedStartDate = startDate ? new Date(startDate) : new Date();
      // Check if date is valid
      if (isNaN(parsedStartDate.getTime())) {
        parsedStartDate = new Date();
      }
    } catch (e) {
      parsedStartDate = new Date();
    }

    // Validate planDuration (must be 'auto' or a number between 1-12)
    let parsedDuration = planDuration || "auto";
    if (parsedDuration !== "auto") {
      const durationNum = parseInt(parsedDuration, 10);
      if (isNaN(durationNum) || durationNum < 1 || durationNum > 12) {
        parsedDuration = "auto";
      } else {
        parsedDuration = durationNum;
      }
    }

    // Get selected symptoms
    const selectedSymptoms = await Symptom.find({
      _id: { $in: symptomIds },
      user: req.user._id,
    });

    if (selectedSymptoms.length === 0) {
      return res.status(400).json({ error: "No valid symptoms found for the selected IDs" });
    }

    // Generate exercise plan
    const result = await geminiService.generateRecoveryPlan(selectedSymptoms, parsedDuration, parsedStartDate);

    // Check if existing plan exists - we'll need to process it specially
    await saveRecoveryPlanWithSelectedSymptoms(req.user._id, result.planStructure, result.exercises, selectedSymptoms);

    res.json({ plan: result.planStructure });
  } catch (error) {
    console.error("Recovery Plan Generation Error:", error);
    res.status(500).json({ error: error.message });
  }
};

exports.saveRecoveryPlan = async (req, res) => {
  try {
    const { plan } = req.body;

    if (!plan || !plan.title || !plan.description || !plan.weeks || !plan.weeks.length) {
      return res.status(400).json({ error: "Invalid recovery plan data" });
    }

    // This is to save a plan that's been manually updated by the user, so we don't need to perform
    // symptom-based cleanup - just save it as-is
    const processedWeeks = await Promise.all(
      plan.weeks.map(async (week) => {
        // Process the exercises in this week
        const processedExercises = await Promise.all(
          week.exercises.map(async (exerciseData) => {
            // Find or create the Exercise document
            let exercise;

            // Try to find an existing exercise with the same name and body part
            exercise = await Exercise.findOne({
              exerciseType: exerciseData.exerciseType,
              user: req.user._id,
              bodyPart: exerciseData.bodyPart,
            });

            // If no existing exercise found, create a new one
            if (!exercise) {
              exercise = new Exercise({
                exerciseType: exerciseData.exerciseType,
                description: exerciseData.description,
                duration: exerciseData.duration,
                difficulty: exerciseData.difficulty || 3,
                precautions: exerciseData.precautions || "Consult with a physical therapist if pain increases",
                bodyPart: exerciseData.bodyPart,
                scheduledDate: exerciseData.scheduledDate || null,
                symptom: await findRelevantSymptom(req.user._id, exerciseData.bodyPart),
                user: req.user._id,
              });

              await exercise.save();
              console.log(`Created new exercise: ${exercise.exerciseType} for ${exercise.bodyPart}`);
            } else {
              // Update existing exercise's scheduled date if it exists
              if (exerciseData.scheduledDate) {
                exercise.scheduledDate = exerciseData.scheduledDate;
                await exercise.save();
              }
            }

            // Return the exercise reference with its completion status
            return {
              exercise: exercise._id,
              isCompleted: exerciseData.isCompleted || false,
            };
          })
        );

        // Return the processed week data
        return {
          weekNumber: week.weekNumber,
          focus: week.focus,
          exercises: processedExercises,
        };
      })
    );

    // Check if a plan already exists for this user
    const existingPlan = await RecoveryPlan.findOne({ user: req.user._id });

    if (existingPlan) {
      // Update existing plan
      existingPlan.title = plan.title;
      existingPlan.description = plan.description;
      existingPlan.weeks = processedWeeks;
      existingPlan.createdAt = Date.now();

      await existingPlan.save();
      res.json({ message: "Recovery plan updated successfully", plan: existingPlan });
    } else {
      // Create new plan
      const newPlan = new RecoveryPlan({
        user: req.user._id,
        title: plan.title,
        description: plan.description,
        weeks: processedWeeks,
      });

      await newPlan.save();
      res.json({ message: "Recovery plan saved successfully", plan: newPlan });
    }
  } catch (error) {
    console.error("Save Recovery Plan Error:", error);
    res.status(500).json({ error: error.message });
  }
};

// Helper function to save a recovery plan while preserving exercises for non-selected symptoms
async function saveRecoveryPlanWithSelectedSymptoms(userId, planStructure, newExercises, selectedSymptoms) {
  try {
    // Get the existing plan
    const existingPlan = await RecoveryPlan.findOne({ user: userId }).populate({
      path: "weeks.exercises.exercise",
      model: "Exercise",
    });

    // Get the IDs of selected symptoms
    const selectedSymptomIds = selectedSymptoms.map((s) => s._id.toString());

    // Save the new exercises to the database first
    const savedExercises = [];
    for (const exerciseData of newExercises) {
      const exercise = new Exercise({
        exerciseType: exerciseData.exerciseType,
        description: exerciseData.description,
        duration: exerciseData.duration,
        difficulty: exerciseData.difficulty || 3,
        precautions: exerciseData.precautions || "Consult with a physical therapist if pain increases",
        bodyPart: exerciseData.bodyPart,
        scheduledDate: exerciseData.scheduledDate || null,
        symptom: await findRelevantSymptom(userId, exerciseData.bodyPart),
        user: userId,
      });

      await exercise.save();
      savedExercises.push(exercise);
    }

    // Prepare the new plan data
    const processedWeeks = planStructure.weeks.map((week) => ({
      weekNumber: week.weekNumber,
      focus: week.focus,
      exercises: week.exercises.map((ex) => {
        // Find the corresponding saved exercise
        const matchingExercise = savedExercises.find(
          (saved) => saved.exerciseType === ex.name && saved.bodyPart === ex.bodyPart
        );

        return {
          exercise: matchingExercise._id,
          isCompleted: ex.isCompleted || false,
        };
      }),
    }));

    // If there's an existing plan, merge with preserved exercises
    if (existingPlan) {
      // Identify exercises in the existing plan that are for symptoms not selected in this update
      const preservedExercises = [];

      for (const week of existingPlan.weeks) {
        for (const exerciseEntry of week.exercises) {
          // If the exercise has a symptom and it's not in the selected symptoms list, preserve it
          if (
            exerciseEntry.exercise.symptom &&
            !selectedSymptomIds.includes(exerciseEntry.exercise.symptom.toString())
          ) {
            preservedExercises.push({
              exercise: exerciseEntry.exercise._id,
              isCompleted: exerciseEntry.isCompleted,
              week: week.weekNumber,
            });
          }
        }
      }

      // Add preserved exercises to the new plan
      for (const preserved of preservedExercises) {
        // Find matching week or create it
        let weekIndex = processedWeeks.findIndex((w) => w.weekNumber === preserved.week);

        if (weekIndex < 0) {
          // Week doesn't exist in new plan, add it
          processedWeeks.push({
            weekNumber: preserved.week,
            focus: `Week ${preserved.week}`,
            exercises: [],
          });
          weekIndex = processedWeeks.length - 1;
        }

        // Add exercise to the week
        processedWeeks[weekIndex].exercises.push({
          exercise: preserved.exercise,
          isCompleted: preserved.isCompleted,
        });
      }

      // Update the existing plan
      existingPlan.title = planStructure.title;
      existingPlan.description = planStructure.description;
      existingPlan.weeks = processedWeeks;
      existingPlan.createdAt = Date.now();

      await existingPlan.save();
      console.log("Updated existing recovery plan with preserved exercises");
      return existingPlan;
    } else {
      // Create a new plan
      const newPlan = new RecoveryPlan({
        user: userId,
        title: planStructure.title,
        description: planStructure.description,
        weeks: processedWeeks,
      });

      await newPlan.save();
      console.log("Created new recovery plan");
      return newPlan;
    }
  } catch (error) {
    console.error("Error saving recovery plan with selected symptoms:", error);
    throw error;
  }
}

// Helper function to find a relevant symptom for an exercise
async function findRelevantSymptom(userId, bodyPart) {
  // Try to find a symptom with the same body part
  const symptom = await Symptom.findOne({
    user: userId,
    bodyPart: new RegExp(bodyPart, "i"), // Case-insensitive match
  });

  if (symptom) {
    return symptom._id;
  }

  // If no matching symptom found, get any symptom from the user
  const anySymptom = await Symptom.findOne({ user: userId });

  if (anySymptom) {
    return anySymptom._id;
  }

  throw new Error("No symptoms found for user. Cannot create exercise without a symptom reference.");
}

exports.getUserRecoveryPlan = async (req, res) => {
  try {
    // Find the plan and populate the exercise references
    const plan = await RecoveryPlan.findOne({ user: req.user._id }).populate({
      path: "weeks.exercises.exercise",
      model: "Exercise",
    });

    if (!plan) {
      return res.status(404).json({ error: "No recovery plan found for this user" });
    }

    // Transform the plan data for the client
    const transformedPlan = {
      _id: plan._id,
      user: plan.user,
      title: plan.title,
      description: plan.description,
      createdAt: plan.createdAt,
      weeks: plan.weeks.map((week) => ({
        _id: week._id,
        weekNumber: week.weekNumber,
        focus: week.focus,
        exercises: week.exercises.map((ex) => ({
          exerciseType: ex.exercise.exerciseType,
          description: ex.exercise.description,
          duration: ex.exercise.duration,
          difficulty: ex.exercise.difficulty,
          precautions: ex.exercise.precautions,
          bodyPart: ex.exercise.bodyPart,
          isCompleted: ex.isCompleted,
        })),
      })),
    };

    res.json({ plan: transformedPlan });
  } catch (error) {
    console.error("Get Recovery Plan Error:", error);
    res.status(500).json({ error: error.message });
  }
};
