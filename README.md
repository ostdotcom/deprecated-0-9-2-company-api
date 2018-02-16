# Pre Setup

* Install Mysql
```bash
> brew install mysql
```
* Create root user and set Password as root in Mysql
* Create a default db - company_sandbox_development


# Start Services

```
> bundle install
> source set_env_vars.sh
> mysql.server start
> rake db:migrate
> rails s -p 4000
```


