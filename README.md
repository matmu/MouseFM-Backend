# MouseFM Backend
This repository contains the backend of the MouseFM tool including the scripts of the etl process and the webserver. The MouseFM client is available as an R package on Github (https://github.com/matmu/MouseFM) or on Bioconductor (https://bioconductor.org/packages/devel/bioc/html/MouseFM.html).


## Directories and files

### Database SQL dump
A dump of the database is available at https://drive.google.com/file/d/16QVwdWw79lGlXudWTNFpULYDfSdNQQYQ/view?usp=sharing (932MB).

### Extraction, Translation, Loading
The scripts for building the database are located under `etl/`. This is only relevant if you want to create a new version of the database Run `process.sh` to execute the ETL pipeline. Before running the pipeline make sure that a MySQL database was created and that the login information is consistent with the one in `loading.pl`.

### Webserver
The webserver of MouseFM is located under `webserver/`. Configurations such as MySQL user can be adapted in `webserver/conf/application.conf`. For debugging purposes the webserver can be started with `webserver/process.sh`.


## Deployment

### Using docker-compose
The webserver of MouseFM can be started using Docker. To do so you need to place the database file `mousefm.100.sql.gz` in the root directory of this repository and start using `docker-compose up -d`. The first start will take some time as the MySQL database will be imported into a Docker volume. By default, the database files of the new volume are stored at `/var/lib/docker/volumes/`. After that the webserver should be available at port `9000`.

###  On the local Ubuntu system
Make sure a local version of MySQL or MariaDB is installed and a respective user is set up according to `webserver/conf/application.conf`.

To load it into a newly created database, use the following code.
```bash
mysql -u mysql -p 8erbahn < mousefm.100.sql
```

Alternatively, you can load the compressed file directly by creating a named pipe:
```bash
mkfifo --mode=0666 /tmp/mousefm
gzip --stdout -d mousefm.100.sql.gz > /tmp/mousefm
mysql -u mysql -p 8erbahn < /tmp/mousefm
```

For debugging purposes the webserver can be started with `webserver/process.sh`.
