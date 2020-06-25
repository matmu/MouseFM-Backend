# MouseFM-Backend
This repository contains the backend of the MouseFM tool including the scripts of the etl process and the webserver. The MouseFM client is available as an R package on Github (https://github.com/matmu/MouseFM) or on Bioconductor (https://bioconductor.org/packages/devel/bioc/html/MouseFM.html).


## Extraction, Translation, Loading
The scripts for building the database are located under `etl/`. Run `process.sh` to execute the ETL pipeline. Before running the pipeline make sure that a MySQL database was created and that the login information is consistent with the one mentioned in `loading.pl`.


## Webserver
The webserver of MouseFM is located under `webserver/`. Configurations such as MySQL user can be adapted in `webserver/conf/application.conf`. For debugging purposes the webserver can be started with `webserver/process.sh`.


## Database SQL dump
A dump of the database is available at https://drive.google.com/file/d/16QVwdWw79lGlXudWTNFpULYDfSdNQQYQ/view?usp=sharing (932MB).

To load it into a newly created database, use the following code.
```bash
mysql -u mysql -p mousefm < mousefm.100.sql
```

Alternatively, you can load the compressed file directly by creating a named pipe:
```bash
mkfifo --mode=0666 /tmp/mousefm
gzip --stdout -d mousefm.100.sql.gz > /tmp/mousefm
mysql -u mysql -p mousefm < /tmp/mousefm
```
