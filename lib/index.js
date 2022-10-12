const functions = require('@google-cloud/functions-framework');

// functions.http('helloHttp', (req, res) => {
//  res.send(`Hello ${req.query.name || req.body.name || 'World'}!`);
// });


import { OAuth2Client } from 'google-auth-library';

const oauth2Client = new OAuth2Client(process.env.app_oauth2_client_id);

async function verifyOauth2Token(token) {
  const ticket = await oauth2Client.verifyIdToken({
    idToken: token,
    audience: [process.env.app_oauth2_client_id]
  });
  return ticket.getPayload();
}

const tokenInfo = await verifyOauth2Token(token);


