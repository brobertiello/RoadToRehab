# PT Tracker iOS App

This is the frontend iOS application for PT Tracker, which allows users to track their physical therapy journey.

## Features

- **User Authentication**
  - Registration and login functionality
  - Secure token storage using iOS Keychain
  - Automatic session restoration on app restart
  
- **Dashboard with Multiple Tabs**
  - Profile: View and manage user information
  - Symptoms: Track and manage pain symptoms
  - Recovery Plan: View personalized recovery plans
  - Settings: Configure app preferences and logout

- **Symptom Tracking**
  - Add symptoms for specific body parts (Neck, Shoulder, Wrist, Back, Hip, Knee, Ankle)
  - Rate pain severity on a scale of 0-10
  - Update symptom pain levels over time
  - Delete symptoms when resolved
  - Visual representation of pain levels with color-coded indicators

- **Data Management**
  - Real-time synchronization with MongoDB backend
  - Secure API communication with JWT authentication
  - Offline capability with local data caching
  - Automatic retry for failed network requests

## Prerequisites

- Xcode 13.0+
- iOS 15.0+
- Swift 5.5+
- Running backend server (default port: 3001)

## Setup Instructions

1. Ensure the backend server is running:
   ```bash
   cd ../backend
   npm run dev
   ```

2. Open the Xcode project:
   ```bash
   cd frontend
   open PTTracker.xcodeproj
   ```

3. Build and run the app in Xcode

## Project Structure

- **Views**
  - `LandingView`: Initial view with login and register options
  - `LoginView`: User authentication form
  - `RegisterView`: New user registration form
  - `DashboardView`: Main tabbed interface
  - `ProfileView`: User profile management
  - `SymptomsView`: Symptom tracking and management
  - `AddSymptomView`: New symptom entry form
  - `UpdateSymptomView`: Symptom severity update form
  - `RecoveryPlanView`: Exercise and recovery tracking
  - `SettingsView`: App configuration and user preferences

- **Models**
  - `User`: User profile and authentication data
  - `Symptom`: Symptom tracking information
  - `Severity`: Pain level tracking over time
  - `Exercise`: Exercise tracking and management

- **ViewModels**
  - `AuthViewModel`: Authentication state management
  - `SymptomsViewModel`: Symptom data operations
  - `ProfileViewModel`: User profile management
  - `RecoveryViewModel`: Exercise and recovery tracking

- **Services**
  - `AuthManager`: JWT token and authentication handling
  - `APIService`: Backend API communication
  - `KeychainService`: Secure data storage
  - `CacheManager`: Local data caching

- **Utils**
  - `KeychainHelper`: Secure storage utilities
  - `NetworkUtils`: API configuration and networking
  - `DateFormatter`: Date handling utilities
  - `ValidationUtils`: Input validation helpers

## Security Features

- Secure storage of JWT tokens in iOS Keychain
- HTTPS communication with backend
- Input validation and sanitization
- Proper error handling and user feedback
- Automatic token refresh mechanism
- Secure password handling

## Error Handling

The app implements comprehensive error handling:
- Network connectivity issues
- Authentication failures
- API errors
- Data validation errors
- Offline mode fallback

## Development Guidelines

1. Follow Swift style guide and best practices
2. Use SwiftUI previews for UI development
3. Implement proper error handling
4. Write clear documentation
5. Test thoroughly before submitting PRs

## Testing

The app includes:
- Unit tests for business logic
- UI tests for critical user flows
- Network mocking for API tests
- Keychain interaction tests 