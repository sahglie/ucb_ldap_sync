
# README

## Application Setup
* Download and install Docker Desktop (www.docker.com)
* Git clone repo
* Obtain .env file (creds to external services)
* Start the application:

```
docker compose build .
docker compose up -d
docker compose exec web bin/rails db:create
docker compose exec -e RAILS_ENV=development web bin/rails ucb_ldap_sync:db:refresh
```
