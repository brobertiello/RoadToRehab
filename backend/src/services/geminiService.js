const { GoogleGenerativeAI } = require("@google/generative-ai");
const exerciseList = require("../data/exerciseList");

// Initialize Gemini API
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

// Helper function to structure the chat context
const createChatContext = (user) => {
  return `You are a personal physical therapy assistant helping ${user.name}. 
  You have access to their symptom history and exercise records. 
  Provide personalized, helpful advice while being empathetic and professional.`;
};

// Helper function to structure the recovery plan prompt
const createRecoveryPlanPrompt = (symptoms, planDuration, startDate) => {
  const symptomsText = symptoms
    .map((s) => {
      let text = `${s.bodyPart} with pain level ${s.severities[s.severities.length - 1].value}/10`;
      if (s.notes) {
        text += ` - Notes: ${s.notes}`;
      }
      return text;
    })
    .join(", ");

  // If auto duration, mention that in the prompt
  const durationText =
    planDuration === "auto"
      ? "Determine the appropriate duration based on symptoms"
      : `Plan should last for ${planDuration} weeks`;

  return `Create a recovery plan for the following symptoms: ${symptomsText}.
  
  The plan should start on ${startDate.toISOString().split("T")[0]} and ${durationText}.
  
  For your plan:
  1. Determine how many weeks the rehabilitation should take based on the symptoms.
  2. For each week, provide a theme/focus area.
  3. Determine which specific existing exercises from our database should be scheduled each week.
  4. Assign specific dates to each exercise.
  
  Please provide the following fields in your response:
  - total_weeks: [number of weeks for full rehabilitation]
  - weekly_plan: [an array of weekly schedules with exercises and dates]
  
  I will parse your response as JSON, so please ensure it's in a valid format.`;
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

exports.generateRecoveryPlan = async (selectedSymptoms, planDuration = "auto", startDate = new Date()) => {
  try {
    // Get the AI to generate the plan structure
    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
    const prompt = createRecoveryPlanPrompt(selectedSymptoms, planDuration, startDate);

    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    console.log("Raw Gemini response:", text);

    // Try to parse the JSON response
    let planData;
    try {
      // Extract JSON from the response (it might be embedded in text)
      const jsonMatch =
        text.match(/```json\n([\s\S]*?)\n```/) || text.match(/```\n([\s\S]*?)\n```/) || text.match(/{[\s\S]*?}/);

      const jsonString = jsonMatch ? jsonMatch[1] || jsonMatch[0] : text;
      planData = JSON.parse(jsonString);
    } catch (err) {
      console.error("Failed to parse JSON from Gemini:", err);
      // Fall back to a simple plan if parsing fails
      planData = generateFallbackPlan(selectedSymptoms, planDuration, startDate);
    }

    // Use the plan structure to assign exercises from our predefined list
    const exercisePlan = createExercisePlanFromStructure(planData, selectedSymptoms, startDate);

    return {
      exercises: exercisePlan.exercises,
      planStructure: {
        title: `Recovery Plan for ${selectedSymptoms.map((s) => s.bodyPart).join(", ")}`,
        description: `A ${exercisePlan.totalWeeks}-week plan focusing on rehabilitation and strengthening of the affected areas.`,
        weeks: exercisePlan.weeks,
      },
    };
  } catch (error) {
    console.error("Gemini Recovery Plan Error:", error);
    // Generate a fallback plan if AI fails
    const fallbackPlan = generateFallbackPlan(selectedSymptoms, planDuration, startDate);
    const exercisePlan = createExercisePlanFromStructure(fallbackPlan, selectedSymptoms, startDate);

    return {
      exercises: exercisePlan.exercises,
      planStructure: {
        title: `Recovery Plan for ${selectedSymptoms.map((s) => s.bodyPart).join(", ")}`,
        description: `A ${exercisePlan.totalWeeks}-week rehabilitation plan to address your symptoms.`,
        weeks: exercisePlan.weeks,
      },
    };
  }
};

// Helper function to create a fallback plan if AI fails
function generateFallbackPlan(symptoms, planDuration, startDate) {
  // Determine duration if 'auto' was selected
  const duration =
    planDuration === "auto"
      ? Math.min(Math.max(2, Math.ceil(averagePainLevel(symptoms))), 8)
      : parseInt(planDuration, 10);

  const weeklyPlan = [];

  // Create a simple weekly structure
  for (let i = 1; i <= duration; i++) {
    weeklyPlan.push({
      week: i,
      focus: i <= duration / 2 ? "Pain Relief and Mobility" : "Strengthening and Function",
      exercise_count: Math.min(3 + i, 7), // Gradually increase number of exercises
    });
  }

  return {
    total_weeks: duration,
    weekly_plan: weeklyPlan,
  };
}

// Calculate average pain level to help determine plan duration
function averagePainLevel(symptoms) {
  if (!symptoms || symptoms.length === 0) return 5;

  let totalPain = 0;
  symptoms.forEach((symptom) => {
    if (symptom.severities && symptom.severities.length > 0) {
      totalPain += symptom.severities[symptom.severities.length - 1].value;
    }
  });

  return totalPain / symptoms.length;
}

// Create a complete exercise plan with weekly structure and exercises from predefined list
function createExercisePlanFromStructure(planData, symptoms, startDate) {
  const totalWeeks = planData.total_weeks || 4;
  const allExercises = [];
  const weeklyStructure = [];

  // Get body parts from symptoms
  const bodyParts = symptoms.map((s) => mapSymptomToExerciseCategory(s.bodyPart));

  // Add core exercises to most rehabilitation plans
  if (!bodyParts.includes("core")) {
    bodyParts.push("core");
  }

  // For each week in the plan
  for (let weekNum = 1; weekNum <= totalWeeks; weekNum++) {
    const weekPlan = planData.weekly_plan.find((w) => w.week === weekNum) || {
      week: weekNum,
      focus: "Rehabilitation",
      exercise_count: 4,
    };

    const weeklyExercises = [];
    const exercisesToAssign = weekPlan.exercise_count || 4;

    // Select exercises for the week based on body parts
    const selectedExercises = selectExercisesForWeek(bodyParts, exercisesToAssign, weekNum, totalWeeks);

    // Calculate dates for the week starting from plan start date
    const weekStartDate = new Date(startDate);
    weekStartDate.setDate(weekStartDate.getDate() + (weekNum - 1) * 7);

    // Assign dates to exercises spread throughout the week
    selectedExercises.forEach((exercise, index) => {
      const exerciseDate = new Date(weekStartDate);
      exerciseDate.setDate(exerciseDate.getDate() + (index % 7)); // Spread across days of the week

      const exerciseWithDate = {
        ...exercise,
        bodyPart:
          exercise.bodyPart ||
          mapExerciseCategoryToSymptom(
            Object.keys(exerciseList).find((k) => exerciseList[k].some((e) => e.exerciseType === exercise.exerciseType))
          ),
        scheduledDate: exerciseDate,
      };

      weeklyExercises.push(exerciseWithDate);
      allExercises.push(exerciseWithDate);
    });

    // Create the weekly structure for the recovery plan
    weeklyStructure.push({
      weekNumber: weekNum,
      focus: weekPlan.focus || `Week ${weekNum} Rehabilitation`,
      exercises: weeklyExercises.map((ex) => ({
        id: `ex_${Math.random().toString(36).substr(2, 9)}`,
        name: ex.exerciseType,
        description: ex.description,
        frequency: ex.duration,
        bodyPart: ex.bodyPart,
        isCompleted: false,
        scheduledDate: ex.scheduledDate,
      })),
    });
  }

  return {
    exercises: allExercises,
    weeks: weeklyStructure,
    totalWeeks,
  };
}

// Select appropriate exercises for the week from our predefined list
function selectExercisesForWeek(bodyParts, count, currentWeek, totalWeeks) {
  const selectedExercises = [];
  const phase = currentWeek <= totalWeeks / 2 ? "early" : "late";

  // Distribute exercises among body parts
  while (selectedExercises.length < count) {
    for (const bodyPart of bodyParts) {
      if (selectedExercises.length >= count) break;

      const availableExercises = exerciseList[bodyPart] || [];
      if (availableExercises.length === 0) continue;

      // Select different exercises based on phase (early vs late in rehabilitation)
      let exercisePool = availableExercises;
      if (phase === "early") {
        // In early phase, prefer easier exercises
        exercisePool = availableExercises.filter((e) => e.difficulty <= 2);
        if (exercisePool.length === 0) exercisePool = availableExercises;
      } else {
        // In later phase, prefer more challenging exercises
        exercisePool = availableExercises.filter((e) => e.difficulty >= 2);
        if (exercisePool.length === 0) exercisePool = availableExercises;
      }

      // Pick an exercise that hasn't been selected yet
      const exerciseIndex = Math.floor(Math.random() * exercisePool.length);
      const selectedExercise = exercisePool[exerciseIndex];

      // Check if this exercise type is already selected
      if (!selectedExercises.some((e) => e.exerciseType === selectedExercise.exerciseType)) {
        selectedExercises.push({
          ...selectedExercise,
          bodyPart: bodyPart,
        });
      }
    }
  }

  return selectedExercises.slice(0, count);
}

// Map symptom body part to exercise category
function mapSymptomToExerciseCategory(bodyPart) {
  const bodyPartLower = bodyPart.toLowerCase();

  if (bodyPartLower.includes("neck")) return "neck";
  if (bodyPartLower.includes("shoulder")) return "shoulder";
  if (bodyPartLower.includes("back")) return "back";
  if (bodyPartLower.includes("hip")) return "hip";
  if (bodyPartLower.includes("knee")) return "knee";
  if (bodyPartLower.includes("ankle") || bodyPartLower.includes("foot")) return "ankle";
  if (bodyPartLower.includes("wrist") || bodyPartLower.includes("hand")) return "wrist";
  if (bodyPartLower.includes("core") || bodyPartLower.includes("abdominal")) return "core";

  // Default to core exercises if no match
  return "core";
}

// Convert exercise category back to symptom body part name
function mapExerciseCategoryToSymptom(category) {
  switch (category) {
    case "neck":
      return "Neck";
    case "shoulder":
      return "Shoulder";
    case "back":
      return "Back";
    case "hip":
      return "Hip";
    case "knee":
      return "Knee";
    case "ankle":
      return "Ankle/Foot";
    case "wrist":
      return "Wrist/Hand";
    case "core":
      return "Core";
    default:
      return "General";
  }
}

// Helper function to safely extract a field from text
function extractField(text, fieldName) {
  const regex = new RegExp(`${fieldName}\\s*(.+?)(?=\\n|$)`, "i");
  const match = text.match(regex);
  return match ? match[1].trim() : null;
}
