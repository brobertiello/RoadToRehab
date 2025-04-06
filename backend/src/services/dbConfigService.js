const mongoose = require("mongoose");
const godaddyService = require("./godaddyService");
require("dotenv").config();

class DbConfigService {
  constructor() {
    this.mongoUri = process.env.MONGODB_URI;
    this.isConnected = false;
  }

  // Connect to MongoDB Atlas
  async connect() {
    if (this.isConnected) {
      console.log("Already connected to MongoDB Atlas");
      return;
    }

    try {
      await mongoose.connect(this.mongoUri);
      this.isConnected = true;
      console.log("Connected to MongoDB Atlas");
    } catch (error) {
      console.error("Error connecting to MongoDB Atlas:", error.message);
      throw error;
    }
  }

  // Disconnect from MongoDB Atlas
  async disconnect() {
    if (!this.isConnected) {
      console.log("Not connected to MongoDB Atlas");
      return;
    }

    try {
      await mongoose.disconnect();
      this.isConnected = false;
      console.log("Disconnected from MongoDB Atlas");
    } catch (error) {
      console.error("Error disconnecting from MongoDB Atlas:", error.message);
      throw error;
    }
  }

  // Get connection status
  getConnectionStatus() {
    return {
      isConnected: this.isConnected,
      connectionString: this.mongoUri.replace(/\/\/(.*)@/, "//***:***@"), // Mask credentials
    };
  }

  // Setup GoDaddy DNS for MongoDB Atlas
  async setupGoDaddyDns(domain, subdomain, mongoIp) {
    try {
      // First check if domain exists
      const domains = await godaddyService.getDomains();
      const domainExists = domains.some((d) => d.domain === domain);

      if (!domainExists) {
        return {
          success: false,
          message: `Domain ${domain} not found in your GoDaddy account.`,
        };
      }

      // Add DNS record for MongoDB Atlas
      const result = await godaddyService.addMongoDBAtlasDnsRecord(domain, subdomain, mongoIp);

      return {
        success: true,
        message: `Successfully set up DNS record for MongoDB Atlas at ${subdomain}.${domain}`,
        details: result,
      };
    } catch (error) {
      console.error("Error setting up GoDaddy DNS for MongoDB Atlas:", error.message);
      return {
        success: false,
        message: `Failed to setup DNS: ${error.message}`,
      };
    }
  }
}

module.exports = new DbConfigService();
