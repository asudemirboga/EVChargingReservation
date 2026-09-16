# Smart EV Charging Slot Reservation

An iOS application that recommends EV charging stations based on the driver's battery level, estimated arrival time, predicted station availability, and existing reservations.

The project combines a **SwiftUI iOS application**, a **LightGBM machine learning model**, **Firebase**, and **Google Maps APIs** to provide dynamic charging station recommendations and slot reservations.

This project was originally developed as my undergraduate Computer Engineering graduation project at Yeditepe University.

## Overview

The application calculates the vehicle's usable driving range based on its battery level and vehicle information.

Charging stations within this range are evaluated using their estimated travel time and predicted availability at the expected arrival time. Existing reservations are also taken into account before the stations are ranked and presented to the user.

Users can reserve charging slots in 15 minute intervals. The predicted availability is adjusted according to existing reservations, and a reservation is accepted only if the adjusted availability remains above 50% throughout the selected period.

## Technologies

**iOS**

- Swift
- SwiftUI
- MVVM
- CoreLocation

**Services**

- Firebase Authentication
- Cloud Firestore
- Google Maps SDK
- Google Directions API

**Machine Learning & Backend**

- Python
- LightGBM
- pandas
- NumPy
- TCP sockets

## Model Performance

The LightGBM model predicts charging station availability using historical station usage and time based features.

| Metric | Result |
| ------ | ------ |
| RMSE | 0.1564 |
| MAE | 0.0754 |
| R² | 0.841 |

## Project Availability

This repository contains the source code of the project. The original Firebase database, API credentials, and service configuration files are not included. Therefore, the application cannot be run directly with the original project environment.

## Limitations

This project is an academic prototype rather than a production charging platform. The prediction model is based on historical charging station data and therefore does not represent a real time production prediction system. The backend was designed for development and testing purposes.

## Project Report

For more details about the dataset, machine learning model, system design, implementation, and evaluation, see the [**Project Report**](./projectReport.pdf).

## Author

**Asude Beyza Demirboga**
