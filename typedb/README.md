# TypeDB Data Container

This readme provides instructions and a script for creating or loading a TypeDB data artifact. The artifact can be shared with others to provide jump start in the development proces.

## Prerequisites

- Docker Engine
- Docker Compose
- Tar, check with `tar --version` if it is installed.
- (Optional) [typedb console 2.x](https://typedb.com/docs/home/2.x/install-tools#_console) for interacting with TypeDB from the console.

## Creating or updating a Data Artifact

To create a data artifact these steps should be followed:

1. Have a TypeDB container with the name `knowledgeplatform-typedb` running

	- This TypeDB container can 

2. Run `./manage.sh`
	- Select option 3 "Package current data"
	- Give a name to the data artifact (e.g. `knowledgeplatform-data`) without the `.tar.gz` extension

3. Share the data artifact that was just created placed inside the `data` directory (e.g. `/data/knowledgeplatform-data.tar.gz`)

## Loading a Data Artifact

To load a data artifact into a new TypeDB container these steps should be followed:

1. Place the data artifact (e.g. `knowledgeplatform-data.tar.gz`) into the local `./data` directory.

2. Run `./manage.sh`.
	- Select option 2 "Load data from an artifact"
	- Select the artifact you wish to load (e.g. `knowledgeplatform-data.tar.gz`)
	- Save the currently loaded data if needed

3. Run `docker-compose up`

## Stopping the Container

To stop and remove the container, run: `docker-compose down`

This will stop the container but keep the data artifact.