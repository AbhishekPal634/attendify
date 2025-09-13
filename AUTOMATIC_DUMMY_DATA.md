# Automatic Dummy Data Creation

The Attendify app now automatically creates dummy data for new users who don't have existing data in Firestore. This eliminates the need to manually set up data in Firebase Console for testing.

## How It Works

When a user logs in and no student data is found for their email, the app automatically creates:

### 1. Student Profile

- Uses the user's email and display name from Firebase Auth
- Generates a unique student ID based on current date
- Creates realistic dummy profile data (phone, address, academic info, etc.)

### 2. Sample Subjects (3 subjects)

- **Data Structures** (CS101) - Dr. Sarah Johnson
- **Database Systems** (CS201) - Prof. Michael Chen
- **Software Engineering** (CS301) - Dr. Emily Rodriguez

### 3. Sample Sessions (5 sessions)

- **1 Active Session**: Currently happening (started 30 min ago, ends in 60 min)
- **1 Upcoming Session**: Scheduled 2 hours from now
- **3 Completed Sessions**: For calculating attendance percentages
  - Yesterday's session (attended)
  - Day before yesterday's session (missed)
  - Today's morning session (attended)

## Features

- ✅ **Automatic Creation**: No manual setup required
- ✅ **Realistic Data**: Includes varied attendance patterns
- ✅ **Unique IDs**: Each user gets their own separate data set
- ✅ **Live Sessions**: Active sessions for testing attendance marking
- ✅ **Attendance Analytics**: Mix of attended/missed sessions for realistic percentages

## What You'll See

After logging in, you'll immediately see:

- **Dashboard**: Shows today's sessions, active sessions, and attendance summary
- **Profile**: Complete profile information that can be edited
- **Real-time Data**: Active session available for marking attendance
- **Analytics**: Calculated attendance percentages based on dummy sessions

## Testing Scenarios

The dummy data includes:

- **Overall Attendance**: ~67% (2 out of 3 completed sessions attended)
- **Active Session**: Ready for facial verification testing
- **Critical Subjects**: None (all subjects above 75% attendance threshold)
- **Today's Summary**: 1 completed session, 1 active session

## No Firebase Console Setup Needed

You no longer need to manually create data in Firebase Console. Just:

1. Run the app
2. Log in with any email
3. Dummy data is automatically created
4. Start testing all features immediately

The app handles everything automatically while maintaining data isolation between different user accounts.
