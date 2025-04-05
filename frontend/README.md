# PT Tracker iOS App

This is the frontend iOS application for PT Tracker, which allows users to track their physical therapy journey.

## Features

- User authentication (login and registration)
- Dashboard for accessing tracking features
- Connection to MongoDB backend

## Prerequisites

- Xcode 13.0+
- iOS 15.0+
- Swift 5.5+
- Running backend server on port 3001

## Setup Instructions

1. Clone this repository
2. Open the `PTTracker.xcodeproj` file in Xcode
3. Make sure the backend server is running on port 3001
4. Build and run the app in Xcode

## App Structure

- **Views**: User interface components
  - `LandingView`: Initial view with login and register buttons
  - `LoginView`: Login form
  - `RegisterView`: Registration form
  - `DashboardView`: Main screen after authentication

- **Models**: Data structures
  - `User`: User model matching backend schema

- **Services**: Backend connection
  - `AuthManager`: Handles authentication with the backend

- **Utils**: Helper utilities
  - `NetworkUtils`: Network configuration helpers

## Backend Connection

The app connects to the Node.js backend running on `http://localhost:3001`. For development purposes, the app allows insecure HTTP connections to localhost. 