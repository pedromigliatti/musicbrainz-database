#!/bin/bash

cd /tmp

echo "Creating Musicbrainz database structure"

echo "postgresql:5432:musicbrainz:$POSTGRES_USER:$POSTGRES_PASSWORD"  > ~/.pgpass
chmod 0600 ~/.pgpass

psql -h postgresql -d musicbrainz -U $POSTGRES_USER -a -c "CREATE SCHEMA musicbrainz"

wget https://raw.githubusercontent.com/metabrainz/musicbrainz-server/master/admin/sql/Extensions.sql
psql -h postgresql -d musicbrainz -U $POSTGRES_USER -a -f Extensions.sql
rm Extensions.sql

wget https://raw.githubusercontent.com/metabrainz/musicbrainz-server/master/admin/sql/CreateTables.sql
wget https://raw.githubusercontent.com/metabrainz/musicbrainz-server/962c5c01e64988b8197eb6ea1325bec6af69ff7f/admin/sql/updates/20121015-caa-as-of-schema-15.sql
psql -h postgresql -d musicbrainz -U $POSTGRES_USER -a -f CreateTables.sql
psql -h postgresql -d musicbrainz -U $POSTGRES_USER -a -f 20121015-caa-as-of-schema-15.sql
rm CreateTables.sql
rm 20121015-caa-as-of-schema-15.sql

echo "Downloading last Musicbrainz dump"
wget -nd -nH -P /tmp http://ftp.musicbrainz.org/pub/musicbrainz/data/fullexport/LATEST
LATEST="$(cat /tmp/LATEST)"
wget -nd -nH -P /tmp http://ftp.musicbrainz.org/pub/musicbrainz/data/fullexport/$LATEST/mbdump-derived.tar.bz2
wget -nd -nH -P /tmp http://ftp.musicbrainz.org/pub/musicbrainz/data/fullexport/$LATEST/mbdump.tar.bz2
wget -nd -nH -P /tmp http://ftp.musicbrainz.org/pub/musicbrainz/data/fullexport/20181110-001544/mbdump-cover-art-archive.tar.bz2

echo "Uncompressing Musicbrainz dump"
tar xjf /tmp/mbdump-cover-art-archive.tar.bz2
rm mbdump-cover-art-archive.tar.bz2
tar xjf /tmp/mbdump-derived.tar.bz2
rm mbdump-derived.tar.bz2
tar xjf /tmp/mbdump.tar.bz2
rm mbdump.tar.bz2

for f in mbdump/*
do
 tablename="${f:7}"
 echo "Importing $tablename table"
 echo "psql -h postgresql -d musicbrainz -U $POSTGRES_USER -a -c COPY $tablename FROM '/tmp/$f'"
 chmod a+rX /tmp/$f
 psql -h postgresql -d musicbrainz -U $POSTGRES_USER -a -c "\COPY $tablename FROM '/tmp/$f'"
done

rm -rf mbdump

echo "Creating Indexes and Primary Keys"

wget https://raw.githubusercontent.com/metabrainz/musicbrainz-server/master/admin/sql/CreatePrimaryKeys.sql
psql -h postgresql -d musicbrainz -U $POSTGRES_USER -a -f CreatePrimaryKeys.sql
rm CreatePrimaryKeys.sql

wget https://raw.githubusercontent.com/metabrainz/musicbrainz-server/master/admin/sql/CreateIndexes.sql
psql -h postgresql -d musicbrainz -U $POSTGRES_USER -a -f CreateIndexes.sql
rm CreateIndexes.sql
