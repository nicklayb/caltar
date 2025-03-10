# Caltar

Calendar platform that supports various providers.

## Installation

### With Docker

```yml
services:
  app:
    image: nboisvert/caltar:latest
    container_name: caltar
    ports:
      - "4000:4000"
    volumes:
      - ./data:/opt/data
    environment:
      - TZ=America/Montreal
      - LOCALE=fr
      - GEONAMES_USERNAME=nboisvert
      - SECRET_KEY_BASE=...
      - LIVE_VIEW_SALT=...
      - DATABASE_PATH=/opt/data/db.sqlite
      - APP_HOST=http://localhost:4000
    restart: always
```

**Note**: It is recommended to mount a local folder at `/opt/data` otherwise the databas will be reset at every restart.

Once the app starts, a default calendar called "Main" will be created.

You can then head to `http://localhost:4000` to show the calendar or `http://localhost:4000/settings` to go to the settings and configure your calendar.

#### Environment

- `TZ`: Timezone to convert calendar dates
- `LOCALE`: Language, only `fr` and `en` are supported so far.
- `GEONAMES_USERNAME`: Username of a user that has access to [Geonames](https://www.geonames.org/) (Only required to use with Formula 1 provider.
- `SECRET_KEY_BASE`: Any random characters sequence of 64 characters long
- `LIVE_VIEW_SALT`: Any random characters sequence of 32 characters long
- `DATABASE_PATH`: Path to the sqlite database (It **must** be scoped under `/opt/data` inside the container).
- `APP_HOST`: Must represent the host from which you wanna access the app.

## Current provider supported

- `Icalendar`: Supports `ics` endpoint to show icalendar format.
- `Formula1`: Wrapper over `Icalendar` that are formatted more appropriately for Formula 1 (requires a `GEONAMES_USERNAME` env variable with a username registered at [Geonames](https://www.geonames.org/))
- `Birthdays`: Birthday list
- `Sport`: Schedule and live sporting event provided by either [theScore](https://thescore.com) or Hockey Tech (Provides mostly Canadian Hockey League).
- `Recurring`: Recurring event that occurs every x weeks for instance.

