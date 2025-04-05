# Physical Therapy Home Exercise Tracker

The Physical Therapy Home Exercise Tracker is a web and mobile application designed to empower users in managing their recovery with personalized physical therapy plans. Users can indicate painful or discomforted body parts via an interactive body outline, receive tailored exercise routines and recovery schedules, track their form in real time using a webcam component, and ask questions through an AI-powered chatbot.

---

## Table of Contents

- [Overview](#overview)
- [Project Architecture](#project-architecture)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Backend Setup](#backend-setup)
  - [Frontend Setup](#frontend-setup)
- [Project Structure](#project-structure)
- [Future Features](#future-features)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

---

## Overview

This project aims to simplify the physical therapy process by providing users with a convenient tool to track their recovery progress. The application is divided into a frontend for user interaction and a backend for data management and API services.

---

## Project Architecture

### Frontend
- **Framework:** React with Next.js for enhanced performance and server-side rendering.
- **Styling & UI:** Material UI ensures consistent and modern design.
- **Animations:** Framer Motion is used for smooth transitions and animations.
- **Language:** TypeScript enhances type safety and improves the development experience.
- **Pages:**
  - Landing Page
  - Login Page
  - Registration Page
  - Dashboard (with subpages: Home, Symptoms, Recovery Plan, Profile, Logout, Settings)

*The frontend is hosted on port `3000`.*

### Backend
- **Database:** MongoDB is used to store user data, recovery plans, and other relevant information.
- **Server:** A Node.js-based server (using Express or a similar framework) handles API requests.
- **Configuration:** Ports and API keys are stored in environment variables for secure and flexible configuration.

*The backend is hosted on port `3001`.*

---

## Getting Started

Follow these steps to set up the development environment.

### Prerequisites
- **Node.js:** Version 14 or higher.
- **npm or yarn:** For dependency management.
- **MongoDB:** Either a local installation or a cloud instance (e.g., MongoDB Atlas).
- **Git:** For version control.

### Backend Setup

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/yourusername/physical-therapy-home-exercise-tracker.git
   cd physical-therapy-home-exercise-tracker/backend
   ```

2. **Install Dependencies:**
   ```bash
   npm install
   ```
   
3. **Configure Environment Variables:**
   Create a `.env` file in the backend directory with the following:
   ```env
   PORT=3001
   MONGODB_URI=your_mongodb_connection_string
   API_KEY=your_api_key_here
   ```
   
4. **Start the Backend Server:**
   ```bash
   npm start
   ```
   The backend server will be running at [http://localhost:3001](http://localhost:3001).

### Frontend Setup

1. **Navigate to the Frontend Directory:**
   Open a new terminal window:
   ```bash
   cd ../frontend
   ```

2. **Install Dependencies:**
   ```bash
   npm install
   ```

3. **Configure Environment Variables:**
   Create a `.env` file in the frontend directory with the following:
   ```env
   NEXT_PUBLIC_BACKEND_URL=http://localhost:3001
   PORT=3000
   ```

4. **Start the Frontend Development Server:**
   ```bash
   npm run dev
   ```
   The frontend will be accessible at [http://localhost:3000](http://localhost:3000).

---

## Project Structure

Below is a suggested structure for organizing your project:

```
physical-therapy-home-exercise-tracker/
├── backend/
│   ├── src/
│   │   ├── controllers/        # API logic controllers
│   │   ├── models/             # Mongoose models
│   │   ├── routes/             # API route definitions
│   │   └── index.js            # Main server file
│   ├── .env                    # Environment variables
│   ├── package.json
│   └── README.md
└── frontend/
    ├── pages/
    │   ├── index.tsx           # Landing Page
    │   ├── login.tsx           # Login Page
    │   ├── register.tsx        # Registration Page
    │   └── dashboard/
    │       ├── index.tsx       # Home
    │       ├── symptoms.tsx    # Symptoms
    │       ├── recovery.tsx    # Recovery Plan
    │       ├── profile.tsx     # Profile
    │       └── settings.tsx    # Settings
    ├── public/
    ├── styles/
    ├── .env                    # Environment variables
    ├── package.json
    └── README.md
```

---

## Future Features

- **Interactive Body Outline:** Allow users to select painful or discomforted areas.
- **Personalized Exercise Routines:** Generate tailored recovery plans based on user input.
- **Real-Time Form Tracking:** Implement a webcam component to monitor and correct exercise form.
- **AI-Powered Chatbot:** Provide users with immediate answers and additional guidance.

---

## Contributing

Contributions are welcome! Please follow these steps:
1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Commit your changes and push to your branch.
4. Open a pull request detailing your changes.

Ensure your contributions adhere to the project's coding standards and include appropriate documentation.
