/**
 * List of predefined exercises for the recovery plan
 * Exercises are organized by body part for easier filtering
 */

const exerciseList = {
  // Neck exercises
  neck: [
    {
      exerciseType: "Neck Stretches",
      description:
        "Slowly tilt your head toward your shoulder, using your hand to apply gentle pressure. Hold, then repeat on the opposite side.",
      duration: "Hold for 15-30 seconds, 3 sets per side, daily",
      difficulty: 2,
      precautions: "Avoid jerky movements and stop if you feel pain or dizziness.",
    },
    {
      exerciseType: "Chin Tucks",
      description:
        "While sitting or standing, gently draw your chin inward, creating a 'double chin.' Hold briefly then release.",
      duration: "Hold for 5 seconds, 10 repetitions, twice daily",
      difficulty: 1,
      precautions: "Keep the movement gentle and avoid pushing your head too far back.",
    },
    {
      exerciseType: "Neck Isometrics",
      description:
        "Place your palm against your forehead and push your head forward while resisting with your hand. Repeat with hand on back and sides of head.",
      duration: "Hold for 5-10 seconds, 5 repetitions in each direction, daily",
      difficulty: 3,
      precautions: "Use only gentle pressure and avoid if you have acute pain.",
    },
  ],

  // Shoulder exercises
  shoulder: [
    {
      exerciseType: "Pendulum Swing",
      description:
        "Bend at the waist, letting the affected arm hang down. Gently swing your arm in small circles, gradually increasing the size.",
      duration: "1-2 minutes per session, 3 times daily",
      difficulty: 1,
      precautions: "Keep the movement gentle and pain-free.",
    },
    {
      exerciseType: "Wall Slides",
      description:
        "Stand facing a wall with forearms against the wall. Slowly slide arms upward while maintaining contact with the wall.",
      duration: "10-15 repetitions, 2-3 sets, daily",
      difficulty: 2,
      precautions: "Keep shoulders relaxed and stop if you feel pinching or pain.",
    },
    {
      exerciseType: "External Rotation",
      description:
        "With elbow bent at 90° and tucked at your side, rotate your forearm outward while keeping elbow in place. Use a resistance band for added challenge.",
      duration: "12-15 repetitions, 2-3 sets, every other day",
      difficulty: 3,
      precautions: "Maintain proper form and avoid shrugging your shoulders.",
    },
    {
      exerciseType: "Scapular Retraction",
      description: "Sit or stand with arms at sides. Squeeze shoulder blades together, hold briefly, then relax.",
      duration: "Hold for 5 seconds, 15 repetitions, twice daily",
      difficulty: 2,
      precautions: "Focus on shoulder blade movement rather than arm movement.",
    },
  ],

  // Back exercises
  back: [
    {
      exerciseType: "Cat-Cow Stretch",
      description:
        "Start on hands and knees. Alternate between arching your back upward (cat) and letting it sag (cow), moving slowly with your breath.",
      duration: "10 repetitions, 2-3 sets, daily",
      difficulty: 2,
      precautions: "Keep the movement fluid and gentle, avoiding jerky motions.",
    },
    {
      exerciseType: "Bird Dog",
      description:
        "Start on hands and knees. Extend opposite arm and leg while maintaining a stable core, then alternate sides.",
      duration: "8-12 repetitions per side, 2-3 sets, daily",
      difficulty: 3,
      precautions: "Keep your back flat and core engaged throughout the movement.",
    },
    {
      exerciseType: "Prone Back Extension",
      description:
        "Lie face down with arms at sides. Gently lift chest off the floor while keeping neck neutral, then lower slowly.",
      duration: "8-10 repetitions, 2 sets, every other day",
      difficulty: 3,
      precautions: "Lift only as high as comfortable and avoid hyperextending your neck.",
    },
    {
      exerciseType: "Child's Pose",
      description:
        "Kneel with buttocks on heels, then bend forward reaching arms out in front, resting forehead on the floor.",
      duration: "Hold for 30-60 seconds, 3-5 repetitions, daily",
      difficulty: 1,
      precautions: "Widen knees if needed for comfort and breathe deeply throughout.",
    },
  ],

  // Hip exercises
  hip: [
    {
      exerciseType: "Hip Bridges",
      description:
        "Lie on your back with knees bent and feet flat. Lift hips toward ceiling, squeezing glutes at the top, then lower slowly.",
      duration: "10-15 repetitions, 2-3 sets, daily",
      difficulty: 2,
      precautions: "Keep movements controlled and avoid arching your lower back.",
    },
    {
      exerciseType: "Hip Flexor Stretch",
      description:
        "Kneel on one knee with other foot in front. Gently push hips forward until you feel a stretch in front of the hip/thigh of the kneeling leg.",
      duration: "Hold for 30 seconds, 3 repetitions per side, daily",
      difficulty: 2,
      precautions: "Keep your back straight and avoid leaning forward.",
    },
    {
      exerciseType: "Clamshells",
      description:
        "Lie on side with knees bent at 45°, feet together. Keeping feet touching, lift top knee while keeping pelvis stable.",
      duration: "15-20 repetitions per side, 2-3 sets, daily",
      difficulty: 2,
      precautions: "Focus on using hip muscles, not momentum, to lift the knee.",
    },
  ],

  // Knee exercises
  knee: [
    {
      exerciseType: "Straight Leg Raises",
      description:
        "Lie on your back with one knee bent and foot flat, the other leg straight. Tighten the quadriceps of the straight leg and lift it to the height of the opposite knee.",
      duration: "10-15 repetitions, 2-3 sets per leg, daily",
      difficulty: 2,
      precautions: "Keep your back flat against the floor throughout the exercise.",
    },
    {
      exerciseType: "Wall Slides with Ball",
      description:
        "Stand with back against wall, ball behind lower back. Slowly slide down into a partial squat, then return to standing.",
      duration: "10 repetitions, 2-3 sets, daily",
      difficulty: 3,
      precautions: "Don't bend knees beyond 90 degrees and keep knees aligned with feet.",
    },
    {
      exerciseType: "Hamstring Curls",
      description:
        "Stand holding onto a support. Bend one knee bringing heel toward buttocks, then lower slowly. Can add ankle weights for progression.",
      duration: "12-15 repetitions per leg, 2-3 sets, every other day",
      difficulty: 3,
      precautions: "Keep hips stable and avoid swinging the leg.",
    },
  ],

  // Ankle/Foot exercises
  ankle: [
    {
      exerciseType: "Ankle Circles",
      description:
        "Sit with leg extended. Rotate ankle clockwise, then counterclockwise, making full circles with the foot.",
      duration: "10 circles in each direction, 3 times daily",
      difficulty: 1,
      precautions: "Keep movements smooth and controlled.",
    },
    {
      exerciseType: "Heel Raises",
      description:
        "Stand with feet shoulder-width apart, holding onto a support if needed. Rise up onto toes, then lower slowly.",
      duration: "15-20 repetitions, 2-3 sets, daily",
      difficulty: 2,
      precautions: "Balance carefully and avoid jerky movements.",
    },
    {
      exerciseType: "Towel Scrunches",
      description: "Sit with foot flat on a towel. Scrunch the towel toward you using only your toes, then release.",
      duration: "3 sets of 15-20 scrunches, daily",
      difficulty: 2,
      precautions: "Stop if you feel cramping in the foot.",
    },
  ],

  // Wrist/Hand exercises
  wrist: [
    {
      exerciseType: "Wrist Flexion and Extension",
      description: "Rest forearm on a table with hand hanging off edge. Move hand up and down from the wrist.",
      duration: "15 repetitions in each direction, 2-3 sets, daily",
      difficulty: 2,
      precautions: "Keep movements slow and controlled.",
    },
    {
      exerciseType: "Grip Strengthening",
      description: "Squeeze a soft ball or stress ball in your hand, hold briefly, then release.",
      duration: "Hold for 5 seconds, 15 repetitions, 2-3 sets, daily",
      difficulty: 2,
      precautions: "Start with a soft object and progress to firmer ones as strength improves.",
    },
    {
      exerciseType: "Finger Springs",
      description:
        "Place a rubber band around fingers and thumb. Spread fingers against the resistance of the band, then relax.",
      duration: "15 repetitions, 2-3 sets, daily",
      difficulty: 2,
      precautions: "Use a band with appropriate resistance for your strength level.",
    },
  ],

  // Core exercises
  core: [
    {
      exerciseType: "Plank",
      description: "Support your body on forearms and toes, maintaining a straight line from head to heels.",
      duration: "Hold for 20-30 seconds, 3-5 repetitions, daily",
      difficulty: 3,
      precautions: "Keep back flat and avoid sagging hips or raising buttocks too high.",
    },
    {
      exerciseType: "Dead Bug",
      description:
        "Lie on back with arms extended toward ceiling and knees bent at 90°. Slowly lower opposite arm and leg while maintaining a flat back.",
      duration: "8-10 repetitions per side, 2-3 sets, daily",
      difficulty: 3,
      precautions: "Keep lower back pressed into the floor throughout the exercise.",
    },
    {
      exerciseType: "Pelvic Tilts",
      description:
        "Lie on back with knees bent. Tighten abdominals and gently tilt pelvis so lower back presses into floor, then release.",
      duration: "10-15 repetitions, 2-3 sets, daily",
      difficulty: 1,
      precautions: "Focus on subtle movement controlled by abdominal muscles.",
    },
  ],
};

module.exports = exerciseList;
