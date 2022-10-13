

# Sample Server

A sample Dart HTTP server that acts as middleware between the client and the services. 

It is used to simplify the client code and to provide a single point of access to the services.

## Features

- Auth service: [Firebase Auth REST API](https://firebase.google.com/docs/reference/rest/auth)   
- Database service: [Cloud Firestore NoSQL database](https://console.cloud.google.com/apis/api/firestore.googleapis.com)  
- Served on: Google [Cloud Run](https://cloud.google.com/run)  

This server is meant to be deployed on Google Cloud Run. It is a simple HTTP server that acts as a proxy between the client and the services.

It allows for the following features:
- Authentication: The client can authenticate with the server. The server uses the Firebase Auth REST API to authenticate the user with the Firebase Auth service. The server then returns a JWT token that can be used to authenticate the user with the services.  
  Authentication methods:  
    - Email/Password login or signup  
    - Anonymous login 

- Database: The client can read and write to the database. The server uses the Cloud Firestore REST API to read and write to the database.



## Endpoints
<!-- TODO: Add documentation for endpoints -->
See source code for more details. Each endpoint is documented with a description
and a sample request. 

- GET /
- POST /login
- POST /loginAnonymously
- POST /signup
- GET /verifyIdToken
- GET /getProfile
- POST /updateProfile
- GET /issues

<!-- GET /db -->
<!-- TODO: Update with all endpoints -->


## Setup
### Prerequisites
- A Google Cloud Platform account
- A Google Cloud Project
- Billing enabled on your Google Cloud Platform project
- A service account for the GCP project 
  - ***Cloud Run Invoker*** role
- A Firebase project
- An API key for the Firebase project
- A Cloud Firestore database
- Firebase Auth service enabled in the Firebase project with the following sign-in methods enabled:
    - Email/Password
    - Anonymous
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
- [Dart SDK](https://dart.dev/get-dart)

### Deploying 


See: [Deploying on Google Cloud Run from source](https://cloud.google.com/run/docs/quickstarts/build-and-deploy/deploy-service-other-languages#deploy)  

In a nutshell:
  - Deploy the service using gcloud sdk:  `gcloud run deploy`  
    - For region, use `us-central1`  
    - To publish revisions, use 
    `gcloud run deploy --source .`   
    This builds the Docker image and deploys it to Cloud Run. See [Dockerfile](Dockerfile) for more details.
    <!-- `gcloud run deploy --image <container-image-url>`   -->
  - Set the environment variables 
    - I used [Secret Manager](https://cloud.google.com/secret-manager) to store the environment variables. Then [set the environment variables in Cloud Run](https://cloud.google.com/run/docs/configuring/secrets#access-secret)   

## Running locally
First set the following environment variables:
- `GOOGLE_APPLICATION_CREDENTIALS` - path to the service account key file
- `GCP_PROJECT` - the project ID
- `FIREBASE_API_KEY` - the API key for the Firebase project (see [here](https://firebase.google.com/docs/projects/api-keys)

> Note: For convenience, you can use [this script](set_env.sh) to set the environment variables from a file. See sample env file [here](.env_example).   
> `$ source set_env.sh <path-to-env-file>`  

Then run the server:
- `dart pub get`
- `dart run bin/server.dart`
 
or as an executable: 
  - get the dependencies: `dart pub get`
  - build: `dart compile exe bin/server.dart -o bin/server`
  - run: `bin/server` 



## Maintainers  
- [lenz.paul@cmic.ca](mailto:Lenz.Paul@cmic.ca) 
