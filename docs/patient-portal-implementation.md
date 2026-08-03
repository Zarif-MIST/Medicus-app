# Patient Portal — Implementation Notes

Reference notes for the patient-side features built in `lib/Features/Role_Based_Interface/Patients/`. Covers what each file does and the technical approach behind each piece, for anyone picking this code up later.

Everything here uses **mock, in-memory data** — no Firestore/backend calls yet. Wherever that matters, the file has a `// Mock data — replaced by a Firestore query...` comment marking exactly what to swap out later.

---

## 1. Architecture: "lift state up, pass it down"

The core pattern used throughout is Flutter's standard **state lifting**: instead of each tab screen owning its own copy of data, the shared data (booked appointments, prescriptions) lives one level up, in the screen that owns the bottom nav, and gets passed down as constructor parameters + callbacks.

```
pat_dash.dart  (_PatientHomeShellState)
 ├─ holds: List<BookedAppointment> _appointments
 ├─ holds: List<Prescription> _prescriptions
 │
 ├─ PatientHomeScreen(appointments, prescriptions)      -- reads both, read-only
 ├─ SpecialistSelectionScreen(appointments, onBook)     -- reads appointments, can add one
 ├─ PharmacyLocatorScreen()                             -- unrelated
 └─ PatientProfileScreen(prescriptions)                 -- reads prescriptions, forwards to Records
```

Why this matters: without it, Home's "Next Appointment" stat and the Appointment tab's "Upcoming Appointments" list would each have their own disconnected mock data and could show different things. Lifting the list to the common ancestor (`pat_dash.dart`) makes there be exactly **one source of truth**, mutated in exactly one place (`_addAppointment`), and every screen below just re-renders when it changes via `setState`.

There's no state-management package (`provider`, `riverpod`, `bloc`) in this project — this pattern is achieved with plain `StatefulWidget` + `setState`, which is enough for this scale of app.

---

## 2. File-by-file reference

### `Screens/pat_dash.dart`
The root of the patient experience. `PatientDashboardScreen` is a thin wrapper; the real logic is in `_PatientHomeShellState`:
- Owns `_index` (which bottom-nav tab is selected), `_appointments`, and `_prescriptions`.
- Builds the 4 tab pages fresh on every `build()` (not `const`, because they now depend on state) and swaps between them inside a `Stack`, not a `Navigator` — each tab's widget subtree stays mounted, `_index` just decides which one is drawn on top of the `LiquidGlassNavBar`.
- `extendBody: true` on the `Scaffold` lets tab content scroll *behind* the nav bar so the glass effect has something to refract.

### `Screens/home/patient_home_screen.dart`
The Home tab. Everything on it is **derived**, not stored:
- `_daysToNextAppointment` — min of `appointment.daysFromNow` across all booked appointments.
- `_ongoingPrescriptions` — flattens every `Prescription.medicines` into `PrescriptionTimelineEntry` objects, keeps only the ones not yet finished, sorts newest-prescribed-first.
- The "Next Dose" card's medicine name is just `ongoing.first.medicineName` — whichever ongoing medicine was prescribed most recently.
- Stat cards (`Total Prescriptions`, `Ongoing Treatments`) are `prescriptions.length` / `ongoing.length` — real counts, not hardcoded numbers.

### `Screens/doctors/specialist_selection_screen.dart`
The Appointment tab — doctor search + booking entry point.
- `_mockDoctors`: flat list of `DoctorSummary` (name, specialty, hospital, rating, fee, etc.) — one per specialty so every filter chip returns something.
- If `appointments` is non-empty, renders an "Upcoming Appointments" section (using the private `_UpcomingAppointmentCard`) above the search UI.
- Tapping a doctor card pushes `DoctorProfileScreen`, forwarding the `onBook` callback so a booking made two screens deep can still update state that lives in `pat_dash.dart`.

### `Screens/doctors/doctor_profile_screen.dart`
Doctor detail + slot picker (`StatefulWidget` because it tracks the selected date/slot locally before booking).
- `_dates`: next 7 days generated with `List.generate(7, (i) => DateTime.now().add(Duration(days: i)))`.
- `_mockTimeSlots`: same slot options every day (no per-doctor availability modeled yet).
- "Book Appointment" is disabled (`onPressed: null`) until a slot is picked, then pushes `AppointmentConfirmationScreen`.

### `Screens/doctors/appointment_confirmation_screen.dart`
Stateless summary + confirm screen.
- On "Confirm Booking": calls `onConfirmed(BookedAppointment(...))` (which is `_addAppointment` in `pat_dash.dart`, threaded all the way down), then shows a success `AlertDialog`.
- The dialog's "Done" button pops **twice** (`Navigator.of(context).pop()` ×2) — once for the dialog, once to skip back past `DoctorProfileScreen` — landing the user back on the Appointment tab in one tap instead of stepping back through each screen.

