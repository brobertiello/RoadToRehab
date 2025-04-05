const User = require('../models/User');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

const generateAuthToken = (user) => {
  return jwt.sign({ _id: user._id }, process.env.JWT_SECRET, {
    expiresIn: '7d'
  });
};

exports.register = async (req, res) => {
  try {
    console.log('=== REGISTER ATTEMPT ===');
    const { name, email, password } = req.body;
    console.log(`User registration: ${name}, ${email}`);
    
    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      console.log(`Registration failed: Email already registered - ${email}`);
      return res.status(400).json({ error: 'Email already registered' });
    }

    const user = new User({
      name,
      email,
      password
    });

    await user.save();
    console.log(`User registered successfully: ${user._id}`);
    const token = generateAuthToken(user);

    res.status(201).json({ user, token });
  } catch (error) {
    console.error('Registration error:', error.message);
    res.status(400).json({ error: error.message });
  }
};

exports.login = async (req, res) => {
  try {
    console.log('=== LOGIN ATTEMPT ===');
    const { email, password } = req.body;
    console.log(`Login attempt: ${email}`);
    
    const user = await User.findOne({ email });
    if (!user) {
      console.log(`Login failed: No user found with email ${email}`);
      return res.status(401).json({ error: 'Invalid login credentials' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      console.log(`Login failed: Invalid password for ${email}`);
      return res.status(401).json({ error: 'Invalid login credentials' });
    }

    user.lastLogin = Date.now();
    await user.save();
    console.log(`User logged in successfully: ${user._id}`);

    const token = generateAuthToken(user);
    res.json({ user, token });
  } catch (error) {
    console.error('Login error:', error.message);
    res.status(400).json({ error: error.message });
  }
};

exports.getUser = async (req, res) => {
  try {
    console.log(`Fetching user data for user ID: ${req.user._id}`);
    const user = await User.findById(req.user._id).populate('symptoms');
    res.json(user);
  } catch (error) {
    console.error('Error fetching user:', error.message);
    res.status(400).json({ error: error.message });
  }
}; 