# My Week – Weekly Timetable App

## 1. Project Overview

My Week is a Flutter-based weekly timetable application that helps students organize and manage their academic schedules.

The application allows users to create personal accounts, add courses, view their weekly timetables, edit course information, and delete courses.

It uses Firebase to authenticate users and Firestore to store course information securely.

## 2. Features

- User registration and login.
- Secure user authentication using Firebase Authentication.
- Add new courses to a weekly timetable.
- View courses organized by day.
- Edit existing course information.
- Delete courses.
- Save course information in Firebase Firestore.
- Keep course information after logging out and signing back in.
- Separate timetables for different users.

## 3. Technologies Used

- **Flutter:** Application development framework.
- **Dart:** Programming language.
- **Firebase Authentication:** User registration and login.
- **Cloud Firestore:** Cloud database for storing course information.
- **Android Studio:** Development environment.

## 4. How to Run the Project

1. Install Flutter and Android Studio.
2. Clone or download this repository.
3. Open the project in Android Studio.
4. Run the following command to install dependencies:

   ```bash
   flutter pub get
   ```

5. Make sure the Firebase configuration files are correctly configured.
6. Run the application:

   ```bash
   flutter run
   ```

## 5. Database Structure

The application uses Cloud Firestore.

Each authenticated user has a separate collection of courses:

```text
users
  └── userId
       └── courses
            ├── courseId
            ├── courseId
            └── courseId
```

Each user can only access their own course information through the application's authentication and Firestore security rules.

## 6. Testing

The following features have been tested successfully:

- User registration and login.
- Adding courses.
- Viewing saved courses.
- Editing courses.
- Deleting courses.
- Saving and retrieving data from Firestore.
- Keeping course data after logging out and signing in again.
- Separating course information between different user accounts.

## 7. Project Purpose

The purpose of My Week is to help students manage their academic schedules more easily, stay organized, and keep track of their weekly classes.

## 8. Author

Developed as a student project using Flutter, Dart, and Firebase.