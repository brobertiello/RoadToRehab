const Symptom = require("../models/Symptom");

exports.createSymptom = async (req, res) => {
  try {
    // Handle severities with notes
    if (!req.body.severities || !Array.isArray(req.body.severities) || req.body.severities.length === 0) {
      // If no severities are provided, create one from the request data
      const severity = {
        value: req.body.severity || 0,
        date: new Date(),
      };

      // If notes are provided for the symptom, include them in the severity
      if (req.body.notes) {
        severity.notes = req.body.notes;
      }

      req.body.severities = [severity];
    }

    const symptom = new Symptom({
      ...req.body,
      user: req.user._id,
    });
    await symptom.save();
    res.status(201).json(symptom);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getSymptoms = async (req, res) => {
  try {
    const symptoms = await Symptom.find({ user: req.user._id }).populate("exercises");
    res.json(symptoms);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getSymptom = async (req, res) => {
  try {
    const symptom = await Symptom.findOne({
      _id: req.params.id,
      user: req.user._id,
    }).populate("exercises");

    if (!symptom) {
      return res.status(404).json({ error: "Symptom not found" });
    }

    res.json(symptom);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.updateSymptom = async (req, res) => {
  try {
    // Get the existing symptom first
    const existingSymptom = await Symptom.findOne({
      _id: req.params.id,
      user: req.user._id,
    });

    if (!existingSymptom) {
      return res.status(404).json({ error: "Symptom not found" });
    }

    // Handle notes update separately from severities
    const updates = {};

    // If notes are provided, update them
    if (req.body.notes !== undefined) {
      updates.notes = req.body.notes;
    }

    // If a new severity is provided, add it to the existing severities array
    if (req.body.severities && req.body.severities.length > 0) {
      // Ensure notes are included in the severity if provided
      if (req.body.notes && !req.body.severities[0].notes) {
        req.body.severities[0].notes = req.body.notes;
      }

      // Use $push to add the new severity to the existing array
      await Symptom.updateOne(
        { _id: req.params.id, user: req.user._id },
        {
          $push: { severities: { $each: req.body.severities } },
          ...updates, // Include any other updates (like notes)
        }
      );
    } else if (Object.keys(updates).length > 0) {
      // If only non-severity updates exist, apply them
      await Symptom.updateOne({ _id: req.params.id, user: req.user._id }, updates);
    }

    // Get the updated symptom to return
    const symptom = await Symptom.findOne({
      _id: req.params.id,
      user: req.user._id,
    });

    res.json(symptom);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.deleteSymptom = async (req, res) => {
  try {
    const symptom = await Symptom.findOneAndDelete({
      _id: req.params.id,
      user: req.user._id,
    });

    if (!symptom) {
      return res.status(404).json({ error: "Symptom not found" });
    }

    res.json(symptom);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};