### `Widgets/doctors/booked_appointment.dart`
Plain data class: `doctorName`, `specialty`, `hospital`, `date`, `time`, `fee`. `daysFromNow` getter does the date-math (`clamp(0, 9999)` so a same-day appointment doesn't show as negative).

### `Widgets/records/prescription.dart`
The core prescription model — **one prescription = one doctor visit, can bundle multiple medicines**:
```dart
Prescription(id, doctorName, date, medicines: List<PrescriptionMedicine>)
PrescriptionMedicine(name, dosage, durationDays)
```
- `timelineEntries` getter converts each medicine into a `PrescriptionTimelineEntry` (the display-only DTO the Home dashboard's progress-bar widget expects), computing `dayCurrent` as `min(daysSincePrescribed, durationDays)`.
- `isCompleted` — true only when *every* medicine in the prescription has finished its course.
- This is the model a doctor-side "write prescription" screen would eventually create; the patient side here only reads it.

### `Widgets/home/prescription_timeline.dart`
Display-only model + widget for a single medicine's course progress (`dayCurrent`/`dayTotal`, a progress bar, "Completed" vs "Day X/Y" badge). Has a `prescribedOn` date field so entries can be sorted chronologically wherever they're shown.

### `Screens/records/records_screen.dart`
The "Medical Records" screen (reached by tapping the card on Profile, not a bottom-nav tab).
- `StatefulWidget` holding just `_query` (the search text).
- Filtering: `query.isEmpty ? all : prescriptions.where(doctor-or-medicine-name-contains-query)`.
- Splits filtered results into Ongoing/Previous (`!p.isCompleted` / `p.isCompleted`), each sorted newest-first by `p.date`.
- Each `Prescription` renders as a `_PrescriptionCard`: ID, date, doctor, medicine list, and a **View PDF** button.

### `Screens/profile/patient_profile_screen.dart`
Rebuilt as an editable, sectioned profile.
- Each section (Personal Info, Medical Info, Emergency Contact) is plain `String` fields in `State`, edited via `_editSection(...)` — a **generic reusable bottom-sheet form**: pass in labels + current values + an `onSave` callback, it builds one `TextField` per label and calls `onSave` with the edited values on tap. Three call sites (`_editPersonalInfo`, `_editMedicalInfo`, `_editEmergencyContact`) reuse this one function instead of three separate dialog implementations.
- "Medical Records" is a single tappable `_NavCard`, not inline content — pushes `RecordsScreen`.
- Shared `_cardDecoration(isDark)` top-level function returns the same `BoxDecoration` (white/dark background + soft shadow) used by every card on the screen, so they all look consistent without repeating the decoration code.

### `Widgets/common/app_search_bar.dart`
One reusable search field (`AppSearchBar`) used by both the doctor-search screen and Records. The "transparent" look is just: `Container` with `color: Colors.transparent` + a 1px `Border.all(...)` (light grey in dark mode, near-black at 12% opacity in light mode) wrapping a `TextField` with `border: InputBorder.none` — no filled background, so it sits directly on the screen instead of looking like its own solid pill.

### `Utilities/prescription_pdf.dart`
`buildPrescriptionPdf({prescription, patientName, patientId}) → Future<Uint8List>`. Builds a one-page PDF with the `pdf` package's widget API (`pw.Document`, `pw.Page`, `pw.Table` for the medicine list) — this runs entirely on-device, no server involved.

---

## 3. Technical techniques used (for reuse elsewhere in the app)

**PDF generation & printing** — two packages working together:
- [`pdf`](https://pub.dev/packages/pdf) builds the actual document (`pw.Document().addPage(pw.Page(build: (context) => ...))`, using `pw.*` widgets that mirror Flutter's own widget names but render to PDF primitives instead of pixels).
- [`printing`](https://pub.dev/packages/printing) takes that document and hands it to the OS's native print/share preview: `Printing.layoutPdf(onLayout: (format) => buildPrescriptionPdf(...))`. This one call gives you print, share, and save-as-PDF for free — no separate PDF *viewer* dependency needed.

**Bottom-sheet edit forms** — `showModalBottomSheet(isScrollControlled: true, ...)` with `MediaQuery.of(context).viewInsets.bottom` added to the bottom padding, so the sheet rides up above the on-screen keyboard instead of being covered by it.

**Derived getters over duplicated state** — nowhere in this feature is there a variable that's a stale copy of another one. `_daysToNextAppointment`, `_ongoingPrescriptions`, `timelineEntries`, `isCompleted` are all *computed* from the underlying list on every build, so there's never a chance of them drifting out of sync with the source data.

**Passing callbacks through pushed routes** — booking a slot happens 2 screens deep (`SpecialistSelectionScreen → DoctorProfileScreen → AppointmentConfirmationScreen`), but the state it needs to update lives in `pat_dash.dart`. Solved by passing the `onBook`/`onBooked`/`onConfirmed` callback itself down through each screen's constructor, rather than trying to pass data back up through `Navigator.pop(result)` chains.

**Liquid glass nav bar** (`Doctors/Widgets/LiquidNavbar.dart`, not modified this round but worth noting): real GPU shader refraction via the `liquid_glass_renderer` package, not a blur/gradient approximation. Only works with Impeller (Android/iOS/macOS) — has a `fake` flag to fall back to a cheaper backdrop-filter look on unsupported platforms (Windows/Linux/web).

---

## 4. What's intentionally still mocked / not built

- No backend — everything is a `const`/`final` list of Dart objects, not a Firestore query.
- No doctor-side "write a prescription" screen — `Prescription` records are hand-written mock data standing in for what that screen would eventually save.
- No cancel/reschedule for bookings — booking-only flow.
- Time-slot availability is the same fixed list every day for every doctor — no real scheduling logic.
