Documentation: https://firebase.google.com/docs/reference/rest/auth#section-update-profile

**Update profile**

    ```bash
    curl 'https://identitytoolkit.googleapis.com/v1/accounts:update?key=[API_KEY]' \
    -H 'Content-Type: application/json' \
    --data-binary \
    '{"idToken":"[ID_TOKEN]","displayName":"[NAME]","photoUrl":"[URL]","returnSecureToken":true}'
    ```

**Sign in with email and password**

    ```bash
    curl 'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=[API_KEY]' \
    -H 'Content-Type: application/json' \
    --data-binary \
    '{"email":"[EMAIL]","password":"[PASSWORD]","returnSecureToken":true}'
    ```

**Get user data**

    ```bash
    curl 'https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=[API_KEY]' \
    -H 'Content-Type: application/json' --data-binary '{"idToken":"[FIREBASE_ID_TOKEN]"}'
    ```

