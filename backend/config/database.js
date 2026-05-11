const mongoose = require('mongoose');
const logger = require('../utils/logger');

// Singleton instance to track connection state
let instance = null;

// Track initialization state
let isInitialized = false;

// Connection health check interval
let healthCheckInterval = null;

// Health check function
const performHealthCheck = async () => {
  try {
    if (mongoose.connection.readyState === 1) {
      // Connection is healthy, perform a simple ping
      await mongoose.connection.db.admin().ping();
      logger.debug('MongoDB health check passed');
    } else {
      logger.warn('MongoDB connection not healthy, attempting reconnection...');
      await connectDB();
    }
  } catch (error) {
    logger.error('MongoDB health check failed:', error.message);
    // Attempt reconnection on health check failure
    if (mongoose.connection.readyState !== 1) {
      try {
        await connectDB();
      } catch (reconnectError) {
        logger.error('Reconnection attempt failed:', reconnectError.message);
      }
    }
  }
};

// Start health check monitoring
const startHealthCheck = () => {
  if (healthCheckInterval) {
    clearInterval(healthCheckInterval);
  }

  // Perform health check every 60 seconds (less frequent to reduce load)
  healthCheckInterval = setInterval(performHealthCheck, 60000);
  logger.info('MongoDB health check monitoring started');
};

// Stop health check monitoring
const stopHealthCheck = () => {
  if (healthCheckInterval) {
    clearInterval(healthCheckInterval);
    healthCheckInterval = null;
    logger.info('MongoDB health check monitoring stopped');
  }
};

// Get connection status
const getConnectionStatus = () => {
  const states = {
    0: 'disconnected',
    1: 'connected',
    2: 'connecting',
    3: 'disconnecting'
  };

  return {
    readyState: mongoose.connection.readyState,
    status: states[mongoose.connection.readyState] || 'unknown',
    host: mongoose.connection.host,
    port: mongoose.connection.port,
    name: mongoose.connection.name,
    isHealthy: mongoose.connection.readyState === 1
  };
};

// Export connection status function
const getDBStatus = () => {
  return {
    connection: getConnectionStatus(),
    healthCheckActive: healthCheckInterval !== null,
    isInitialized: isInitialized
  };
};

const connectDB = async () => {
  // Check if already connected
  if (mongoose.connection.readyState === 1) {
    console.log('🟢 Already connected to MongoDB');
    return mongoose.connection;
  }

  // Check if connecting
  if (mongoose.connection.readyState === 2) {
    console.log('🔄 Already connecting to MongoDB, waiting...');
    return new Promise((resolve, reject) => {
      mongoose.connection.once('connected', () => resolve(mongoose.connection));
      mongoose.connection.once('error', reject);
    });
  }

  try {
    const mongoURI = process.env.MONGODB_URI;
    console.log('\n🔄 Connecting to MongoDB...');
    console.log('📡 URI:', mongoURI.replace(/:[^:]*@/, ':***@'));

    // Configure Mongoose for better stability
    mongoose.set('strictQuery', false);
    mongoose.set('bufferCommands', true);

    // MongoDB Atlas optimized connection options for production stability
    const connectionOptions = {
      // Connection timeouts - increased for Atlas stability
      serverSelectionTimeoutMS: 30000,  // 30 seconds for Atlas
      socketTimeoutMS: 45000,           // 45 seconds socket timeout
      connectTimeoutMS: 30000,          // 30 seconds connection timeout

      // Connection pool settings - optimized for Atlas
      maxPoolSize: 10,                  // Pool size for better performance
      minPoolSize: 2,                   // Keep minimum connections
      maxIdleTimeMS: 60000,             // 1 minute idle time

      // Retry settings - more aggressive for Atlas
      retryWrites: true,

      // Read preference - optimize for Atlas
      readPreference: 'primary',
    };

    // Connect to MongoDB
    const conn = await mongoose.connect(mongoURI, connectionOptions);

    console.log('\n✅ MongoDB Connected Successfully!');
    console.log('📊 Database:', conn.connection.name);
    console.log('🖥️  Host:', conn.connection.host);
    console.log('🌐 Port:', conn.connection.port);
    console.log('🔗 Connection State:', conn.connection.readyState);
    console.log('----------------------------------------\n');

    instance = conn;
    isInitialized = true;

    // Start health check monitoring after successful connection
    startHealthCheck();

    return instance;
  } catch (error) {
    console.error('\n❌ MongoDB Connection Error:', error.message);
    console.error('Stack:', error.stack);
    console.log('----------------------------------------\n');

    // Don't exit - let the health check monitor handle reconnection
    logger.error('MongoDB connection failed, will retry via health check:', error.message);
    return null;
  }
};

// Enhanced MongoDB connection event handlers with reconnection logic
mongoose.connection.on('connected', () => {
  console.log('🟢 MongoDB connection established');
  logger.info('MongoDB connection established');

  // Start health check when connection is established
  if (!healthCheckInterval) {
    startHealthCheck();
  }
});

mongoose.connection.on('error', (err) => {
  console.error('🔴 MongoDB connection error:', err.message);
  logger.error('MongoDB connection error:', err.message);
});

mongoose.connection.on('disconnected', () => {
  console.log('🟡 MongoDB connection disconnected');
  logger.warn('MongoDB connection disconnected');

  // Stop health check when disconnected
  stopHealthCheck();

  // Attempt reconnection after a delay
  setTimeout(async () => {
    if (mongoose.connection.readyState === 0) {
      console.log('🔄 Attempting to reconnect to MongoDB...');
      try {
        await connectDB();
      } catch (err) {
        console.error('❌ Reconnection failed:', err.message);
        logger.error('MongoDB reconnection failed:', err);
      }
    }
  }, 5000); // Wait 5 seconds before attempting reconnection
});

mongoose.connection.on('reconnected', () => {
  console.log('🟢 MongoDB reconnected');
  logger.info('MongoDB reconnected');

  // Restart health check when reconnected
  startHealthCheck();
});

mongoose.connection.on('close', () => {
  console.log('🔴 MongoDB connection closed');
  logger.info('MongoDB connection closed');

  // Stop health check when connection is closed
  stopHealthCheck();
});

// Graceful shutdown handling
process.on('SIGINT', async () => {
  try {
    console.log('\n🔄 Shutting down gracefully...');
    stopHealthCheck();
    await mongoose.connection.close();
    console.log('✅ MongoDB connection closed through app termination');
    process.exit(0);
  } catch (err) {
    console.error('❌ Error closing MongoDB connection:', err);
    process.exit(1);
  }
});

process.on('SIGTERM', async () => {
  try {
    console.log('\n🔄 Received SIGTERM, shutting down gracefully...');
    stopHealthCheck();
    await mongoose.connection.close();
    console.log('✅ MongoDB connection closed through SIGTERM');
    process.exit(0);
  } catch (err) {
    console.error('❌ Error closing MongoDB connection:', err);
    process.exit(1);
  }
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  console.error('❌ Unhandled Rejection at:', promise, 'reason:', reason);
  logger.error('Unhandled Rejection:', reason);
});

module.exports = {
  connectDB,
  getDBStatus,
  getConnectionStatus
};