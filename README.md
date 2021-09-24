dbt-trino-incremental-hive
=====================

This is a test [dbt](https://www.getdbt.com/) project used to test `incremental` materialization with dbt-trino adapter.

[dbt-trino](https://github.com/findinpath/dbt-trino) is a `dbt` adapter used to interact with [Trino](https://trino.io/)

The dbt [incremental](https://docs.getdbt.com/docs/building-a-dbt-project/building-models/materializations#incremental) materialization provides two strategies:

- `append` : appends new entries to the model
- `insert_overwrite` : deletes eventually from the model the entries which exist in the staging table and then appends the staging entries to the model


This project is an attempt to test the `incremental` materializations on Trino by using the [hive](https://trino.io/docs/current/connector/hive.html) connector.




## Local setup

Use [virtualenv](https://pypi.org/project/virtualenv/) for creating a _virtual_ python environment:

```
pip3 install virtualenv
virtualenv venv
source venv/bin/activate

```


Install the feature branch of dbt-trino which contains the `incremental` materialization implemenation:


https://github.com/findinpath/dbt-trino/tree/feature/incremental

Run the command

```bash
pip3 install the_location_of_the_dbt_trino_directory
```

Spin up Docker environment for working with Trino & [minio](https://min.io/) hive compatible
object storage.

```
docker-compose up -d
```


In `~/.dbt/profiles.yml` add the following configuration:


```
trino-incremental-hive:
  target: dev
  outputs:
    dev:
      type: trino
      method: none
      user: admin
      password:
      catalog: minio
      schema: tiny
      host: localhost
      port: 8080
      http_scheme: http
      threads: 1  
```


Check now that everything is ok before performing the dbt transformations:

```
(venv)#  dbt debug
```

### Create a bucket in MinIO


Open [MinIO UI](http://localhost:9000/) by using the following credentials:

- access key: minio
- secret key: minio123

Create the bucket `tiny`



### Trino CLI

```
docker container exec -it trino-dbt-trino-incremental-hive_trino-coordinator_1 trino
```

```
trino> show catalogs;
```


### Create Trino `minio.tiny` schema

```
CREATE SCHEMA minio.tiny
WITH (location = 's3a://tiny/');
```

### Create `minio.tiny.raw_customer` hive table


```sql
CREATE TABLE minio.tiny.raw_customer (            
    id bigint,                                     
    first_name varchar(32),                        
    last_name varchar(32),                         
    email varchar(256)                             
 )                                                 
 WITH (                                            
    external_location = 's3a://tiny/raw_customer', 
    format = 'ORC'                                 
 );
```

### Populate `minio.tiny.raw_customer` hive table


```
INSERT INTO minio.tiny.raw_customer (id, first_name, last_name, email)
    VALUES 
        (1,'Michael','Perez','mperez0@chronoengine.com'),
        (2,'Shawn','Mccoy','smccoy1@reddit.com'),
        (3,'Kathleen','Payne','kpayne2@cargocollective.com');

```


### Run dbt for creating the models

```bash
(venv)# dbt run
```


### Troubleshooting

The problems start occuring when running `dbt` more than once.

Here is an example

```
Runtime Error in model customer_insert_overwrite (models/marts/core/customer_insert_overwrite.sql)
  TrinoUserError(type=USER_ERROR, name=NOT_SUPPORTED, message="Deletes must match whole partitions for non-transactional tables", query_id=20210924_074331_00048_njuyb)
```



### Stop the Trino environment

```
docker-compose down
```
