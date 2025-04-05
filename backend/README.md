# PT Tracker Backend

This is the backend server for the Physical Therapy Home Exercise Tracker application. It provides a RESTful API for user authentication, symptom tracking, and exercise management.

## Table of Contents

- [Setup](#setup)
- [Models](#models)
- [API Routes](#api-routes)
- [Admin Panel](#admin-panel)

## Setup

### Prerequisites

- Node.js (v14 or higher)
- MongoDB (local or Atlas)
- npm or yarn

### Installation

1. Install dependencies:
```bash
npm install
```

2. Create a `.env` file in the backend directory with the following variables:
```env
PORT=3333
MONGODB_URI=mongodb://localhost:27017/pt-tracker
JWT_SECRET=your-secret-key-here
```

3. Start the development server:
```bash
npm run dev
```

The server will start on http://localhost:3333

## Models

### User
```javascript
{
  name: String,
  email: String,
  password: String (hashed),
  dateJoined: Date,
  lastLogin: Date,
  symptoms: [Symptom]
}
```

### Symptom
```javascript
{
  bodyPart: String,
  severities: [{
    value: Number (0-10),
    date: Date
  }],
  exercises: [Exercise],
  user: User
}
```

### Exercise
```javascript
{
  exerciseType: String,
  date: Date,
  completed: Boolean,
  symptom: Symptom,
  user: User
}
```

## API Routes

### Authentication

#### Register User
- **POST** `/api/users/register`
- **Body:**
```json
{
  "name": "string",
  "email": "string",
  "password": "string"
}
```

#### Login
- **POST** `/api/users/login`
- **Body:**
```json
{
  "email": "string",
  "password": "string"
}
```

#### Get Current User
- **GET** `/api/users/me`
- **Headers:** `Authorization: Bearer <token>`

### Symptoms

#### Create Symptom
- **POST** `/api/symptoms`
- **Headers:** `Authorization: Bearer <token>`
- **Body:**
```json
{
  "bodyPart": "string"
}
```

#### Get All Symptoms
- **GET** `/api/symptoms`
- **Headers:** `Authorization: Bearer <token>`

#### Get Single Symptom
- **GET** `/api/symptoms/:id`
- **Headers:** `Authorization: Bearer <token>`

#### Update Symptom
- **PATCH** `/api/symptoms/:id`
- **Headers:** `Authorization: Bearer <token>`
- **Body:**
```json
{
  "bodyPart": "string"
}
```

#### Delete Symptom
- **DELETE** `/api/symptoms/:id`
- **Headers:** `Authorization: Bearer <token>`

### Exercises

#### Create Exercise
- **POST** `/api/exercises`
- **Headers:** `Authorization: Bearer <token>`
- **Body:**
```json
{
  "exerciseType": "string",
  "symptom": "symptom_id"
}
```

#### Get All Exercises
- **GET** `/api/exercises`
- **Headers:** `Authorization: Bearer <token>`

#### Get Single Exercise
- **GET** `/api/exercises/:id`
- **Headers:** `Authorization: Bearer <token>`

#### Update Exercise
- **PATCH** `/api/exercises/:id`
- **Headers:** `Authorization: Bearer <token>`
- **Body:**
```json
{
  "exerciseType": "string",
  "completed": boolean
}
```

#### Delete Exercise
- **DELETE** `/api/exercises/:id`
- **Headers:** `Authorization: Bearer <token>`

## Admin Panel

The backend includes a simple admin panel for testing the API endpoints.

### Setup

1. Navigate to the admin directory:
```bash
cd admin
```

2. Install dependencies:
```bash
npm install
```

3. Start the admin panel:
```bash
npm start
```

The admin panel will be available at http://localhost:3330

### Features

- User registration and login
- CRUD operations for symptoms
- CRUD operations for exercises
- Real-time API response display
- JWT token management

## Error Handling

The API returns appropriate HTTP status codes and error messages:

- 200: Success
- 201: Created
- 400: Bad Request
- 401: Unauthorized
- 404: Not Found
- 500: Server Error

Error responses follow this format:
```json
{
  "error": "Error message"
}
```

## Security

- Passwords are hashed using bcrypt
- JWT tokens are used for authentication
- Protected routes require valid JWT token
- Input validation for email and password
- CORS enabled for development 