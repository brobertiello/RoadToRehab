const geminiService = require('../services/geminiService');
const Exercise = require('../models/Exercise');
const Symptom = require('../models/Symptom');
const RecoveryPlan = require('../models/RecoveryPlan');

exports.chatInteraction = async (req, res) => {
  try {
    const { message, chatHistory } = req.body;
    const response = await geminiService.generateChatResponse(req.user, message, chatHistory);
    res.json({ response });
  } catch (error) {
    console.error('Chat Interaction Error:', error);
    res.status(500).json({ error: error.message });
  }
};

exports.generateRecoveryPlan = async (req, res) => {
  try {
    // Get user's symptoms
    const symptoms = await Symptom.find({ user: req.user._id });
    if (!symptoms || symptoms.length === 0) {
      return res.status(400).json({ error: 'No symptoms found for the user' });
    }

    // Generate exercise plan
    const exercises = await geminiService.generateRecoveryPlan(symptoms);
    
    // Save exercises to database
    const savedExercises = await Promise.all(
      exercises.map(async (exercise) => {
        const newExercise = new Exercise({
          ...exercise,
          user: req.user._id,
          symptom: symptoms[0]._id // Assigning to first symptom for simplicity
        });
        return await newExercise.save();
      })
    );

    res.json({ exercises: savedExercises });
  } catch (error) {
    console.error('Recovery Plan Generation Error:', error);
    res.status(500).json({ error: error.message });
  }
};

exports.saveRecoveryPlan = async (req, res) => {
  try {
    const { plan } = req.body;
    
    if (!plan || !plan.title || !plan.description || !plan.weeks || !plan.weeks.length) {
      return res.status(400).json({ error: 'Invalid recovery plan data' });
    }
    
    // Process the weeks to ensure we're using Exercise references
    const processedWeeks = await Promise.all(plan.weeks.map(async (week) => {
      // Process the exercises in this week
      const processedExercises = await Promise.all(week.exercises.map(async (exerciseData) => {
        // Find or create the Exercise document
        let exercise;
        
        // Try to find an existing exercise with the same name and body part
        exercise = await Exercise.findOne({ 
          exerciseType: exerciseData.exerciseType,
          user: req.user._id,
          bodyPart: exerciseData.bodyPart
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
            symptom: await findRelevantSymptom(req.user._id, exerciseData.bodyPart),
            user: req.user._id
          });
          
          await exercise.save();
          console.log(`Created new exercise: ${exercise.exerciseType} for ${exercise.bodyPart}`);
        }
        
        // Return the exercise reference with its completion status
        return {
          exercise: exercise._id,
          isCompleted: exerciseData.isCompleted || false
        };
      }));
      
      // Return the processed week data
      return {
        weekNumber: week.weekNumber,
        focus: week.focus,
        exercises: processedExercises
      };
    }));
    
    // Check if a plan already exists for this user
    const existingPlan = await RecoveryPlan.findOne({ user: req.user._id });
    
    if (existingPlan) {
      // Update existing plan
      existingPlan.title = plan.title;
      existingPlan.description = plan.description;
      existingPlan.weeks = processedWeeks;
      existingPlan.createdAt = Date.now();
      
      await existingPlan.save();
      res.json({ message: 'Recovery plan updated successfully', plan: existingPlan });
    } else {
      // Create new plan
      const newPlan = new RecoveryPlan({
        user: req.user._id,
        title: plan.title,
        description: plan.description,
        weeks: processedWeeks
      });
      
      await newPlan.save();
      res.json({ message: 'Recovery plan saved successfully', plan: newPlan });
    }
  } catch (error) {
    console.error('Save Recovery Plan Error:', error);
    res.status(500).json({ error: error.message });
  }
};

// Helper function to find a relevant symptom for an exercise
async function findRelevantSymptom(userId, bodyPart) {
  // Try to find a symptom with the same body part
  const symptom = await Symptom.findOne({ 
    user: userId,
    bodyPart: new RegExp(bodyPart, 'i') // Case-insensitive match
  });
  
  if (symptom) {
    return symptom._id;
  }
  
  // If no matching symptom found, get any symptom from the user
  const anySymptom = await Symptom.findOne({ user: userId });
  
  if (anySymptom) {
    return anySymptom._id;
  }
  
  throw new Error('No symptoms found for user. Cannot create exercise without a symptom reference.');
}

exports.getUserRecoveryPlan = async (req, res) => {
  try {
    // Find the plan and populate the exercise references
    const plan = await RecoveryPlan.findOne({ user: req.user._id })
      .populate({
        path: 'weeks.exercises.exercise',
        model: 'Exercise'
      });
    
    if (!plan) {
      return res.status(404).json({ error: 'No recovery plan found for this user' });
    }
    
    // Transform the plan data for the client
    const transformedPlan = {
      _id: plan._id,
      user: plan.user,
      title: plan.title,
      description: plan.description,
      createdAt: plan.createdAt,
      weeks: plan.weeks.map(week => ({
        _id: week._id,
        weekNumber: week.weekNumber,
        focus: week.focus,
        exercises: week.exercises.map(ex => ({
          exerciseType: ex.exercise.exerciseType,
          description: ex.exercise.description,
          duration: ex.exercise.duration,
          difficulty: ex.exercise.difficulty,
          precautions: ex.exercise.precautions,
          bodyPart: ex.exercise.bodyPart,
          isCompleted: ex.isCompleted
        }))
      }))
    };
    
    res.json({ plan: transformedPlan });
  } catch (error) {
    console.error('Get Recovery Plan Error:', error);
    res.status(500).json({ error: error.message });
  }
}; 