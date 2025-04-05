# PT Tracker

A comprehensive Physical Therapy Tracking application that helps users monitor their recovery journey.

## Project Structure

This project consists of three main components:

1. **Backend** - A Node.js/Express MongoDB API for data storage and retrieval
2. **Frontend** - A Swift iOS app for tracking symptoms and physical therapy progress
3. **PoseDetection** - A Swift app that uses the device camera to detect human body poses

## Backend (MongoDB & Express.js)

The backend handles:

- User authentication (registration, login)
- Symptom tracking (create, read, update, delete)
- Exercise management

To run the backend:

```bash
cd backend
npm install
node src/index.js
```

The server will run on port 3001.

## Frontend (Swift iOS App)

The iOS app provides:

- User registration and login with persistent authentication
- Dashboard with tabs for Profile, Symptoms, Recovery Plan, and Settings
- Symptom tracking with selectable body parts and pain levels
- Clean, intuitive user interface

To run the frontend:

```bash
cd frontend
open PTTracker.xcodeproj
```

Then build and run the app in Xcode.

## PoseDetection (Swift Camera App)

A separate Swift app that:

- Uses the device camera
- Detects human body positioning
- Analyzes physical therapy poses

## Setup Instructions

1. Clone this repository
2. Start the backend server:
   ```
   cd backend
   npm install
   node src/index.js
   ```
3. Open the frontend app in Xcode:
   ```
   cd frontend
   open PTTracker.xcodeproj
   ```
4. Build and run the app on a simulator or device

## Features

- **User Authentication**: Register and login functionality with secure token storage
- **Symptom Tracking**: Record and monitor symptoms by body part and severity
- **Persistent Authentication**: Stay logged in even after app restarts
- **Profile Management**: View and manage user information
- **Clean UI**: Intuitive interface for easy navigation and data entry

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
