## TODO
- [x] Add Firestore 
- [x] Remove printing of the token to the console
- [ ] Add more endpoints
- [ ] FIX: For some reason the http client unauthenticated and not requesting
  google scopes has more permissions than the authenticated client. For example, when making a signup request for the AUthenticated client, it is successful but does not return an idToken. However, when making the same request with the unauthenticated client, it returns an idToken.  It likely has something to do with the google apis package, or the scopes that are being requested (ie insufficient scopes for firebase auth). Need to look into this. 
  In the meantime, I will use the unauthenticated client for all but firestore requests.
