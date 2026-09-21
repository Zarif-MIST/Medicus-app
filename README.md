# Medicus

A Flutter app connecting the four parties involved in a prescription: the
patient who receives it, the doctor who writes it, the pharmacist who
dispenses it, and the lab specialist who runs the tests ordered alongside it.

Built on Firebase Auth and Cloud Firestore.

## Roles

Each account registers as exactly one role, stored on the user document, and
lands on its own dashboard.

| Role | What it does |
| --- | --- |
| **Patient** | Books appointments, tracks prescriptions and doses, uploads lab reports, finds nearby pharmacies, shows a QR code at the counter |
| **Doctor** | Sets clinic hours and availability, writes prescriptions from live pharmacy stock, orders lab tests, reviews patient records |
| **Pharmacist** | Works a queue of pending prescriptions, dispenses fully or partially, manages inventory with low-stock alerts and an audit log |
| **Lab specialist** | Scans a patient's QR code, works through ordered tests, publishes results back to the ordering doctor |

## Two identifiers

Worth knowing before reading any query, because they are easy to confuse:

- **`request.auth.uid`** — the Firebase Auth UID. Keys the `users` collection.
- **`userId`** — a 4-digit app-level ID (`'4821'`). Every clinical record
  stores this as `patientId`, `doctorId` or `pharmacistId`.

Translating between them means reading the caller's `users` document. The
security rules do exactly this.

## Getting started

Requires Flutter **3.44.2** or later.

```bash
flutter pub get
```

Email verification goes through MailerSend, whose credentials are read with
`String.fromEnvironment` and must be supplied at build time. Copy the example
file and fill it in:

```bash
cp env.example.json env.json
```

`env.json` is gitignored — do not commit it.

```bash
flutter run --dart-define-from-file=env.json
```

Without those values, registration throws when it tries to send the
verification email.

### Firebase

The repo ships `firebase_options.dart` and `android/app/google-services.json`
for the `medicus-8536d` project. These contain a Firebase API key, which is
a public client identifier by design — it identifies the project, it does not
grant access. Access is controlled entirely by the security rules.

Deploy the rules after changing them:

```bash
firebase deploy --only firestore:rules
```

`firestore.rules` is the authoritative copy. If what is live in the console
disagrees with this file, the file is right and the console is stale.

## Layout

```
lib/
├── Features/
│   ├── Appointments/          booking, availability, date overrides
│   ├── Authentication/        registration, login, email verification
│   ├── Prescriptions/         dose logs
│   └── Role_Based_Interface/
│       ├── Doctors/
│       ├── Lab_Specialist/
│       ├── Patients/
│       └── Pharmacist/
├── Theme/
└── Utilities/                 validators, colors, sizes, helpers
```

Screens hold state and pass it down to widgets; services own all Firestore
access. `docs/patient-portal-implementation.md` walks through the patient side
in detail.

## Firestore collections

`users`, `prescriptions`, `appointments`, `doctor_availability`,
`doctor_date_overrides`, `patient_profiles`, `lab_orders`, `lab_reports`,
`dose_logs`, `inventory`, `inventory_transactions`, `pharmacy_visits`,
`pharmacy_reviews`.

Queries deliberately avoid combining an equality filter with an inequality on
a different field, so the project needs no composite indexes; where both are
wanted, the second filter is applied client-side. Sorting is client-side too.

## Tests and CI

```bash
flutter test
flutter analyze
```

The tree is warning-free, and CI runs `flutter analyze --fatal-infos` on every
push and pull request, so a new warning fails the build.

`dart format` has not been applied across the codebase — 38 files currently
differ from the formatter, so the check is not in CI yet.
