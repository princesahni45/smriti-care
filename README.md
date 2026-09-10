# MindCare NER

## AI-Powered Cognitive Care and Safety Platform for Elderly Dementia Patients

MindCare NER is a digital healthcare platform designed to support elderly individuals experiencing dementia, memory loss, and cognitive decline, particularly in the North Eastern Region (NER) of India.

The platform aims to improve cognitive engagement, daily independence, safety, and caregiver support through interactive cognitive activities, AI-powered personalization, reminders, multilingual assistance, caregiver monitoring, and offline-first accessibility.

---

## Problem Statement

The North Eastern Region of India faces several challenges in providing continuous and specialized healthcare support to elderly individuals experiencing age-related cognitive disorders such as dementia and memory loss.

Many elderly individuals, especially those living in remote and rural areas, face challenges such as:

* Memory decline and confusion
* Anxiety and social isolation
* Forgetting medicines
* Difficulty remembering daily routines
* Limited access to specialized neurological care
* Difficulty in continuous caregiver monitoring
* Limited or unreliable internet connectivity
* Risk of becoming confused or disoriented while away from home

MindCare NER aims to address these challenges through an accessible, elderly-friendly, AI-enabled digital platform.

---

# Our Solution

MindCare NER provides an integrated platform that combines:

* Cognitive training games
* AI-powered adaptive difficulty
* Voice-assisted interaction
* Smart medication reminders
* Hydration reminders
* Daily activity management
* Caregiver monitoring
* Cognitive engagement analytics
* Offline-assisted home navigation
* Offline functionality
* Multilingual support
* Secure patient data management

The goal is to encourage long-term cognitive engagement while supporting caregivers and improving healthcare accessibility.

---

# Key Features

## Cognitive Training Games

Interactive activities designed to support cognitive engagement and mental stimulation.

Planned activities include:

* Memory Card Matching
* Pattern Recognition
* Object Recognition
* Daily Routine Recall
* Attention and Concentration Activities

The games are designed with:

* Large buttons
* Simple instructions
* Elderly-friendly interfaces
* Voice guidance
* Personalized difficulty levels

---

## AI-Powered Adaptive Learning

The platform analyzes user performance and adapts activities accordingly.

Performance factors may include:

* Correct answers
* Incorrect answers
* Response time
* Number of attempts
* Historical performance
* Cognitive engagement trends

The difficulty level can adapt dynamically.

```text id="g3j6v2"
Good Performance
       |
       v
Higher Difficulty
       |
       v
Continued Cognitive Engagement
```

```text id="l4wbfg"
Low Performance
       |
       v
Simplified Activities
       |
       v
Reduced Frustration
```

---

## Voice-Assisted Interaction

MindCare NER aims to provide simple voice-based interaction for elderly users.

Example interactions include:

```text id="ahpl65"
"Start a memory game"

"What should I do today?"

"When should I take my medicine?"

"Help me"
```

The platform can provide voice-assisted responses and simple navigation.

---

## Multilingual and Cultural Support

The platform is designed to support:

* English
* Hindi
* Future North-Eastern regional languages

Future versions can include culturally familiar:

* Food
* Festivals
* Traditional clothing
* Music
* Landscapes
* Objects and activities

This helps create a more familiar and engaging experience for elderly users.

---

## Smart Reminder System

The platform can provide reminders for:

* Medicines
* Hydration
* Meals
* Daily activities
* Medical appointments

Users can confirm activities with simple actions such as:

```text id="kj8sbd"
Medicine Taken

Water Drunk

Activity Completed
```

---

## Caregiver Dashboard

Caregivers can monitor important patient activities through a centralized dashboard.

Planned information includes:

* Daily activity level
* Games completed
* Cognitive engagement
* Reminder completion
* Medicine status
* Hydration status
* Performance trends

The platform may generate alerts for:

* Missed medication
* Extended inactivity
* Reduced cognitive engagement
* Significant performance changes

---

## Cognitive Engagement Analytics

The system tracks cognitive engagement over time.

Example metrics include:

