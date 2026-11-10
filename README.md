# 🚌 AI-Integrated Fleet Management and Safety Analytics Suite

An AI-powered college transportation management application built with Flutter and Firebase. The system provides dedicated dashboards for students, drivers, and administrators, combining bus tracking, fleet operations, safety monitoring, and an AI-powered transport assistant in a single mobile application.

## 📌 Project Overview

The **AI-Integrated Fleet Management and Safety Analytics Suite** is designed to improve college transportation management by connecting students, drivers, and administrators through a centralized mobile application.

Students can view bus information, monitor transportation status, and interact with an AI assistant to obtain bus-related information. Drivers can share their GPS location through their mobile devices, while administrators can manage buses, routes, drivers, and safety alerts.

The application uses cloud-based services to synchronize transportation information between different user roles.

## 🎯 Objectives

- Provide a centralized platform for college transportation management.
- Enable students to access bus and route information.
- Allow drivers to share location data using their mobile GPS.
- Provide administrators with fleet management capabilities.
- Monitor driver speed and identify overspeeding conditions.
- Integrate an AI assistant for conversational transport information.
- Improve communication and safety awareness across transportation operations.

## 👥 User Roles

The application contains three separate role-based dashboards within one mobile application.

### 1. Student Dashboard

- Student login and authentication.
- View available buses and transportation information.
- Search buses by bus number or route.
- Access the bus tracking map.
- View estimated arrival information where location data is available.
- Interact with the AI-powered transport assistant.
- Receive spoken responses using Text-to-Speech.
- Trigger SOS emergency alerts.

### 2. Driver Dashboard

- Driver registration and authentication.
- Driver approval workflow.
- Dedicated driver dashboard.
- Start and stop trip tracking.
- Share GPS coordinates using the mobile device.
- Background location tracking service.
- Monitor vehicle speed.
- Display an overspeed warning when speed exceeds 60 km/h.
- Store location updates in Firebase Realtime Database.
- Buffer location information when internet connectivity is unavailable.

### 3. Admin Dashboard

- Dedicated administrator dashboard.
- Manage bus information.
- Add and manage fleet vehicles.
- Create and manage transportation routes.
- Generate route coordinates using OpenStreetMap Nominatim.
- Review and approve driver applications.
- Monitor safety alerts.
- Resolve and manage reported alerts.

## 🤖 AI-Powered Transport Assistant

The application integrates the Google Gemini API to provide an intelligent transport assistant called **CampusBot**.

Capabilities include:

- Answer bus-related questions through a conversational interface.
- Retrieve available fleet information from Firebase Realtime Database.
- Provide bus status and route-related information.
- Generate responses using current available transportation data.
- Read responses aloud using Flutter Text-to-Speech.
- Provide a fallback response when AI communication fails.

## 🛡️ Safety and Analytics

Safety-related functionality includes:

- Driver speed monitoring.
- Overspeed threshold configuration of 60 km/h.
- Driver-side audible overspeed warnings.
- SOS emergency reporting.
- Centralized safety alert management.
- Alert resolution through the administrator dashboard.

**Note:** The current prototype includes driver-side overspeed warnings and alert-management components. Automatic cloud notification of every overspeed event requires further integration.

## 🏗️ System Architecture

The application follows a modular Flutter architecture with separate feature modules.

```text
                  FLUTTER MOBILE APP
                          |
          +---------------+---------------+
          |               |               |
       STUDENT          DRIVER           ADMIN
       DASHBOARD       DASHBOARD       DASHBOARD
          |               |               |
          +---------------+---------------+
                          |
                  FIREBASE SERVICES
                          |
          +---------------+---------------+
          |               |               |
       Firebase        Cloud          Firebase
     Authentication   Firestore     Realtime Database
          |               |               |
       User Login      User Profiles   Bus Information
       Registration    Route Details   GPS Updates
                       Driver Data     Safety Alerts
                          |
                EXTERNAL INTEGRATIONS
                          |
             +------------+------------+
             |            |            |
           Gemini     Google Maps    OpenStreetMap
            API         SDK           Nominatim
```

## 🛠️ Technology Stack

