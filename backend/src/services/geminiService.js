const { GoogleGenerativeAI } = require("@google/generative-ai");
const exerciseList = require("../data/exerciseList");
const mongoose = require("mongoose");

// Initialize Gemini API
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

// Helper function to structure the chat context
const createChatContext = (user) => {
  return `You are a personal physical therapy assistant helping ${user.name}. 
  You have access to their symptom history and exercise records. 
  Provide personalized, helpful advice while being empathetic and professional.`;
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

// Generate exercises based on symptoms
exports.generateExercises = async (symptoms, exerciseList, startDate, durationDays) => {
  try {
    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

    // Format the symptoms data for the prompt
    const symptomsData = symptoms
      .map((symptom) => {
        const latestSeverity = symptom.severities.sort((a, b) => new Date(b.date) - new Date(a.date))[0];
        return `Body part: ${symptom.bodyPart}
Current pain level: ${latestSeverity ? latestSeverity.value : "Unknown"}/10
Notes: ${symptom.notes || "None"}
Severity history: ${symptom.severities
          .map((s) => `${new Date(s.date).toLocaleDateString()}: ${s.value}/10${s.notes ? ` (${s.notes})` : ""}`)
          .join(", ")}`;
      })
      .join("\n\n");

    // Calculate end date
    const endDate = new Date(startDate);
    endDate.setDate(endDate.getDate() + durationDays);

    // Build the prompt for exercise generation
    const prompt = `As a physical therapy AI, generate a personalized exercise plan based on the following symptoms:

${symptomsData}

Create a recovery plan with exercises from the following categories only:
${Object.keys(exerciseList)
  .map((category) => `- ${category}`)
  .join("\n")}

For each symptom, select appropriate exercises and specify:
1. The exercise type (must be one from the list)
2. Scheduled date (between ${new Date(startDate).toLocaleDateString()} and ${endDate.toLocaleDateString()})
3. Number of sets and repetitions or duration
4. A difficulty level from 1-5

Format your response as a JSON array with the following structure for each exercise:
[
  {
    "exerciseType": "Name of exercise",
    "description": "Exercise description",
    "scheduledDate": "YYYY-MM-DD",
    "duration": "Duration or repetition instructions",
    "sets": number of sets (if applicable),
    "repetitions": number of repetitions per set (if applicable),
    "difficulty": difficulty level (1-5),
    "notes": "Any specific instructions",
    "symptom": "symptomId"
  },
  ...
]

Make sure to select appropriate exercises based on the body part and severity level, and schedule them in a progressive manner over the given period.`;

    // Call the AI model
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    // Extract the JSON from the response
    const jsonMatch = text.match(/\[\s*\{.*\}\s*\]/s);
    if (!jsonMatch) {
      throw new Error("Failed to extract exercise data from AI response");
    }

    // Parse the JSON
    const exercisesData = JSON.parse(jsonMatch[0]);

    // Map the symptoms to their IDs for reference
    const symptomMap = {};
    symptoms.forEach((symptom) => {
      symptomMap[symptom.bodyPart.toLowerCase()] = symptom.id;
    });

    // Process the exercises to ensure they have valid data
    const processedExercises = exercisesData.map((exercise) => {
      // Find the corresponding symptom based on the exercise type
      const bodyPart = Object.keys(exerciseList).find((part) =>
        exerciseList[part].some((e) => e.exerciseType === exercise.exerciseType)
      );

      // Find the matching symptom ID
      let symptomId = exercise.symptom;
      if (!mongoose.Types.ObjectId.isValid(symptomId)) {
        // If the symptom isn't a valid ID, try to match by body part
        const matchingSymptom = symptoms.find(
          (s) =>
            s.bodyPart.toLowerCase() === (exercise.symptom || "").toLowerCase() ||
            s.bodyPart.toLowerCase().includes(bodyPart || "")
        );
        symptomId = matchingSymptom ? matchingSymptom.id : symptoms[0].id;
      }

      return {
        ...exercise,
        scheduledDate: new Date(exercise.scheduledDate),
        symptom: symptomId,
        // Ensure numeric fields are numbers
        sets: Number(exercise.sets) || undefined,
        repetitions: Number(exercise.repetitions) || undefined,
        difficulty: Number(exercise.difficulty) || 1,
      };
    });

    return processedExercises;
  } catch (error) {
    console.error("Generate Exercises Error:", error);
    throw new Error("Failed to generate exercises plan");
  }
};

// Helper function to safely extract a field from text
function extractField(text, fieldName) {
  const regex = new RegExp(`${fieldName}\\s*(.+?)(?=\\n|$)`, "i");
  const match = text.match(regex);
  return match ? match[1].trim() : null;
}
