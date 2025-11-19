# Meshina - Smart Sustainable Transportation App 🌱🚗

Empowering eco-conscious travel decisions through AI-powered route optimization.

---

## 🌟 Overview

   Meshina is a Flutter-based mobile application designed to promote sustainable transportation in Saudi Arabia. The app leverages AI/ML models, real-time traffic data, and carbon footprint calculations to help users make eco-friendly travel decisions while earning rewards for sustainable choices.
   🎯 Core Mission
        Reduce Carbon Emissions: Track and minimize your carbon footprint
        Reward Sustainability: Earn eco-points for choosing green transportation
        Smart Routing: AI-powered travel time predictions considering weather, traffic, and road conditions
        Multi-Modal Transport: Support for walking, cycling, public transit, and driving
   

---

## ✨ Key Feature
 🚀 Core Functionality
    🗺️ Interactive Map Interface
        Real-time location tracking with Google Maps
        Visual route comparison with color-coded polylines
        Multiple route alternatives with carbon impact analysis
    🤖 AI-Powered Predictions
        ML-based travel time estimation
        Weather-aware routing
        Traffic pattern analysis
        Hour-of-day optimization
    🌱 Carbon Footprint Tracking
        Real-time emission calculations per transport mode
        Historical carbon contribution analytics
        Beautiful data visualizations with pie charts
        Emission level categorization (Low/Medium/High)
    🎁 Rewards System
        Earn eco-points for sustainable travel choices
        Points-to-currency conversion (100 points = 1 SAR)
        Integration with utility bill payments
        Nafath payment gateway support
    🎤 Voice Interaction
        Arabic voice commands via Speech-to-Text
        AI assistant powered by Google Gemini
        Text-to-Speech navigation instructions
        Natural language location search
    📊 Analytics Dashboard
        Interactive carbon wheel visualization
        Transport mode usage statistics
        Emission percentage breakdowns
        Points earning history
🔐 Authentication & Security
    Email/Password authentication via Firebase
    Google Sign-In integration
    Nafath authentication support (Saudi Arabia)
    PIN-based quick login
    Secure session management with SharedPreferences
💾 Data Persistence
    Trip history saved to Firestore
    User profiles with eco-points tracking
    Offline-capable data storage
    Real-time synchronization
---

## 🛠️ Tech Stack
   - Frontend
      •	Framework: Flutter 3.0+
     
      •	State Management:
          BLoC/Cubit for business logic
     
      •	UI Libraries:
          google_maps_flutter - Interactive maps
          fl_chart - Data visualizations
          sliding_up_panel - Smooth bottom sheets
          lucide_icons - Modern iconography
     
   - Backend & Services
      •	Authentication: Firebase Auth
     
      •	Database: Cloud Firestore
     
      •	ML Backend: Python FastAPI (External service)
     
      •	Maps: Google Maps Platform & OpenRouteService API

   - APIs & Integrations
      •	Gemini AI: Conversational assistant
     
      •	OpenRouteService: Alternative route calculations

      •	Nominatim: Reverse geocoding
     
    
   - AI & Machine Learning
      •	Custom travel time prediction model
     
      •	Transport mode classification
     
      •	Carbon emission estimation algorithms

---
## 🪄 App Preview

![App Demo](assets/.gif)

---

## 🚀 Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/soha131/Meshina.git
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run the App
```bash
flutter run
```

> Make sure your environment is set up with Flutter SDK.

---

## 🧩 Folder Structure

```

meshina_app/
├── lib/
│   ├── auth/                          # Authentication screens
│   │   ├── login.dart
│   │   ├── signup.dart
│   │   ├── CreatePinScreen.dart
│   │   ├── pin_screen.dart
│   │   ├── forgetpassword.dart
│   │   ├── request_otp.dart
│   │   ├── enter_otp.dart
│   │   ├── new_password.dart
│   │   └── password_changed.dart
│   │
│   ├── cubit/                         # State management
│   │   ├── AuthCubit.dart
│   │   ├── auth_state.dart
│   │   ├── time_cubit.dart
│   │   ├── time_state.dart
│   │   ├── time_model.dart
│   │   └── route_option.dart
│   │
│   ├── features_screen/               # Feature modules
│   │   ├── dashboard.dart             # Carbon analytics
│   │   ├── points_currency.dart       # Rewards & payments
│   │   ├── savedlist.dart             # Trip history
│   │   └── live_location.dart         # Real-time tracking
│   │
│   ├── onboarding/                    # Onboarding flow
│   │   ├── splash.dart
│   │   └── welcome.dart
│   │
│   ├── widget/                        # Reusable widgets
│   │   └── route_prediction_sheet.dart
│   │
│   ├── main.dart                      # App entry point
│   ├── main_map.dart                  # Core map screen
│   ├── arrived.dart                   # Arrival celebration
│   ├── optimal_route.dart             # Route comparison
│   ├── helper.dart                    # Utility functions
│   ├── service.dart                   # API service
│   ├── carbon_service.dart            # Carbon calculations
│   └── firebase_options.dart          # Firebase config
│
├── assets/
│   ├── icons/                         # App icons
│   ├── fonts/                         # Custom fonts
│   └── images/                        # Static images
│
├── android/                           # Android specific
├── ios/                               # iOS specific
├── pubspec.yaml                       # Dependencies
└── README.md                          # Documentation
```


---
## 📅 Future Enhancements
   - 🌍 Leaderboards for eco-champions
   - 📴 Implement offline mode for saved routes
   - 🤖 Daily/weekly challenges
   - 📄 Monthly carbon impact reports

---
---

## 📸 Screenshots




---

## 🤝 Contributing

Contributions are welcome!  
Please open an issue or submit a pull request to help improve the project.

---

## 📄 License

This project is licensed under the **MIT License** — feel free to use and modify it.

---
