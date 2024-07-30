# Location Saver

Location Saver is a Flutter application that allows users to save and manage their favorite locations using Google Maps integration. This app provides a user-friendly interface for adding, viewing, editing, and deleting location markers, along with authentication features for user accounts.

## Features

- User Authentication:
  - Email/Password sign-up and login
  - Google Sign-In integration
- Google Maps Integration:
  - Interactive map for adding and viewing locations
  - Custom markers for different location categories
- Location Management:
  - Add new locations with custom names and categories
  - View saved locations on the map
  - Edit existing location details
  - Delete saved locations
- Search Functionality:
  - Search for places or coordinates
  - Autocomplete suggestions for place searches
- Responsive UI:
  - Clean and intuitive user interface
  - Supports both light and dark themes (system default)

## Technical Stack

- Flutter: Frontend framework for building cross-platform applications
- Firebase:
  - Firebase Authentication for user management
  - Cloud Firestore for storing location data
- Google Maps Flutter plugin for map integration
- Provider package for state management
- http package for making API requests
- geolocator package for handling device location
- google_sign_in package for Google authentication

## Project Structure

The project is organized into several key files and directories:

- `lib/`:
  - `main.dart`: Entry point of the application
  - `pages/`:
    - `authPage.dart`: Handles user authentication (login/signup)
    - `locationsListPage.dart`: Displays the list of saved locations
    - `addLocationPage.dart`: Allows users to add new locations
  - `components/`: Contains reusable UI components
  - `provider/`:
    - `locationsProvider.dart`: Manages the state of locations using the Provider pattern


## Usage

1. Launch the app and sign in or create a new account.
2. Use the map to navigate to a desired location.
3. Tap the floating action button to add a new location marker.
4. Fill in the location details (name and category) and save.
5. View your saved locations in the list view.
6. Edit or delete locations by swiping left or right on the location items.


## Contact

For any questions or feedback, please open an issue on the GitHub repository or contact the maintainer directly.
