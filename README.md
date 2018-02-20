# Pre Setup

* Install Mysql
```bash
> brew install mysql
```
* Create root user and set Password as root in Mysql
* Create a default db - company_sandbox_development

* Install redis
```main
> brew install redis
```

* Install Memcache
```main
> brew install memcached
```

# Start Services

* Start redis
```main
> sudo redis-server --requirepass 'st123'
```

* Start MySQL
```bash
> mysql.server start
```

* Start Memcached
```bash
> memcached -p 11211 -d
```

* Run migration or install new packages
```bash
> cd company-api
> source set_env_vars.sh
> bundle install
> rake db:migrate
# NOTE: remove and create db again
rake db:drop:all
rake db:create:all
```

* Start SideKiq
```bash
> cd company-api
> source set_env_vars.sh
> sidekiq -C ./config/sidekiq.yml -q sk_api_high_task  -q sk_api_med_task -q sk_api_default
```

* Start server
```bash
> cd company-api
> source set_env_vars.sh
> rails s -p 4000
```


