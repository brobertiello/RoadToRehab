# PT Tracker iOS App

This is the frontend iOS application for PT Tracker, which allows users to track their physical therapy journey.

## Features

- **User Authentication**
  - Registration and login functionality
  - Persistent authentication using iOS Keychain
  - Automatic session restoration on app restart
  
- **Dashboard with Multiple Tabs**
  - Profile: View user information
  - Symptoms: Track and manage pain symptoms
  - Recovery Plan: View personalized recovery plans (placeholder for future functionality)
  - Settings: Configure app preferences and logout

- **Symptom Tracking**
  - Add symptoms for specific body parts (Neck, Shoulder, Wrist, Back, Hip, Knee, Ankle)
  - Rate pain severity on a scale of 0-10
  - Update symptom pain levels over time
  - Delete symptoms when resolved
  - Visual representation of pain levels with color-coded indicators

- **Backend Integration**
  - Real-time synchronization with MongoDB backend
  - Secure API communication with token authentication
  - Offline capability with local data caching

## Prerequisites

- Xcode 13.0+
- iOS 15.0+
- Swift 5.5+
- Running backend server on port 3001

## Setup Instructions

1. Ensure the backend server is running:
   ```
   cd ../backend
   node src/index.js
   ```

2. Open the Xcode project:
   ```
   cd frontend
   open PTTracker.xcodeproj
   ```

3. Build and run the app in Xcode

## Project Structure

- **Views**: User interface components
  - `LandingView`: Initial view with login and register buttons
  - `LoginView`: Login form
  - `RegisterView`: Registration form
  - `DashboardView`: Main app container with tab navigation
  - `ProfileView`: Shows user information
  - `SymptomsView`: Lists user's symptoms and allows management
  - `AddSymptomView`: Form to add new symptoms
  - `UpdateSymptomView`: Form to update symptom severity
  - `RecoveryPlanView`: Placeholder for future functionality
  - `SettingsView`: App settings and logout

- **Models**: Data structures
  - `User`: User model matching backend schema
  - `Symptom`: Symptom model with severity tracking
  - `Severity`: Model for tracking pain severity over time

- **Services**: Backend connection
  - `AuthManager`: Handles authentication with persistent tokens
  - `SymptomService`: API calls for symptom management

- **ViewModels**: Business logic
  - `SymptomsViewModel`: Manages symptom data and operations

- **Utils**: Helper utilities
  - `KeychainHelper`: Secure storage for authentication data
  - `NetworkUtils`: Network configuration helpers

## Security

The app implements several security features:
- Secure storage of authentication tokens in iOS Keychain
- Token-based API authentication
- Proper error handling and validation

## Backend Connection

The app connects to the Node.js backend running on `http://localhost:3001`. For development purposes, the app allows insecure HTTP connections to localhost. 