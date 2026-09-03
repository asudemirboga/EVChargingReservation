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
| --- | ---: |
| RMSE | 0.1564 |
| MAE | 0.0754 |
| R² | 0.841 |

## Setup

1. Install the iOS dependencies:

```bash
pod install
```

2. Open `EVChargingReservation.xcworkspace` in Xcode.

3. Add your own Firebase `GoogleService-Info.plist`.

4. Copy `Secrets.example.plist` as `Secrets.plist` and provide:
   - `GoogleMapsPlatformAPIKey`
   - `MLBackendHost`

5. Start the prediction backend:

```bash
cd backend
pip install -r requirements.txt
python server.py
```

> Firebase and API configuration files containing credentials are intentionally excluded from this repository.

## Limitations

This project is an academic prototype rather than a production charging platform.

The prediction model was trained using historical charging station data, and the ML backend uses a lightweight TCP server intended for development and testing. Reservation validation and creation are separate operations, so simultaneous reservation requests are not protected by an atomic transaction.

## Project Report

For more details about the dataset, machine learning model, system design, implementation, and evaluation, see the **[Project Report](./projectReport.pdf)**.

## Author

**Asude Beyza Demirboga** 