* Memory Performance
* Attention Score
* Recognition Score
* Game Completion Rate
* Activity Level

Example:

```text id="t3qf2l"
Memory Score:       75/100
Attention Score:    82/100
Recognition Score:  70/100

Overall Engagement: GOOD
```

Important: MindCare NER is designed to support cognitive engagement and monitoring. It does not diagnose dementia or replace professional medical advice.

---

# Safe Return Home

One of the planned safety features is Safe Return Home.

Elderly individuals experiencing confusion or disorientation may find it difficult to navigate back to familiar locations.

The application will provide a simple emergency-friendly option:

```text id="wvymub"
TAKE ME HOME
```

The planned system can include:

* Saved home location
* Pre-downloaded map data
* GPS location assistance
* Offline map access
* Simple navigation instructions
* Large visual guidance
* Voice-assisted directions
* Caregiver contact options

Conceptual flow:

```text id="ufm3u9"
User Feels Lost
      |
      v
Presses "TAKE ME HOME"
      |
      v
Location is Detected
      |
      v
Offline Navigation Starts
      |
      v
Voice and Visual Guidance
      |
      v
User is Guided Toward Home
```

Important: This feature is intended as an assistive safety tool and should not replace appropriate caregiver supervision or emergency services.

---

# Offline-First Accessibility

Internet connectivity can be unreliable in remote areas.

MindCare NER is planned as an offline-first platform.

Offline capabilities can include:

* Cognitive games
* Activity tracking
* Reminder management
* Local patient data storage
* Offline maps
* Navigation assistance

When connectivity becomes available:

```text id="k7u5pv"
Offline Data
     |
     v
Secure Synchronization
     |
     v
Cloud Database
     |
     v
Caregiver Dashboard
```

---

# Mobile Application Architecture

```text
               +----------------------------------------+
               |        SmritiCare Mobile App           |
               |         (Flutter & Dart)               |
               +----------------------------------------+
                                   |
         +-------------------------+-------------------------+
         |                         |                         |
         v                         v                         v
+-----------------+       +-----------------+       +-----------------+
| Patient Module  |       |   Games Hub     |       | Caregiver Hub   |
| - Quick Actions |       | - Memory Match  |       | - Vitals & Stats|
| - Daily Routine |       | - Word Recall   |       | - Reminders Log |
| - Reminders     |       | - Diff Object   |       | - Alert Triggers|
+-----------------+       +-----------------+       +-----------------+
         |                         |                         |
         +-------------------------+-------------------------+
                                   |
                                   v
               +----------------------------------------+
               |   Core Services & Local Persistence    |
               | - Offline-first (path_provider)        |
               | - Multi-language i18n dictionaries     |
               | - GoRouter declarative routing         |
               +----------------------------------------+
```

---

# Technology Stack

## Mobile Client (Flutter & Dart)

* **Framework:** Flutter SDK (`>=3.0.0 <4.0.0`)
* **Language:** Dart
* **Routing:** `go_router`
* **Typography:** `google_fonts` (DM Sans elderly-friendly legible font)
* **Design System:** Material Design 3 with custom accessibility high-contrast palette
* **Storage:** `path_provider` (local file caching and offline stats)
* **Icons:** `cupertino_icons` & Material Icons
* **Localization:** 10 Regional languages (`as`, `bn`, `brx`, `en`, `grt`, `hi`, `kha`, `lus`, `mni`, `trp`)

---

# Project Structure

