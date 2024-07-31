# IronJournal (Overhaul) - Code Samples
- Below are code samples and details for my app, Iron Journal's unrelased overhaul.


## Features
### Exercises that are Fast and Easy to Build

- **Quick Build Sets**: Iron Journal allows users to quickly build sets. It saves user inputs to auto-fill sets as you build.
- **Cached Build History**: If the user needs to go back to edit inputs are auto filled up till the most current point.
- **Link Personal Records (PRs)**: Seamlessly update your records and track trends across the exercises that matter most.
- **Muscle Group Linking**: Easily link muscle groups to your exercises and receive reports on the number of sets performed for each, ensuring your training is optimal.

### Customizable Goals for Workouts

- **Rest Times**: Customize rest times in seconds or minutes.
- **Exertion Tracking**: Optionally track exertion using RPE or RIR.
- **Reps**: Track reps to failure or by specific numbers.
- **Weight**: Record weights in lbs/kgs or as a percentage of your one-rep max (1RM).

### Designed to Integrate Seamlessly into Workouts

- **Minimal Scrolling**: Iron Journal's phase system allows users to quickly input their workout data with minimal scrolling.
- **On-the-Go Editing**: Update exercise and set goals while work outs are running.
- **Add Exercises and Sets**: Build new workouts as you go, lifting in any order you prefer with Iron Journal's exercise selector.

### Powerful Workout History Tools

- **Side-by-Side Set Comparison**: View sets side by side to compare workout data.
- **Filtering**: Filter sets by exercise or by the order performed.
- **Graphs and Trends**: Visualize trends in workout goals, exertion, reps, and weight across your workout history on a per-workout basis.
- **Specialized Metrics**: Total tonage, goals accompished, overall sets, reps performed metrics available for every workout summary.

### Additional Features

- **Export Workouts**: Export workouts to Excel-compatible files.
- **Customizable Animations**: Optional screen animations to enhance user experience.
- **Customizable Accent Colors**: Personalize the app with your favorite accent colors.
- **Metric Support**: Support for both imperial and metric.


## Working App Demo (Pre-Alpha)
![App Demo](https://github.com/JMiller7334/IronJournal-Code-Samples/blob/main/Demo/IJ-Demo.gif)

---
# Tech Stack

Iron Journal is built with the following technologies:

- **Swift**: Programming language.
- **UIKit (Storyboard)**: For building the main user interface.
- **SwiftUI (Embedded)**: Used for the settings screen and graphs.
- **UserDefaults**: For persisting basic user settings.
- **Firebase Auth**: For managing user accounts.
- **Realm**: Primary local database for data storage.
- **CocoaPods**: Dependency management tool.
- **Design Pattern**: Model-View-ViewModel (MVVM).
- **Dependency Injection**: For managing dependencies.



# Documentation

## How It Works

Iron Journal runs on a slightly modified MVVM design pattern. The view subscribes to changes in a custom model referred to as the screen state, which holds all the data that the view presents to the user. When the user interacts with the UI, the view calls functions in the ViewModel. These functions update models and handle business logic. If all operations succeed, the ViewModel updates the screen state model with the appropriate data. The screen state then parses this data, prepares it for the view, and triggers the view to update.

## Deviations from MVVM Design Pattern

### Screen State Model:

- Provides a simple solution for using MVVM design pattern with Storyboards.
- Abstracts parsing logic from the ViewModel, reducing complexity.

### Component Models:

- Encapsulate logic for moderate to large-sized UI components.
- Act as a combination of a view and ViewModel to reduce the size of both the view and the ViewModel.
- Many components are reusable across multiple screens.



# Code Samples
### Build Exercise Screen:
* [View](https://github.com/JMiller7334/IronJournal-Code-Samples/blob/main/NewExerciseScreen/Views/ViewControllerNewExercise.swift)
* [ViewModel](https://github.com/JMiller7334/IronJournal-Code-Samples/blob/main/NewExerciseScreen/ViewModels/ViewModelNewExercise.swift)



## Other Info
### Expected Release:
* Spetember - October 2024

---



