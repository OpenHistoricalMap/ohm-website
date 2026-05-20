## Setup OHM Web in Development Mode
Here are simple steps to set up the OHM web application for development using Docker containers. This development setup relies on the environment variables defined in the `ohm-docker.dev.env` file. You do not need to rename this file.

### Requirement: clone ohm-website-patches alongside

`docker-compose.dev.yml` bind-mounts OHM-specific files from a sibling repo `ohm-website-patches`. Clone it at the same level as `ohm-website`:

```
apps/
├── ohm-website/
└── ohm-website-patches/   ← required for dev
```

```sh
git clone git@github.com:OpenHistoricalMap/ohm-website-patches.git ../ohm-website-patches
```

Without it, `docker compose` will fail to mount the overlay files.

### Build and run

To start in development mode, simply run the following command. This will launch the database, a Memcached instance, and the Rails container.

```sh
docker compose -f docker-compose.dev.yml build

## this command will bring you inside a continaer 
docker compose -f docker-compose.dev.yml run  --service-ports web bash
```

Once you are inside the container, run the following command:

```sh
./start.sh
```

### Editing OHM-customized files

Files like `app/assets/javascripts/leaflet.map.js`, `config/settings.yml`, `app/views/layouts/_head.html.erb`, etc. are mounted from `../ohm-website-patches/overlays/`. Edit them there and refresh the browser — Sprockets recompiles on the fly. Commits for those files go to the `ohm-website-patches` repo, not here.



If you want to restart from scratch, make sure you remove the volumes and then run the command to start the containers again

```sh
docker compose -f docker-compose.dev.yml down --remove-orphans
docker volume rm ohm-website_db-data
docker volume rm ohm-website_web-storage
docker volume rm ohm-website_web-tmp
```


## User Login
This environment comes with pre-registered users that you can use to log in and make edits in iD:

Admin: admin / 12345678
Regular user: test / 12345678


## ⚠️ Do Not Commit
This workflow modifies config/settings.yml by replacing values to make the development environment work properly.
If you're working on site improvements, please remember not to commit this file, as it has been customized specifically for local development purposes.
