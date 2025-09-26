# TypeDB and Qdrant data artifacts

This readme provides instructions and a script for creating and loading a data artifact of TypeDB and Qdrant data. The artifact can be shared with others to provide jump start in the development proces.

## Prerequisites

- Make sure that `/data/typedb` and `/data/qdrant` directories exist to prevent issues with insufficient permissions errors with docker.
- Docker Engine
- Docker Compose
- Tar, check with `tar --version` if it is installed.
- (Optional) [typedb console 2.x](https://typedb.com/docs/home/2.x/install-tools#_console) for interacting with TypeDB from the console.

## Creating a Data Artifact

To create a data artifact these steps should be followed:

1. Run `docker-compose up`

	- This creates a TypeDB and a Qdrant container.

2. Initialize the data stores by running the `database-builder` application, which resides in it's own repository.

	View the documentation of the [`database-builder`](https://github.com/AIM-kennisplatformen/database-builder/blob/main/README.md#to-use).
	
	Below is a simplified explanation of the steps.
	- Call the `/init` endpoint
	- Insert any number of documents
	- Call the `/persist` endpoint

2. Run `./manage.sh`
	- Select option 3 "Package current data"
	- Give a name to the data artifact (e.g. `knowledgeplatform-data`) without the `.tar.gz` extension

3. Share the data artifact that was just created placed inside the `data` directory (e.g. `/data/knowledgeplatform-data.tar.gz`) of this repository.

## Updating a Data Artifact

1. Load the data artifact you want to update by running `./manage.sh` and selecting option 2 "Load data from an artifact".

2. Run `docker-compose up`

3. Adjust the data as you want by interacting with it trough the `database-builder` application.

4. Run `./manage.sh`
	- Select option 3 "Package current data"

5. Share the data artifact that was just created

## Loading a Data Artifact

To load a data artifact into TypeDB and Qdrant these steps should be followed:

1. Place the data artifact (e.g. `knowledgeplatform-data.tar.gz`) into the local `./data` directory of this repository.

2. Run `./manage.sh`.
	- Select option 2 "Load data from an artifact"
	- Select the artifact you wish to load (e.g. `knowledgeplatform-data.tar.gz`)
	- Save the currently loaded data if needed

3. Run `docker-compose up`

## Stopping the Container

To stop and remove the container, run: `docker-compose down`

This will stop the container but keep the data artifact.
 