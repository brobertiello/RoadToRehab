const express = require("express");
const router = express.Router();
const geminiController = require("../controllers/geminiController");
const auth = require("../middleware/auth");

// All routes are protected
router.use(auth);

router.post("/chat", geminiController.chatInteraction);

module.exports = router;
