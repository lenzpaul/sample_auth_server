ARG build_env=runtime

# Official Dart image: https://hub.docker.com/_/dart
# Specify the Dart SDK base image version using dart:<version> (ex: dart:2.12)
FROM dart:stable AS build

# Resolve app dependencies.
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

# Copy app source code and AOT compile it.
COPY . .
# Ensure packages are still up-to-date if anything has changed
RUN dart pub get --offline
RUN dart compile exe bin/server.dart -o bin/server

# Build minimal serving image from AOT-compiled `/server` and required system
# libraries and configuration files stored in `/runtime/` from the build stage.
FROM scratch AS build_runtime
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/
# README.md: Served on main route `/`
COPY --from=build /app/README.md /app/
# ONBUILD RUN echo "build_env set to 'runtime'"


# If DEBUG is set to true, copy the creds file to the container
# FROM scratch as build_debug
FROM build_runtime AS build_debug
# For debugging purposes only, this will fail on cloud run. Using this to test
# locally as the container needs google credentials. These are not needed on
# cloud run.
#
# This runs when the container is built using the `--build-arg build_env=debug` flag. 
# e.g: `docker image build -t sample_server --build-arg build_env=debug .`
ONBUILD COPY --from=build /app/.google_application_default_credentials.json /app/.google_application_default_credentials.json


FROM build_${build_env} 







WORKDIR /app
# Start server.
EXPOSE 8080
# CMD ["/app/bin/server"]
CMD ["bin/server"]
