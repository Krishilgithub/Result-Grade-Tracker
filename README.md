# Result & Grade Tracker App

A comprehensive Flutter application for tracking student grades, calculating GPA, and managing academic performance.

## Features

### 1. Grade Entry

- Add grades with the following fields:
  - Course Code
  - Course Name
  - Assessment Type (Midterm, Final, Assignment, Quiz, Project, Practical, Lab, Viva)
  - Max Marks
  - Obtained Marks
  - Date
  - Remarks (optional)
  - Scanned Marksheet (file upload)
  - Semester
  - Credits

### 2. Display & Analytics

- **Dashboard** showing:
  - Overall GPA with visual representation
  - GPA trend chart across semesters
  - Grade distribution
  - Quick statistics (total courses, average marks)
  - Recent grades list
- **Course-wise Grade Summary**:
  - Grouped by semester and course
  - Individual assessment breakdown
  - Performance trend charts per course
  - Grade improvements/declines marked
- **Term-wise GPA Calculation**:
  - Automatic GPA calculation per semester
  - Credit-weighted GPA computation
  - Overall cumulative GPA

### 3. Search & Filter

- Search by:
  - Course code
  - Course name
  - Assessment type
- Filter by:
  - Semester/term
  - Assessment type
  - Date range

### 4. Re-evaluation Deadlines

- Add and track re-evaluation deadlines
- Countdown timer showing days remaining
- Color-coded urgency (red for urgent, orange for near, green for safe)
- Mark deadlines as completed
- Edit and delete deadline functionality

### 5. Data Persistence

- SQLite database for local storage
- Cached GPA calculations for quick access
- Automatic recalculation when grades are modified
- All data persists between app sessions

### 6. Navigation

- **Dashboard**: Main screen with GPA overview and trends
- **Course Grades**: Detailed view of all grades by course
- **Add/Edit Grade**: Form to manage grade entries
- **Deadlines**: Manage re-evaluation deadlines
- **GPA Forecast**: Predict future GPA based on hypothetical scores

### 7. UI/UX Features

- Material Design 3 with modern UI
- Interactive charts showing:
  - GPA trends across semesters
  - Performance trends per course
  - Grade distribution
- Color-coded grade letters
- Pull-to-refresh functionality
- Responsive cards and layouts
- Grade improvements/declines highlighted

### 8. Bonus Features

#### GPA Forecasting

- Select a semester
- Enter hypothetical scores for courses
- Calculate forecasted GPA
- Impact analysis with recommendations

#### PDF Export

- **Transcript Export**: Complete academic transcript with all courses and GPAs
- **Course Report Export**: Detailed report for individual courses
- Includes grading scale and formatted tables
- Professional layout suitable for printing

## Grading Scale

| Grade | Grade Point | Percentage Range |
| ----- | ----------- | ---------------- |
| O     | 10.0        | 90% and above    |
| A+    | 9.0         | 80% - 89%        |
| A     | 8.0         | 70% - 79%        |
| B+    | 7.0         | 60% - 69%        |
| B     | 6.0         | 50% - 59%        |
| C     | 5.0         | 45% - 49%        |
| D     | 4.0         | 40% - 44%        |
| F     | 0.0         | Below 40%        |

## Technical Stack

### Dependencies

- **flutter**: SDK
- **provider**: State management
- **sqflite**: Local database
- **path_provider**: File system access
- **file_picker**: File selection for marksheets
- **pdf**: PDF generation
- **printing**: PDF preview and printing
- **fl_chart**: Interactive charts
- **intl**: Date formatting
- **image**: Image processing

### Architecture

- **Models**: Grade, CourseGrade, ReEvaluationDeadline
- **Database**: DatabaseHelper with CRUD operations
- **Provider**: GradeProvider for state management
- **Screens**: Dashboard, CourseGrades, AddEditGrade, Deadlines, GPAForecast
- **Utils**: PDFExporter for transcript generation

## Database Schema

### Grades Table

- id (PRIMARY KEY)
- courseCode
- courseName
- assessmentType
- maxMarks
- obtainedMarks
- date
- remarks
- marksheetPath
- semester
- credits

### Deadlines Table

- id (PRIMARY KEY)
- courseCode
- deadline
- description
- isCompleted

### GPA Cache Table

- id (PRIMARY KEY)
- semester
- gpa
- lastUpdated

## How to Run

1. Ensure Flutter is installed on your system
2. Navigate to the project directory:
   ```
   cd "c:\FlutterProjects\External Practical\result_grade_tracker"
   ```
3. Get dependencies:
   ```
   flutter pub get
   ```
4. Run the app:
   ```
   flutter run
   ```

## Course Outcomes (COs) Covered

This project demonstrates proficiency in:

- **CO1**: Understanding Flutter framework and Material Design
- **CO2**: Implementing state management with Provider
- **CO3**: Database integration using SQLite
- **CO4**: File handling and media integration
- **CO5**: UI/UX design principles
- **CO6**: Data visualization with charts
- **CO7**: PDF generation and reporting
- **CO8**: Complex business logic implementation (GPA calculations)

## Features Breakdown by Requirements

✅ Grade Entry with all required fields
✅ Course-wise grade summary
✅ Term-wise GPA calculation
✅ Search functionality
✅ Filter by semester and assessment type
✅ Re-evaluation deadline tracking with countdown
✅ SQLite persistence with cached GPA
✅ Multi-screen navigation
✅ Interactive charts for trends
✅ Grade improvements/declines marked
✅ GPA forecasting (Bonus)
✅ PDF transcript export (Bonus)

## Author

Created for External Practical - Flutter Application Development
