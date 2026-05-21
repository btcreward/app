const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const FIREBASE_PROJECT_ID = 'btc-reward-35f8c';
const FIREBASE_DATABASE_URL =
    process.env.FIREBASE_DATABASE_URL || `https://${FIREBASE_PROJECT_ID}.firebaseio.com`;

const getServiceAccountFromEnv = () => {
    if (!process.env.FIREBASE_PRIVATE_KEY || !process.env.FIREBASE_CLIENT_EMAIL) {
        return null;
    }

    if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_PROJECT_ID !== FIREBASE_PROJECT_ID) {
        throw new Error(
            `FIREBASE_PROJECT_ID must be ${FIREBASE_PROJECT_ID}, got ${process.env.FIREBASE_PROJECT_ID}`
        );
    }

    return {
        type: process.env.FIREBASE_TYPE || 'service_account',
        project_id: FIREBASE_PROJECT_ID,
        private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
        private_key: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
        client_email: process.env.FIREBASE_CLIENT_EMAIL,
        client_id: process.env.FIREBASE_CLIENT_ID,
        auth_uri: process.env.FIREBASE_AUTH_URI || 'https://accounts.google.com/o/oauth2/auth',
        token_uri: process.env.FIREBASE_TOKEN_URI || 'https://oauth2.googleapis.com/token',
        auth_provider_x509_cert_url:
            process.env.FIREBASE_AUTH_PROVIDER_X509_CERT_URL ||
            'https://www.googleapis.com/oauth2/v1/certs',
        client_x509_cert_url: process.env.FIREBASE_CLIENT_X509_CERT_URL
    };
};

const initializeFirebase = () => {
    try {
        if (admin.apps.length) {
            return admin;
        }

        const serviceAccountPath = path.join(
            __dirname,
            '../btc-reward-35f8c-firebase-adminsdk.json'
        );

        if (fs.existsSync(serviceAccountPath)) {
            const serviceAccount = require(serviceAccountPath);
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount),
                databaseURL: FIREBASE_DATABASE_URL
            });
        } else {
            const serviceAccount = getServiceAccountFromEnv();
            if (!serviceAccount) {
                throw new Error(
                    'Missing Firebase Admin credentials. Add backend/btc-reward-35f8c-firebase-adminsdk.json or set FIREBASE_* environment variables for btc-reward-35f8c.'
                );
            }

            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount),
                databaseURL: FIREBASE_DATABASE_URL
            });
        }

        console.log(`Firebase Admin SDK initialized for ${FIREBASE_PROJECT_ID}`);
        return admin;
    } catch (error) {
        console.error('Firebase Admin SDK initialization failed:', error);
        throw error;
    }
};

const verifyIdToken = async (idToken) => {
    try {
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        return {
            success: true,
            data: decodedToken
        };
    } catch (error) {
        console.error('Firebase token verification failed:', error);
        return {
            success: false,
            error: error.message
        };
    }
};

const getUserByUid = async (uid) => {
    try {
        const userRecord = await admin.auth().getUser(uid);
        return {
            success: true,
            data: userRecord
        };
    } catch (error) {
        console.error('Firebase user fetch failed:', error);
        return {
            success: false,
            error: error.message
        };
    }
};

module.exports = {
    admin,
    initializeFirebase,
    verifyIdToken,
    getUserByUid
};
