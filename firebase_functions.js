/**
 * Firebase Cloud Functions for Notification System
 * 
 * This file demonstrates how to set up Firebase Cloud Functions for handling
 * notifications in the TrackStatus Flutter application.
 * 
 * To implement these functions, you would create a separate Firebase Functions project:
 * 1. Run: `firebase init functions` in your project directory
 * 2. Copy the code below to your functions/index.js file
 * 3. Install dependencies: `npm install firebase-admin firebase-functions`
 * 4. Deploy: `firebase deploy --only functions`
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Handle bus tracking notifications
exports.handleBusTrackingNotification = functions.firestore
  .document('Notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    
    if (notification.type === 'bus_tracking') {
      try {
        // Get recipient user to fetch their FCM token
        const userDoc = await admin.firestore()
          .collection('Users')
          .doc(notification.recipientId)
          .get();
          
        if (userDoc.exists) {
          const fcmToken = userDoc.data().fcmToken;
          
          if (fcmToken) {
            const message = {
              notification: {
                title: notification.title || 'แจ้งเตือนรถรับส่ง',
                body: notification.body || 'มีการอัปเดตสถานะรถรับส่ง',
              },
              data: {
                type: notification.type,
                payload: JSON.stringify(notification.payload || {}),
                timestamp: notification.timestamp ? notification.timestamp.toDate().toISOString() : new Date().toISOString(),
              },
              token: fcmToken,
            };

            await admin.messaging().send(message);
          }
        }
      } catch (error) {
        console.error('Error sending bus tracking notification:', error);
      }
    }
  });

// Handle attendance notifications
exports.handleAttendanceNotification = functions.firestore
  .document('Notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    
    if (notification.type === 'attendance_update') {
      try {
        const userDoc = await admin.firestore()
          .collection('Users')
          .doc(notification.recipientId)
          .get();
          
        if (userDoc.exists) {
          const fcmToken = userDoc.data().fcmToken;
          
          if (fcmToken) {
            const message = {
              notification: {
                title: notification.title || 'แจ้งเตือนการเข้าเรียน',
                body: notification.body || 'มีการอัปเดตสถานะการเข้าเรียนของคุณ',
              },
              data: {
                type: notification.type,
                payload: JSON.stringify(notification.payload || {}),
                timestamp: notification.timestamp ? notification.timestamp.toDate().toISOString() : new Date().toISOString(),
              },
              token: fcmToken,
            };

            await admin.messaging().send(message);
          }
        }
      } catch (error) {
        console.error('Error sending attendance notification:', error);
      }
    }
  });

// Handle announcement notifications
exports.handleAnnouncementNotification = functions.firestore
  .document('Notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    
    if (notification.type === 'public_announcement') {
      try {
        const userDoc = await admin.firestore()
          .collection('Users')
          .doc(notification.recipientId)
          .get();
          
        if (userDoc.exists) {
          const fcmToken = userDoc.data().fcmToken;
          
          if (fcmToken) {
            const message = {
              notification: {
                title: notification.title || 'แจ้งเตือนประชาสัมพันธ์',
                body: notification.body || 'มีประกาศใหม่จากโรงเรียน',
              },
              data: {
                type: notification.type,
                payload: JSON.stringify(notification.payload || {}),
                timestamp: notification.timestamp ? notification.timestamp.toDate().toISOString() : new Date().toISOString(),
              },
              token: fcmToken,
            };

            await admin.messaging().send(message);
          }
        }
      } catch (error) {
        console.error('Error sending announcement notification:', error);
      }
    }
  });

// Handle homework notifications
exports.handleHomeworkNotification = functions.firestore
  .document('Notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    
    if (notification.type === 'homework') {
      try {
        const userDoc = await admin.firestore()
          .collection('Users')
          .doc(notification.recipientId)
          .get();
          
        if (userDoc.exists) {
          const fcmToken = userDoc.data().fcmToken;
          
          if (fcmToken) {
            const message = {
              notification: {
                title: notification.title || 'แจ้งเตือนการบ้าน',
                body: notification.body || 'มีการอัปเดตการบ้านใหม่',
              },
              data: {
                type: notification.type,
                payload: JSON.stringify(notification.payload || {}),
                timestamp: notification.timestamp ? notification.timestamp.toDate().toISOString() : new Date().toISOString(),
              },
              token: fcmToken,
            };

            await admin.messaging().send(message);
          }
        }
      } catch (error) {
        console.error('Error sending homework notification:', error);
      }
    }
  });

// Handle bus departure to school notifications
exports.sendBusDepartureToSchoolNotification = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Function must be called by authenticated user');
  }

  const { busId, driverId, studentIds } = data;

  // Get driver info
  const driverDoc = await admin.firestore().collection('Users').doc(driverId).get();
  const driverName = driverDoc.data()?.name || 'คนขับรถ';

  // Send notification to parents of all students on the bus
  for (const studentId of studentIds) {
    const parentSnapshot = await admin.firestore()
      .collection('Users')
      .where('role', '==', 'parent')
      .get();

    for (const parentDoc of parentSnapshot.docs) {
      const parentData = parentDoc.data();
      const children = parentData.children || [];
      
      if (children.includes(studentId)) {
        // Create notification in Firestore
        await admin.firestore().collection('Notifications').add({
          title: 'รถโรงเรียนกำลังเดินทาง',
          body: `รถโรงเรียนของคุณ ${driverName} กำลังเดินทางไปรับนักเรียนที่โรงเรียน`,
          type: 'bus_tracking',
          senderId: driverId,
          senderName: driverName,
          recipientId: parentDoc.id,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          isRead: false,
          payload: {
            busId: busId,
            driverId: driverId,
            action: 'departure_to_school',
          },
        });
      }
    }
  }

  return { success: true, message: `Notifications sent for bus ${busId}` };
});

// Handle student pickup notifications
exports.sendStudentBusPickupNotification = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Function must be called by authenticated user');
  }

  const { studentId, studentName, busId, driverId, location } = data;

  // Get driver info
  const driverDoc = await admin.firestore().collection('Users').doc(driverId).get();
  const driverName = driverDoc.data()?.name || 'คนขับรถ';

  // Find parents of this student
  const parentSnapshot = await admin.firestore()
    .collection('Users')
    .where('role', '==', 'parent')
    .get();

  for (const parentDoc of parentSnapshot.docs) {
    const parentData = parentDoc.data();
    const children = parentData.children || [];
    
    if (children.includes(studentId)) {
      // Create notification in Firestore
      await admin.firestore().collection('Notifications').add({
        title: 'รับนักเรียนขึ้นรถ',
        body: `นักเรียน ${studentName} ได้ขึ้นรถของคุณ ${driverName} เรียบร้อยแล้ว`,
        type: 'bus_tracking',
        senderId: driverId,
        senderName: driverName,
        recipientId: parentDoc.id,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        isRead: false,
        payload: {
          busId: busId,
          driverId: driverId,
          studentId: studentId,
          action: 'student_pickup',
          location: location,
        },
      });
    }
  }

  return { success: true, message: `Pickup notification sent for student ${studentName}` };
});

// Handle deadline reminder notifications (scheduled function)
exports.sendDeadlineReminders = functions.pubsub.schedule('every 1 hours from 06:00 to 00:00')
  .timeZone('Asia/Bangkok')
  .onRun(async (context) => {
    const now = new Date();
    const threeDaysFromNow = new Date();
    threeDaysFromNow.setDate(now.getDate() + 3);

    // Find assignments due in the next 3 days
    const assignmentsSnapshot = await admin.firestore()
      .collection('Assignments')
      .where('dueDate', '>', now)
      .where('dueDate', '<', threeDaysFromNow)
      .get();

    for (const assignmentDoc of assignmentsSnapshot.docs) {
      const assignment = assignmentDoc.data();
      
      // For each assigned student, check if they've submitted
      for (const studentId of assignment.assignedStudentIds || []) {
        // Check if student has submitted
        const submissionDoc = await admin.firestore()
          .collection('Assignments')
          .doc(assignmentDoc.id)
          .collection('Submissions')
          .doc(studentId)
          .get();
          
        if (!submissionDoc.exists) {
          // Student hasn't submitted, send reminder
          const daysUntilDue = Math.ceil((assignment.dueDate.toDate() - now) / (1000 * 60 * 60 * 24));
          
          // Create notification for student
          await admin.firestore().collection('Notifications').add({
            title: 'เตือน! งานที่ได้รับมอบหมายใกล้ถึงกำหนดส่ง',
            body: `งาน "${assignment.title}" จะครบกำหนดส่งในอีก ${daysUntilDue} วัน`,
            type: 'homework',
            senderId: 'system',
            senderName: 'ระบบ',
            recipientId: studentId,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            isRead: false,
            payload: {
              assignmentId: assignment.id,
              daysRemaining: daysUntilDue,
              dueDate: assignment.dueDate,
              action: 'deadline_reminder',
            },
          });

          // Create notification for parent (if applicable)
          const parentSnapshot = await admin.firestore()
            .collection('Users')
            .where('role', '==', 'parent')
            .get();

          for (const parentDoc of parentSnapshot.docs) {
            const parentData = parentDoc.data();
            const children = parentData.children || [];
            
            if (children.includes(studentId)) {
              await admin.firestore().collection('Notifications').add({
                title: 'เตือนลูกของคุณ! งานที่ได้รับมอบหมายใกล้ถึงกำหนดส่ง',
                body: `งาน "${assignment.title}" ของลูกคุณจะครบกำหนดส่งในอีก ${daysUntilDue} วัน`,
                type: 'homework',
                senderId: 'system',
                senderName: 'ระบบ',
                recipientId: parentDoc.id,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                isRead: false,
                payload: {
                  assignmentId: assignment.id,
                  studentId: studentId,
                  daysRemaining: daysUntilDue,
                  dueDate: assignment.dueDate,
                  action: 'deadline_reminder',
                },
              });
            }
          }
        }
      }
    }

    return null;
  });