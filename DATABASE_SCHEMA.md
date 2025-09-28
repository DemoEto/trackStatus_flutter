# TrackStatus Flutter - Database Schema

## Overview
This document describes the Firestore database schema for the TrackStatus Flutter application, which is a student tracking system with attendance, bus tracking, notifications, and user management features.

## Collections Structure

### 1. `Users` Collection
**Purpose**: Stores user information for students, teachers, parents, drivers, and administrators.

**Document Structure**:
```json
{
  "id": "string",           // User ID
  "name": "string",         // User's full name
  "role": "string",         // User role: 'student', 'teacher', 'parent', 'driver', 'admin'
  "fcmToken": "string",     // Firebase Cloud Messaging token for push notifications
  "createdAt": "timestamp", // Account creation timestamp
  
  // Student-specific fields
  "busId": "string",        // Assigned bus ID (for students)
  "classRoomId": "string",  // Classroom ID (for students)
  
  // Parent-specific fields
  "phone": "string",        // Parent's phone number
  "children": ["string"],   // Array of student IDs (for parents)
  
  // Teacher-specific fields
  "subId": "string",        // Subject ID (for teachers)
  
  // Driver-specific fields
  "drvId": "string"         // Driver ID (for drivers)
}
```

### 2. `Attendance` Collection
**Purpose**: Stores attendance records for students.

**Document Structure**:
```json
{
  "studentId": "string",    // Student's ID
  "name": "string",         // Student's name
  "status": "string",       // Attendance status: 'present', 'leave', 'absent'
  "subId": "string",        // Subject ID (nullable for school_in/school_out)
  "type": "string",         // Type: 'school_in', 'class_in', 'school_out'
  "timestamp": "timestamp"  // Timestamp of attendance
}
```

**Document ID Format**: `${studentId}_${date}` or `${studentId}_${subjectId}_${date}`

### 3. `Notifications` Collection
**Purpose**: Stores all application notifications for users.

**Document Structure**:
```json
{
  "id": "string",           // Notification ID
  "title": "string",        // Notification title
  "body": "string",         // Notification body
  "type": "string",         // Notification type: 'attendance_update', 'public_announcement', 
                           // 'bus_tracking', 'homework', 'general'
  "senderId": "string",     // Sender's user ID
  "senderName": "string",   // Sender's name
  "recipientId": "string",  // Recipient's user ID
  "timestamp": "timestamp", // Notification creation time
  "isRead": "boolean",      // Read status (true/false)
  "payload": "object"       // Additional data specific to notification type
}
```

### 4. `Announcements` Collection
**Purpose**: Stores public announcements created by teachers or administrators.

**Document Structure**:
```json
{
  "id": "string",           // Announcement ID
  "title": "string",        // Announcement title
  "content": "string",      // Announcement content
  "senderId": "string",     // Sender's user ID
  "senderName": "string",   // Sender's name
  "senderRole": "string",   // Sender's role
  "targetRoles": ["string"], // Target roles: ['student', 'parent', 'driver']
  "timestamp": "timestamp", // Creation time
  "isImportant": "boolean"  // Importance flag
}
```

### 5. `Assignments` Collection
**Purpose**: Stores homework assignments.

**Document Structure**:
```json
{
  "id": "string",           // Assignment ID
  "title": "string",        // Assignment title
  "description": "string",  // Assignment description
  "dueDate": "timestamp",   // Due date
  "assignedDate": "timestamp", // Assignment date
  "teacherId": "string",    // Teacher's ID
  "teacherName": "string",  // Teacher's name
  "subjectId": "string",    // Subject ID
  "assignedStudentIds": ["string"], // List of assigned student IDs
  "status": "string"        // Status: 'assigned', etc.
}
```

### 6. `vehicles` Collection
**Purpose**: Stores vehicle information for school buses and personal vehicles.

**Document Structure**:
```json
{
  "licensePlate": "string", // Vehicle license plate number
  "imageUrl": "string",     // URL to vehicle image
  "isPersonalVehicle": "boolean", // Flag for personal vehicles
  "isSchoolVehicle": "boolean",   // Flag for school vehicles
  "createdAt": "timestamp"  // Creation timestamp
}
```

