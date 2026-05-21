// backend/utils/fcm.js
const { admin, initializeFirebase } = require('../config/firebase.config');
const User = require('../models/user.model');

initializeFirebase();

/**
 * Send a push notification to a user by userId
 * @param {String} userId - The user's MongoDB ID
 * @param {Object} notification - { title, body, data }
 * @returns {Promise<Object>} FCM response
 */
async function sendPushToUser(userId, notification) {
    try {
        const user = await User.findById(userId);
        if (!user || !user.fcmToken) {
            throw new Error('User or FCM token not found');
        }

        const message = {
            token: user.fcmToken,
            notification: {
                title: notification.title,
                body: notification.body
            },
            data: notification.data || {}
        };

        const response = await admin.messaging().send(message);
        console.log('Push notification sent successfully:', response);
        return response;
    } catch (error) {
        console.error('Failed to send push notification:', error);
        throw error;
    }
}

module.exports = { sendPushToUser };
