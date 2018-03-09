# Pre Setup

* Setup Company Web. Instrunctions are published: https://github.com/OpenSTFoundation/company-web/blob/master/README.md

* Install Mysql
```bash
> brew install mysql
```

* Create root user and set Password as root in Mysql

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
> rake db:create:all
> rake db:migrate
```

* Start SideKiq in New Terminal
```bash
> cd company-api
> source set_env_vars.sh
> sidekiq -C ./config/sidekiq.yml -q sk_api_high_task  -q sk_api_med_task -q sk_api_default
```

* Start server in New Terminal
```bash
> cd company-api
> source set_env_vars.sh
> rails s -p 4001
```

* Set Cron Jobs
```bash
# Every one minute
> rake RAILS_ENV=development cron_task:continuous:process_email_service_api_call_hooks lock_key_suffix=1
```

