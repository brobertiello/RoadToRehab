const geminiService = require('../services/geminiService');
const Exercise = require('../models/Exercise');
const Symptom = require('../models/Symptom');

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