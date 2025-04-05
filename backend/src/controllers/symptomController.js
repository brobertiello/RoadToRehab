const Symptom = require('../models/Symptom');

exports.createSymptom = async (req, res) => {
  try {
    const symptom = new Symptom({
      ...req.body,
      user: req.user._id
    });
    await symptom.save();
    res.status(201).json(symptom);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getSymptoms = async (req, res) => {
  try {
    const symptoms = await Symptom.find({ user: req.user._id })
      .populate('exercises');
    res.json(symptoms);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getSymptom = async (req, res) => {
  try {
    const symptom = await Symptom.findOne({
      _id: req.params.id,
      user: req.user._id
    }).populate('exercises');
    
    if (!symptom) {
      return res.status(404).json({ error: 'Symptom not found' });
    }
    
    res.json(symptom);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.updateSymptom = async (req, res) => {
  try {
    const symptom = await Symptom.findOneAndUpdate(
      { _id: req.params.id, user: req.user._id },
      req.body,
      { new: true }
    );
    
    if (!symptom) {
      return res.status(404).json({ error: 'Symptom not found' });
    }
    
    res.json(symptom);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.deleteSymptom = async (req, res) => {
  try {
    const symptom = await Symptom.findOneAndDelete({
      _id: req.params.id,
      user: req.user._id
    });
    
    if (!symptom) {
      return res.status(404).json({ error: 'Symptom not found' });
    }
    
    res.json(symptom);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
}; 