### 7. `pendingAttendance` Collection
**Purpose**: Stores temporary attendance records during the scanning process.

**Document Structure**:
```json
{
  "date": "string",         // Date string in format "YYYY-MM-DD"
  "students": [
    {
      "status": "string",   // Attendance status
      "stdId": "string",    // Student ID
      "subId": "string",    // Subject ID
      "teacherId": "string" // Teacher ID
    }
  ]
}
```

### 8. `Subjects` Collection
**Purpose**: Stores subject information.

**Document Structure**:
```json
{
  "id": "string",           // Subject ID
  "name": "string",         // Subject name
  "description": "string"   // Subject description (optional)
}
```

## Subcollections

### 1. `Submissions` Subcollection (under `Assignments`)
**Purpose**: Stores individual student submissions for assignments.

**Document Structure**:
```json
{
  "studentId": "string",    // Student's user ID
  "assignmentId": "string", // Assignment ID
  "submittedAt": "timestamp", // Submission time
  "status": "string"        // Status: 'submitted', etc.
}
```

## Security Rules

### Users Collection
- Users can only read their own information
- Admins can read/write all user information
- Teachers can read student information assigned to them

### Attendance Collection
- Users can only read their own attendance
- Teachers can write attendance records for their classes
- Students can read their own records
- Parents can read attendance for their children

### Notifications Collection
- Users can only read their own notifications
- Teachers/admins can create notifications

### Announcements Collection
- All users can read announcements targeted to their role
- Only teachers/admins can create announcements

### Assignments Collection
- Teachers can create and manage assignments
- Students can read assignments assigned to them
- Parents can read assignments for their children

### Vehicles Collection
- Users can view their own vehicles
- Admins have full access to all vehicles
- Personal vehicles require parent approval

## Indexes

### Required Indexes
- `Attendance`: Compound index on `studentId` and `timestamp` for efficient date range queries
- `Notifications`: Compound index on `recipientId` and `timestamp` for chronological queries
- `Users`: Index on `role` for role-based queries
- `Assignments`: Index on `assignedStudentIds` for student-specific queries

## Relations

### User Relations
- Parents → Students (via `children` array in parent documents)
- Students → Teachers (via subject enrollment)
- Students → Vehicles (via `busId` reference)

### Attendance Relations
- Attendance → Users (via `studentId` reference)
- Attendance → Subjects (via optional `subId` reference)

### Notification Relations
- Notifications → Users (via `senderId` and `recipientId` references)
- Notifications → Announcements (for announcement notifications)

### Assignment Relations
- Assignments → Users (via `teacherId` and `assignedStudentIds`)
- Assignments → Subjects (via `subjectId` reference)
- Assignment Submissions → Assignments (subcollection relationship)

## Data Flow

### Attendance Flow
1. Student scans QR code → Temporary record in `pendingAttendance`
2. Teacher confirms attendance → Permanent record in `Attendance`
3. System creates notification in `Notifications`
4. Parents receive attendance update notifications

### Bus Tracking Flow
1. Driver updates bus status → System creates notification in `Notifications`
2. Parents receive bus tracking notifications
3. System stores bus tracking history

### Announcement Flow
1. Teacher/Admin creates announcement → Record in `Announcements`
2. System creates individual notifications in `Notifications` for target roles
3. Users receive and can view announcements

## Validation Rules

### Attendance
- Date must be current or past
- Status must be one of allowed values: 'present', 'leave', 'absent'
- Student ID must exist in Users collection

### Users
- Role must be one of: 'student', 'teacher', 'parent', 'driver', 'admin'
- ID must be unique across collection
- Required fields based on role

### Notifications
- Sender must exist in Users collection
- Recipient must exist in Users collection
- Type must be one of defined notification types

### Announcements
- Only users with 'teacher' or 'admin' role can create
- Target roles must be valid roles
- Required fields: title, content, sender information