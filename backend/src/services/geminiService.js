const { GoogleGenerativeAI } = require('@google/generative-ai');

// Initialize Gemini API
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

// Helper function to structure the chat context
const createChatContext = (user) => {
  return `You are a personal physical therapy assistant helping ${user.name}. 
  You have access to their symptom history and exercise records. 
  Provide personalized, helpful advice while being empathetic and professional.`;
};

// Helper function to structure the recovery plan prompt
const createRecoveryPlanPrompt = (symptoms) => {
  const symptomsText = symptoms.map(s => 
    `${s.bodyPart} with pain level ${s.severities[s.severities.length - 1].value}/10`
  ).join(', ');
  
  return `Generate a recovery exercise plan for the following symptoms: ${symptomsText}.
  For each exercise, provide:
  - Exercise type/name
  - Description
  - Duration/repetitions
  - Difficulty level (1-5)
  - Precautions
  Format the response as a structured list of exercises that can be parsed into Exercise objects.`;
};

exports.generateChatResponse = async (user, message, chatHistory = []) => {
  try {
    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
    const chat = model.startChat({
      history: chatHistory,
      context: createChatContext(user),
    });

    const result = await chat.sendMessage(message);
    const response = await result.response;
    return response.text();
  } catch (error) {
    console.error('Gemini Chat Error:', error);
    throw new Error('Failed to generate chat response');
  }
};

exports.generateRecoveryPlan = async (symptoms) => {
  try {
    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
    const prompt = createRecoveryPlanPrompt(symptoms);
    
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();
    
    // Parse the response into exercise objects
    // This is a simplified example - you'll need to adjust the parsing based on the actual response format
    const exercises = text.split('\n\n').map(exerciseText => {
      const lines = exerciseText.split('\n');
      return {
        exerciseType: lines[0].replace('- ', '').trim(),
        description: lines[1].replace('Description: ', '').trim(),
        duration: lines[2].replace('Duration: ', '').trim(),
        difficulty: parseInt(lines[3].replace('Difficulty: ', '').trim()),
        precautions: lines[4].replace('Precautions: ', '').trim()
      };
    });
    
    return exercises;
  } catch (error) {
    console.error('Gemini Recovery Plan Error:', error);
    throw new Error('Failed to generate recovery plan');
  }
}; 