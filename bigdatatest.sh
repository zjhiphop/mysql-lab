#!/bin/bash
# Generate 100w data
# python -c "for i in range(1,1+1000000): print(i)">100w.txt

check(){
    local name="$1"
    local v="$2"
	[[ -z $v ]] && { echo "${name}'s value is empty."; exit 1; }
}

check "Data limit " $1
check "MySql username " $2
check "MySql username " $3

host="$2"
pass="$3"
i=1;while [ $i -le $1 ];do echo $i ;let i+=1; done > $1.txt
datafile=`pwd`/$1.txt

exec() {
start=`date +%s`
mysql -u$host -p$pass <<EOF 
$1
EOF
end=`date +%s`

runtime=$((end-start))
echo Time cost: $runtime
echo 
echo 
}

echo init...
exec "
set global local_infile = 1;
show databases;
create database if not exists test;
use test;

CREATE TABLE if not exists t_user (
    id int(11) NOT NULL AUTO_INCREMENT,
    c_user_id varchar(36) NOT NULL DEFAULT '',
    c_name varchar(22) NOT NULL DEFAULT '',
    c_province_id int(11) NOT NULL,
    c_city_id int(11) NOT NULL,
    create_time datetime NOT NULL,
PRIMARY KEY (id),
KEY idx_user_id (c_user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

create table if not exists tmp_series(id int,primary key(id));
"

echo Test load $1 data...
exec "
use test;
load data LOCAL infile '${datafile}' replace into table tmp_series;
"

echo Test insert data...
exec "
use test;
INSERT INTO t_user
   SELECT
     id,
     uuid(),
     CONCAT('userNickName', id),
     FLOOR(Rand() * 1000),
     FLOOR(Rand() * 100),
     NOW()
   FROM
     tmp_series;
"

echo Test Update data with random time...
exec "
use test;
UPDATE t_user SET create_time=date_add(create_time, interval FLOOR(1 + (RAND() * 7)) year);
UPDATE t_user SET create_time=date_add(create_time, interval FLOOR(1 + (RAND() * 7)) year);
"

echo Test select data
exec "
use test;
select * from t_user limit 30;
"

echo Clear table and data...
exec "
use test;
drop table tmp_series;
drop table t_user;
"

echo Test Done.