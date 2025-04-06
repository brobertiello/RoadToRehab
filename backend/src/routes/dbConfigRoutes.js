const express = require("express");
const router = express.Router();
const dbConfigService = require("../services/dbConfigService");
const godaddyService = require("../services/godaddyService");
const auth = require("../middleware/auth");

// Get MongoDB connection status
router.get("/status", auth, async (req, res) => {
  try {
    const status = dbConfigService.getConnectionStatus();
    res.status(200).json(status);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get all GoDaddy domains
router.get("/godaddy/domains", auth, async (req, res) => {
  try {
    const domains = await godaddyService.getDomains();
    res.status(200).json(domains);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get DNS records for a domain
router.get("/godaddy/domains/:domain/records", auth, async (req, res) => {
  try {
    const { domain } = req.params;
    const { type } = req.query;
    const records = await godaddyService.getDnsRecords(domain, type || "A");
    res.status(200).json(records);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Setup MongoDB Atlas with GoDaddy DNS
router.post("/godaddy/setup", auth, async (req, res) => {
  try {
    const { domain, subdomain, mongoIp } = req.body;

    if (!domain || !subdomain || !mongoIp) {
      return res.status(400).json({
        error: "Missing required fields: domain, subdomain, mongoIp",
      });
    }

    const result = await dbConfigService.setupGoDaddyDns(domain, subdomain, mongoIp);

    if (result.success) {
      res.status(200).json(result);
    } else {
      res.status(400).json(result);
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
