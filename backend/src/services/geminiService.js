const { GoogleGenerativeAI } = require("@google/generative-ai");

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
  const symptomsText = symptoms
    .map((s) => {
      let text = `${s.bodyPart} with pain level ${s.severities[s.severities.length - 1].value}/10`;
      if (s.notes) {
        text += ` - Notes: ${s.notes}`;
      }
      return text;
    })
    .join(", ");

  return `Generate a recovery exercise plan for the following symptoms: ${symptomsText}.
  
  I need you to return structured data that I can parse. For each exercise, include EXACTLY these fields with EXACTLY these labels:
  
  Exercise type: [name of exercise]
  Description: [detailed description of how to do it]
  Duration: [duration/repetitions]
  Difficulty: [number from 1-5]
  Precautions: [safety notes]
  Body part: [affected body part]
  
  Please format each exercise as a separate paragraph with these exact field names.
  Include at least 8 different exercises that target the affected body parts.`;
};

exports.generateChatResponse = async (user, message, chatHistory = []) => {
  try {
    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
    const chat = model.startChat({
      history: chatHistory,
      context: createChatContext(user),
    });

    const result = await chat.sendMessage(message);
    const response = await result.response;
    return response.text();
  } catch (error) {
    console.error("Gemini Chat Error:", error);
    throw new Error("Failed to generate chat response");
  }
};

exports.generateRecoveryPlan = async (symptoms) => {
  try {
    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
    const prompt = createRecoveryPlanPrompt(symptoms);

    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    console.log("Raw Gemini response:", text);

    // Parse the response into exercise objects with safer handling
    const exerciseBlocks = text.split(/\n\s*\n/); // Split by one or more blank lines

    const exercises = exerciseBlocks
      .map((block) => {
        // Safely extract each field with regex
        const exerciseType = extractField(block, "Exercise type:") || "General exercise";
        const description = extractField(block, "Description:") || "Perform carefully and as directed.";
        const duration = extractField(block, "Duration:") || "As tolerated";
        const difficultyText = extractField(block, "Difficulty:") || "3";
        const difficulty = parseInt(difficultyText.match(/\d+/)?.[0] || "3");
        const precautions = extractField(block, "Precautions:") || "Stop if pain increases.";
        const bodyPart = extractField(block, "Body part:") || symptoms[0]?.bodyPart || "General";

        return {
          exerciseType,
          description,
          duration,
          difficulty: isNaN(difficulty) ? 3 : difficulty, // Default to 3 if parsing fails
          precautions,
          bodyPart,
        };
      })
      .filter(
        (exercise) =>
          // Filter out any exercises that don't have the minimum required fields
          exercise.exerciseType && exercise.description
      );

    // If we failed to parse any exercises, create a fallback
    if (exercises.length === 0) {
      const bodyPart = symptoms[0]?.bodyPart || "General";

      return [
        {
          exerciseType: `Gentle ${bodyPart} Stretches`,
          description: `Slowly and gently stretch the ${bodyPart} area, holding each stretch for 15-30 seconds.`,
          duration: "3 sets of 30 seconds, twice daily",
          difficulty: 2,
          precautions: "Stop if pain increases significantly",
          bodyPart,
        },
        {
          exerciseType: `${bodyPart} Strengthening`,
          description: `Basic resistance exercises for the ${bodyPart} area using bodyweight or light resistance.`,
          duration: "2 sets of 10 repetitions, every other day",
          difficulty: 3,
          precautions: "Maintain proper form throughout the exercise",
          bodyPart,
        },
      ];
    }

    return exercises;
  } catch (error) {
    console.error("Gemini Recovery Plan Error:", error);
    throw new Error("Failed to generate recovery plan");
  }
};

// Helper function to safely extract a field from text
function extractField(text, fieldName) {
  const regex = new RegExp(`${fieldName}\\s*(.+?)(?=\\n|$)`, "i");
  const match = text.match(regex);
  return match ? match[1].trim() : null;
}
