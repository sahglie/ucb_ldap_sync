
# README

## Application Setup
* Download and install Docker Desktop (www.docker.com)
* Git clone repo
* Copy .env to .env.test and .env.development
* Add LDAP config to .env.test and .env.development 
* Prepare image

```
docker compose build .
docker compose run web bin/rails db:create
docker compose run -e RAILS_ENV=development web bin/rails ucb_ldap_sync:db:refresh
docker compose run -e RAILS_ENV=test web bin/rails ucb_ldap_sync:db:refresh
```

# Run tests

```
docker compose run -e RAILS_ENV=test web bin/rails test -p
```
