/**
 * Secure Backend Agora Token Server
 * 
 * SECURITY BEST PRACTICE:
 * The Agora App Certificate must NEVER be shipped in mobile app code.
 * It stays securely on this backend server inside server-side environment variables.
 */

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const {
  RtcTokenBuilder,
  RtcRole,
  ChatTokenBuilder,
} = require('agora-token');

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 8080;
const AGORA_APP_ID = process.env.AGORA_APP_ID;
const AGORA_APP_CERTIFICATE = process.env.AGORA_APP_CERTIFICATE;

// Verify required credentials at startup
if (!AGORA_APP_ID || !AGORA_APP_CERTIFICATE) {
  console.error(
    'FATAL: AGORA_APP_ID and AGORA_APP_CERTIFICATE must be set in backend environment variables!'
  );
  process.exit(1);
}

// Token expiration time (in seconds - e.g. 3600 = 1 hour, 86400 = 24 hours)
const TOKEN_EXPIRY_SECONDS = 3600;

/**
 * Health check endpoint
 */
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

/**
 * Generate Dynamic Agora RTC Token
 * GET /api/rtc-token?channelName=Test&uid=12345&role=publisher
 */
app.get('/api/rtc-token', (req, res) => {
  const channelName = req.query.channelName;
  const uid = req.query.uid || 0;
  const roleParam = req.query.role || 'publisher';

  if (!channelName) {
    return res.status(400).json({ error: 'channelName query parameter is required' });
  }

  const role = roleParam === 'subscriber' ? RtcRole.SUBSCRIBER : RtcRole.PUBLISHER;
  const currentTimestamp = Math.floor(Date.now() / 1000);
  const privilegeExpiredTs = currentTimestamp + TOKEN_EXPIRY_SECONDS;

  try {
    let token;
    // Check if numeric UID or String UserAccount
    if (isNaN(uid)) {
      token = RtcTokenBuilder.buildTokenWithUserAccount(
        AGORA_APP_ID,
        AGORA_APP_CERTIFICATE,
        channelName,
        uid.toString(),
        role,
        privilegeExpiredTs,
        privilegeExpiredTs
      );
    } else {
      token = RtcTokenBuilder.buildTokenWithUid(
        AGORA_APP_ID,
        AGORA_APP_CERTIFICATE,
        channelName,
        parseInt(uid, 10),
        role,
        privilegeExpiredTs,
        privilegeExpiredTs
      );
    }

    return res.json({
      token,
      channelName,
      uid,
      expiresAt: privilegeExpiredTs,
    });
  } catch (error) {
    console.error('Error generating RTC token:', error);
    return res.status(500).json({ error: 'Failed to generate RTC token' });
  }
});

/**
 * Generate Agora Chat User Token
 * GET /api/chat-token?userId=user1
 */
app.get('/api/chat-token', (req, res) => {
  const userId = req.query.userId;
  if (!userId) {
    return res.status(400).json({ error: 'userId query parameter is required' });
  }

  try {
    const token = ChatTokenBuilder.buildUserToken(
      AGORA_APP_ID,
      AGORA_APP_CERTIFICATE,
      userId,
      TOKEN_EXPIRY_SECONDS
    );

    return res.json({
      token,
      userId,
      expiresIn: TOKEN_EXPIRY_SECONDS,
    });
  } catch (error) {
    console.error('Error generating Chat token:', error);
    return res.status(500).json({ error: 'Failed to generate Chat token' });
  }
});

app.listen(PORT, () => {
  console.log(`Agora Token Server running securely on port ${PORT}`);
});
