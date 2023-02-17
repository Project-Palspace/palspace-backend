# palspace_backend

## Running the Application Locally

To build and start the development instance: 

```
$ make dev
```

To start the development instance if you already have an image of the backend locally: 

```
$ make up
```

To stop the container and destroy it:

```
$ make down
```

To generate the latest Swagger file: (Make sure the container is running `make up`)

```
$ make document
```

For more details see

```
$ make 
```


### Locally

1. Make sure you have conduit on your local machine.
```
$ dart pub global activate conduit
$ conduit --version
```

2. Run the server
```
$ onduit serve
```

## Running Application Tests

To run all tests for this application, run the following in this directory:

```
$ conduit test
```

## Deploying latest image to docker registry
WIP

## Deploying an Application
WIP
