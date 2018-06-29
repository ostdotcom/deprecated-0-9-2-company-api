# Pre Setup

* Setup Company Web. Instructions are published at:

  https://github.com/OpenSTFoundation/company-web/blob/master/README.md

* Install Mysql.
  ```bash
  > brew install mysql
  ```

* Create root user and set password as "root" in Mysql.
  ```bash
  ALTER USER 'root'@'localhost' IDENTIFIED BY 'root';
  ```
  * Sometimes you might face a client authentication error in Mysql. Run the following command to mitigate the issue:
    ```bash
    ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'root';
    ```

* Install Redis.
  ```main
  > brew install redis
  ```

* Install Memcached.
  ```main
  > brew install memcached
  ```

# Start Services

* Start Redis.
```main
> sudo redis-server --port 6379 --requirepass 'st123'
```

* Start MySQL.
```bash
> mysql.server start
```

* Start Memcached.
```bash
> memcached -p 11211 -d
```

* Run migration or install new packages.
```bash
> cd company-api
> source set_env_vars.sh
> bundle install
> rake db:create:all
> rake db:migrate
```

* Start SideKiq.
```bash
> cd company-api
> source set_env_vars.sh
> sidekiq -C ./config/sidekiq.yml -q sk_api_high_task  -q sk_api_med_task -q sk_api_default
```

  * Sometimes you might face an issue stating that sidekiq.pid file is not found.
    * In that case, remove the following line from config/sidekiq.yml:
    ```bash
    :pidfile: ./tmp/pids/sidekiq.yml
    ```
    * Start sidekiq.

* Populate "whitelisted_domains" table in Mysql with appropriate entries. Delete entire cache after this step.

* Start server in new terminal.
```bash
> cd company-api
> source set_env_vars.sh
> rails s -p 4001
```

* Set Cron Jobs (<b>NOTE: set set_env_vars.sh in .bash_profile for crons to run independently.</b>)
```bash
# Every one minute
> rake RAILS_ENV=development cron_task:continuous:process_email_service_api_call_hooks lock_key_suffix=1
```
