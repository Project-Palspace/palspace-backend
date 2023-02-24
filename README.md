# palspace_backend

## Running the Application Locally (MacOS/Linux)

1. Build and start the development instance: 

```
$ make dev
```

2. Start the development instance if you already have an image of the backend locally: 

```
$ make up
```

To stop the container and destroy it:

```
$ make down
```

For more details see

```
$ make 
```

## Running the Application Locally (Windows)

### Prerequisites

1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop)
2. Install chocolatey (https://chocolatey.org/install)
3. Install choco packages (make, mkcert, sed)
```
$ choco install make mkcert sed
```
4. Install [Flutter SDK](https://docs.flutter.dev/get-started/install) or [Dart SDK](https://dart.dev/get-dart)
5. Run steps 1-2 from the [Running the Application Locally (MacOS/Linux)](#running-the-application-locally-macoslinux) section. (Makefile is adapted to work on Windows)

### Locally

1. Install dependencies
```
$ pub get
```

2. Run the server
```
$ dart run bin/server.dart
```

## Running Application Tests

To run all tests for this application, run the following in this directory:

```
$ dart test
```

## Deploying latest image to docker registry
WIP

## Deploying an Application
WIP