```text
smriti-care/
├── android/                    # Android native host config & Gradle
├── ios/                        # iOS native host config & Xcode workspace
├── lib/                        # Flutter Dart source code
│   ├── app.dart                # App widget & GoRouter route configuration
│   ├── main.dart               # App entrypoint
│   ├── core/                   # Theme, constants, models, navigation
│   │   ├── constants/
│   │   ├── models/
│   │   └── theme/
│   ├── features/               # Feature-first modules
│   │   ├── auth/               # Role selection, login, register
│   │   ├── caregiver/          # Caregiver overview, vitals, alerts
│   │   ├── games/              # Cognitive games (Memory, Word, Object)
│   │   ├── patient/            # Patient dashboard & daily routine
│   │   └── splash/             # Splash screen & onboarding
│   └── shared/                 # Reusable UI widgets & buttons
├── assets/                     # Application assets
│   ├── i18n/                   # Multilingual translation JSON dictionaries
│   └── images/                 # App hero banners and illustrations
├── references/                 # Reference specifications for future modules
│   ├── emergency/              # Emergency SOS & Take Me Home reference logic
│   └── reminders/              # Smart medication & dosage guard reference logic
├── test/                       # Unit & widget integration test suites
│   ├── caregiver_migration_test.dart
│   ├── dashboard_test.dart
│   ├── games_migration_test.dart
│   └── widget_test.dart
├── analysis_options.yaml       # Flutter static analysis rules
├── pubspec.yaml                # Package manifest & asset declarations
└── README.md
```

---

# Getting Started

### Prerequisites
* Flutter SDK (3.0.0 or later)
* Android Studio / Xcode (for device emulation)
* VS Code or Android Studio with Flutter & Dart extensions

### Setup & Run
```bash
# Clone the repository
git clone https://github.com/princesahni45/smriti-care.git
cd smriti-care

# Fetch Flutter dependencies
flutter pub get

# Run static analysis
flutter analyze

# Execute automated tests
flutter test

# Launch on connected mobile device / emulator
flutter run
```

## Phase 1: Landing Page

* Project introduction
* Problem overview
* Features overview
* How the platform works
* Responsive design

## Phase 2: Patient Interface

* Elderly-friendly dashboard
* Large navigation buttons
* Daily activities
* Basic reminders

## Phase 3: Cognitive Games

* Memory Card Matching
* Pattern Recognition
* Object Recognition
* Daily Routine Recall
* Attention Activities

## Phase 4: Caregiver Dashboard

* Patient activity monitoring
* Reminder tracking
* Cognitive engagement analytics
* Alerts

## Phase 5: AI Integration

* Adaptive difficulty
* Performance analysis
* Cognitive engagement trends

## Phase 6: Voice and Multilingual Support

* Voice commands
* Text-to-speech
* English support
* Hindi support
* Future regional language support

## Phase 7: Offline Functionality

* Offline games
* Local data storage
* Data synchronization
* Offline maps
* Safe Return Home navigation

---

# Future Enhancements

Potential future improvements include:

* Advanced machine learning models
* Wearable device integration
* Fall detection
* Emergency SOS functionality
* Smartwatch support
* Telemedicine integration
* Healthcare worker portal
* Additional regional languages
* Advanced caregiver alerts
* Improved offline navigation

---

# Target Users

The platform is designed for:

* Elderly individuals experiencing cognitive decline
* Dementia patients
* Family caregivers
* Healthcare workers
* Community healthcare providers

---

# Social Impact

MindCare NER aims to contribute towards:

* Improved cognitive engagement among elderly individuals
* Increased independence and confidence
* Better management of daily routines
* Improved caregiver support
* Better access to digital healthcare
* Support for remote and rural communities
* Improved elderly safety
* Greater healthcare accessibility in the North Eastern Region

---

# Important Disclaimer

MindCare NER is a cognitive assistance and engagement platform.

It is not intended to diagnose dementia, provide medical diagnoses, replace professional neurological care, or replace emergency services.

All cognitive insights and activity data should be interpreted with appropriate support from qualified healthcare professionals.

---

# Contributing

Contributions, ideas, and improvements are welcome.

If you would like to contribute:

1. Fork the repository.
2. Create a new branch.
3. Make your changes.
4. Commit your changes.
5. Push the branch.
6. Create a Pull Request.

---

# License

This project is currently developed as an academic and innovation project. License information will be added in future versions.

---

# Vision

Our vision is to build technology that helps elderly individuals remain mentally engaged, connected, independent, and safe.

**MindCare NER — Supporting Cognitive Well-being, Independence, and Safety Through Technology.**
