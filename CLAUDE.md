# Calories - Personal Health Tracking App

## Introduction

Calories is a comprehensive health tracking application built with SwiftUI, designed to help users monitor their daily calorie intake, exercise activities, and weight progress. The app combines food logging, exercise tracking, and weight management in a unified experience across iOS and watchOS platforms.

The application integrates with Apple's HealthKit to provide accurate BMR calculations and sync health data, while offering features like plant-based food tracking, motivational notifications, and visual progress charts.

## Features

### Core Functionality
- **Food Entry Logging**: Add and track daily food consumption with calorie counts
- **Exercise Tracking**: Log workouts and physical activities with calorie burn estimates
- **Weight Management**: Record and visualize weight changes over time with deficit tracking
- **Plant-Based Tracking**: Specialized plant food entry system with AI-generated imagery

### Smart Features
- **Meal-Based Suggestions**: Context-aware food recommendations based on time of day and history
- **Apple Watch Integration**: Simplified calorie tracking directly from your wrist
- **Visual Progress Charts**: Weekly charts showing weight trends and calorie deficits
- **Motivational Notifications**: Personalized daily messages based on progress
- **HealthKit Integration**: Seamless sync with Apple Health for BMR and activity data

### User Experience
- **Search & Quick Entry**: Fast food and exercise search with recent item suggestions
- **Historical Data**: View past entries and track long-term progress
- **Dark Mode Support**: Custom color scheme with brand theming
- **Accessibility**: Full VoiceOver support and accessibility identifiers

## Database Models

The app uses SwiftData with Core Data persistence, featuring three main entities:

### FoodEntry
- **calories**: `Double` - Caloric value of the food item
- **foodDescription**: `String` - Description or name of the food
- **timeConsumed**: `Date` - When the food was consumed
- **plants**: `[PlantEntry]` - Related plant-based items (many-to-many relationship)

### PlantEntry
- **name**: `String` - Unique plant name
- **timeConsumed**: `Date` - When the plant was consumed
- **imageData**: `Data?` - AI-generated image data (external storage)
- **foodEntries**: `[FoodEntry]` - Associated food entries (inverse relationship)

### ExerciseEntry
- **calories**: `Int32` - Calories burned during exercise
- **exerciseDescription**: `String` - Description of the exercise performed
- **timeExercised**: `Date` - When the exercise was performed

All entities include optimized fetch indexes on their respective time fields for efficient querying.

## Key User Flows

### Adding Food Entries
1. User taps "Add food" from main screen
2. App presents search interface with meal-time specific suggestions
3. User either selects from recent foods or searches for new items
4. App navigates to detailed entry screen with calorie input
5. User confirms entry, which syncs to HealthKit and updates meal view

### Exercise Logging
1. User taps "Add exercise" from main screen
2. App shows search interface with recent exercise suggestions
3. User selects or searches for exercise type
4. App presents detail screen for duration and intensity input
5. Calorie burn calculated and added to HealthKit upon confirmation

### Weight Recording
1. User taps "Record weight" to open weight tracking interface
2. App displays historical weight chart with deficit visualization
3. User adjusts current weight using +/- controls
4. App calculates weight change and shows total loss summary
5. Confirmation triggers celebratory confetti for weight loss achievements

### Plant Food Tracking
1. Accessed through specialized "Add Plant" flow
2. Network integration fetches plant data and generates AI imagery
3. Plants are linked to food entries for comprehensive nutrition tracking
4. Visual plant grid shows consumption frequency and variety

## Code Style

### Architecture Patterns
- **MVVM**: View-ViewModel separation with `@StateObject` and `@ObservedObject`
- **SwiftUI**: Declarative UI with custom modifiers and themes
- **Dependency Injection**: ViewModels receive dependencies through initializers
- **Protocol-Oriented**: `HealthStore` protocol enables testing with mock implementations

### Conventions
- **File Organization**: Features grouped in dedicated folders with co-located tests
- **Naming**: Descriptive names following Swift conventions (e.g., `AddFoodViewModel`, `RecordWeightView`)
- **Testing**: Comprehensive unit tests for ViewModels using `@testable import`
- **Accessibility**: Consistent use of `accessibilityIdentifier` for UI testing

### UI/UX Standards
- **Custom Font**: Avenir Next brand font applied consistently via `Font.brand`
- **Color Scheme**: Centralized color management through `Colours` enum
- **Responsive Design**: Adaptive layouts with proper spacing and padding
- **User Feedback**: Haptic feedback, progress indicators, and confirmation animations

### Development Practices
- **Environment Handling**: Separate configurations for UI testing, unit testing, and production
- **Date Overrides**: Testable date injection for consistent testing scenarios
- **Error Handling**: Graceful error states with user-friendly alerts
- **Performance**: Lazy loading, efficient Core Data queries, and optimized image storage