| Category | Technologies |
|---|---|
| Mobile development | Flutter, Dart |
| Backend services | Firebase |
| Authentication | Firebase Authentication |
| Database | Firebase Realtime Database |
| Cloud database | Cloud Firestore |
| Maps | Google Maps Flutter |
| GPS tracking | Geolocator |
| Background services | Flutter Background Service |
| AI integration | Google Gemini API |
| Voice output | Flutter TTS |
| Notifications | Flutter Local Notifications |
| Offline storage | Shared Preferences |
| State management | Riverpod, Provider |
| Navigation | GoRouter |
| Connectivity | Connectivity Plus |
| Route geocoding | OpenStreetMap Nominatim |
| Development IDE | Android Studio |

## 📂 Project Structure

```text
lib/
│
├── app.dart
├── main.dart
│
├── config/
│   ├── routes/
│   └── theme/
│
├── core/
│   ├── constants/
│   ├── services/
│   ├── theme/
│   └── utils/
│
├── features/
│   ├── admin/
│   │   ├── analytics/
│   │   ├── dashboard/
│   │   ├── manage_buses/
│   │   ├── manage_drivers/
│   │   ├── manage_fleet/
│   │   ├── manage_routes/
│   │   └── notifications/
│   │
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── common/
│   │   ├── presentation/
│   │   └── services/
│   │
│   ├── driver/
│   │   ├── crowd/
│   │   ├── dashboard/
│   │   ├── safety/
│   │   └── tracking/
│   │
│   ├── student/
│   │   ├── home/
│   │   ├── map/
│   │   ├── support/
│   │   └── tracking/
│   │
│   └── splash/
│
├── shared/
│   ├── animations/
│   ├── models/
│   ├── utils/
│   └── widgets/
│
└── l10n/
```

## ⚙️ Installation and Setup

### Prerequisites

- Flutter SDK
- Dart SDK
- Android Studio
- Firebase account
- Google Maps API key
- Gemini API key

### 1. Clone the Repository

```bash
git clone https://github.com/prakash0241/college_bus_app.git
```

### 2. Navigate to the Project

```bash
cd college_bus_app
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Configure Firebase

- Create a Firebase project.
- Register your Android application.
- Configure Firebase Authentication.
- Enable Cloud Firestore.
- Enable Firebase Realtime Database.
- Configure the application using FlutterFire CLI.
- Verify Firebase configuration and database security rules.

### 5. Configure Google Maps

Create and configure a Google Maps API key with the required Android Maps SDK permissions and application restrictions.

### 6. Configure Gemini API

Configure the Gemini API key securely. Do not commit API keys or credentials to the repository.

The current prototype requires a security refactor to remove its hardcoded Gemini API key.

### 7. Run the Application

```bash
flutter run
```

## 📍 GPS Tracking Workflow

1. The driver starts a trip from the driver dashboard.
2. The application obtains location updates using the mobile device's GPS.
3. A background service receives location updates.
4. Location information is synchronized with Firebase Realtime Database when internet connectivity is available.
5. Offline location points are temporarily buffered locally.
6. The student tracking screen listens for bus information from Firebase.
7. The map uses available coordinates to display bus information.

**Current implementation status:** Driver-side GPS collection and Firebase synchronization logic are present. The live GPS marker display for students and administrators requires further debugging and validation in the current prototype.

## 🔮 Future Enhancements

- Complete real-time GPS visualization for students and administrators.
- Improve synchronization between driver GPS updates and map listeners.
- Implement reliable arrival-time predictions.
- Complete automatic cloud-based overspeed alert notifications.
- Add comprehensive transportation analytics.
- Improve offline synchronization and recovery.
- Complete and validate payment gateway integration.
- Complete and validate profile image storage integration.
- Improve production-level security and access control.

## ⚠️ Project Status

This project was developed as an individual academic prototype.

Some modules are implemented and functional, while other integrations require additional development and testing. It is not currently presented as a production-ready transportation platform.

## 👨‍💻 Developer

**Prakash**

MCA Graduate | Flutter Project Developer

**GitHub:** https://github.com/prakash0241

## 📜 License

This project is developed for academic and educational purposes. Add an appropriate license before allowing reuse or redistribution.
