# MouseFM-Backend

## Extraction, Translation, Loading
The scripts for building the database are located under `etl/`. Run `process.sh` to execute the ETL pipeline. Before running the pipeline make sure that a MySQL database was created and that the login information is consistent with the one mentioned in `loading.pl`.

## Webserver
The webserver of MouseFM is located under `webserver/`. Configurations such as MySQL user can be adapted in `webserver/conf/application.conf`. For debugging purposes the webserver can be started with `webserver/process.sh`.
