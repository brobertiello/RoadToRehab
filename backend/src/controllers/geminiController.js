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
