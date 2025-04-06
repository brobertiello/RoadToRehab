# PT Tracker Backend

This is the backend server for the Physical Therapy Tracker application. It provides a RESTful API for user authentication, symptom tracking, and exercise management.

## Table of Contents

- [Setup](#setup)
- [Environment Variables](#environment-variables)
- [API Documentation](#api-documentation)
- [Models](#models)
- [Security](#security)
- [Error Handling](#error-handling)
- [Admin Panel](#admin-panel)
- [Development](#development)

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
PORT=3001
MONGODB_URI=your_mongodb_uri
JWT_SECRET=your_jwt_secret
GEMINI_API_KEY=your_gemini_api_key
```

3. Start the development server:
```bash
npm run dev
```

The server will start on http://localhost:3001 (or your specified PORT)

## Environment Variables

- `PORT`: Server port number (default: 3001)
- `MONGODB_URI`: MongoDB connection string
- `JWT_SECRET`: Secret key for JWT token generation
- `GEMINI_API_KEY`: API key for Gemini AI integration

## API Documentation

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
- **Response:** User object with JWT token

#### Login
- **POST** `/api/users/login`
- **Body:**
```json
{
  "email": "string",
  "password": "string"
}
```
- **Response:** User object with JWT token

#### Get Current User
- **GET** `/api/users/me`
- **Headers:** `Authorization: Bearer <token>`
- **Response:** Current user object

### Symptoms

#### Create Symptom
- **POST** `/api/symptoms`
- **Headers:** `Authorization: Bearer <token>`
- **Body:**
```json
{
  "bodyPart": "string",
  "severity": {
    "value": number,
    "date": "string"
  }
}
```

#### Get All Symptoms
- **GET** `/api/symptoms`
- **Headers:** `Authorization: Bearer <token>`
- **Query Parameters:**
  - `sort`: Sort order (asc/desc)
  - `limit`: Number of results
  - `page`: Page number

#### Get Single Symptom
- **GET** `/api/symptoms/:id`
- **Headers:** `Authorization: Bearer <token>`

#### Update Symptom
- **PATCH** `/api/symptoms/:id`
- **Headers:** `Authorization: Bearer <token>`
- **Body:**
```json
{
  "bodyPart": "string",
  "severity": {
    "value": number,
    "date": "string"
  }
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
  "name": "string",
  "description": "string",
  "sets": number,
  "reps": number,
  "symptomId": "string"
}
```

#### Get All Exercises
- **GET** `/api/exercises`
- **Headers:** `Authorization: Bearer <token>`
- **Query Parameters:**
  - `sort`: Sort order (asc/desc)
  - `limit`: Number of results
  - `page`: Page number

#### Get Single Exercise
- **GET** `/api/exercises/:id`
- **Headers:** `Authorization: Bearer <token>`

#### Update Exercise
- **PATCH** `/api/exercises/:id`
- **Headers:** `Authorization: Bearer <token>`
- **Body:**
```json
{
  "name": "string",
  "description": "string",
  "sets": number,
  "reps": number,
  "completed": boolean
}
```

#### Delete Exercise
- **DELETE** `/api/exercises/:id`
- **Headers:** `Authorization: Bearer <token>`

## Models

### User
```typescript
{
  name: string;
  email: string;
  password: string; // hashed
  dateJoined: Date;
  lastLogin: Date;
  symptoms: Symptom[];
}
```

### Symptom
```typescript
{
  bodyPart: string;
  severities: {
    value: number; // 0-10
    date: Date;
  }[];
  exercises: Exercise[];
  user: User;
}
```

### Exercise
```typescript
{
  name: string;
  description: string;
  sets: number;
  reps: number;
  completed: boolean;
  symptom: Symptom;
  user: User;
}
```

## Security

- Password hashing using bcrypt
- JWT-based authentication
- Protected routes with middleware
- Input validation and sanitization
- Rate limiting on authentication routes
- CORS configuration
- HTTP headers security
- MongoDB injection prevention

## Error Handling

All API endpoints return appropriate HTTP status codes:

- 200: Success
- 201: Created
- 400: Bad Request
- 401: Unauthorized
- 403: Forbidden
- 404: Not Found
- 500: Server Error

Error responses follow this format:
```json
{
  "error": {
    "message": "Error description",
    "code": "ERROR_CODE"
  }
}
```

## Admin Panel

The backend includes an admin panel for API testing and management:

### Setup
1. Navigate to admin directory:
```bash
cd admin
```

2. Install dependencies:
```bash
npm install
```

3. Start admin panel:
```bash
npm start
```

Access the panel at http://localhost:3330

### Features
- User management
- Symptom tracking overview
- Exercise management
- API testing interface
- Real-time response monitoring
- JWT token management

## Development

### Scripts
- `npm run dev`: Start development server with hot reload
- `npm start`: Start production server
- `npm test`: Run tests
- `npm run lint`: Run linter
- `npm run build`: Build for production

### Best Practices
1. Follow Node.js and Express best practices
2. Write clear documentation
3. Use TypeScript for type safety
4. Implement proper error handling
5. Write unit tests
6. Follow security guidelines 