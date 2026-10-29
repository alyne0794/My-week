# My Week – Weekly Class Timetable

## Project Description

My Week is a Flutter application that helps students organize their weekly class timetable. Students can view their courses for each day, check class times, and calculate their daily and weekly scheduled class hours.

## Features

- View the weekly timetable from Monday to Sunday.
- Add new courses with a course name, day, start time, and end time.
- Edit existing courses.
- Delete courses with confirmation and undo.
- Automatically sort courses by start time.
- Detect overlapping classes and display clash warnings.
- Calculate daily and weekly scheduled class hours.
- Validate time inputs using the 24-hour HH:MM format.
- Display a message when a day has no scheduled classes.

## Technologies Used

- Flutter
- Dart
- Material Design

## How to Run the Project

1. Install Flutter and set up the development environment.
2. Open the project folder in Android Studio or VS Code.
3. Open the terminal in the project folder.
4. Run `flutter pub get`.
5. Run `flutter run -d edge` to launch the app in Microsoft Edge.

## Screenshots

Create a folder named `screenshots` and add at least four screenshots of your completed application.

- `screenshots/weeklyss-view.png` – Weekly timetable.
- `screenshots/course-form.png` – Add or edit course form.
- `screenshots/clash-detection.png` – Overlapping course warnings.
- `screenshots/time-validation.png` – Invalid time validation message.

## Think Questions

### 1. How does the app detect a clash between two courses?

Two courses clash when they are scheduled on the same day and their time intervals overlap. If one course ends exactly when another begins, they do not clash.

### 2. Why does the app store times as minutes instead of text?

Storing times as minutes makes it easier to compare course times, sort courses, detect clashes, and calculate durations. For example, 08:30 is stored as 510 minutes after midnight.
