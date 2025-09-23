# TypeDB Data Container

This readme provides instructions and a script for creating a data artifact of a TypeDB container that can be shared with others and starting the TypeDB container with or without a data artifact.  

## Prerequisites

- Docker engine
- Docker Compose
- (Optional) [typedb console 2.x](https://typedb.com/docs/home/2.x/install-tools#_console)

## Creating or updating a Data Artifact

To create a data artifact these steps should be followed:

1. Have a TypeDB container with the name `knowledgeplatform-typedb` running

	- To update an artifact run the `database-builder` application and insert as many documents as needed.

2. Run `package.sh`

3. Share the data artifact placed at `/data/knowledgeplatform-data.tar.gz`

## Loading a Data Artifact

To load a data artifact into a new TypeDB container these steps should be followed:

1. Place the `knowledgeplatform-data.tar.gz` file into the local `/data` directory.

2. Run `docker-compose up -d`.

The `entrypoint.sh` script will find the artifact, clear any existing data in the container, and load the new data from your artifact before starting the server. If no data artifact or an invalid artifact has been placed in the `/data` directory the container will start with an empty database.

## Stopping the Container

To stop and remove the container, run: `docker-compose down`

This will stop the container but keep the data artifact.