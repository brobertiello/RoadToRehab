const axios = require("axios");
require("dotenv").config();

class GoDaddyService {
  constructor() {
    this.baseUrl = "https://api.godaddy.com/v1";
    this.apiKey = process.env.GODADDY_API_KEY;
    this.apiSecret = process.env.GODADDY_API_SECRET;
    this.headers = {
      Authorization: `sso-key ${this.apiKey}:${this.apiSecret}`,
      "Content-Type": "application/json",
    };
  }

  // Get all domains in the account
  async getDomains() {
    try {
      const response = await axios.get(`${this.baseUrl}/domains`, {
        headers: this.headers,
      });
      return response.data;
    } catch (error) {
      console.error("Error fetching domains:", error.message);
      throw error;
    }
  }

  // Get details for a specific domain
  async getDomainDetails(domain) {
    try {
      const response = await axios.get(`${this.baseUrl}/domains/${domain}`, {
        headers: this.headers,
      });
      return response.data;
    } catch (error) {
      console.error(`Error fetching details for domain ${domain}:`, error.message);
      throw error;
    }
  }

  // Get DNS records for a domain
  async getDnsRecords(domain, type = "A") {
    try {
      const response = await axios.get(`${this.baseUrl}/domains/${domain}/records/${type}`, {
        headers: this.headers,
      });
      return response.data;
    } catch (error) {
      console.error(`Error fetching DNS records for domain ${domain}:`, error.message);
      throw error;
    }
  }

  // Add DNS record for MongoDB Atlas
  async addMongoDBAtlasDnsRecord(domain, name, ip) {
    try {
      const records = [
        {
          name,
          data: ip,
          ttl: 600,
          type: "A",
        },
      ];

      const response = await axios.patch(`${this.baseUrl}/domains/${domain}/records/A/${name}`, records, {
        headers: this.headers,
      });

      return { success: true, message: `DNS record for MongoDB Atlas created at ${name}.${domain}` };
    } catch (error) {
      console.error(`Error creating DNS record:`, error.message);
      throw error;
    }
  }
}

module.exports = new GoDaddyService();
