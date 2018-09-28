-- 3-3-cqlsh.sql

-- BASH
kubectl exec -it cassandra-0 -- nodetool status

Datacenter: DC1
===============
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address       Load       Tokens       Owns (effective)  Host ID                               Rack
UN  192.168.2.15  170.85 KiB  256          100.0%            311cd32a-2c8d-4a5c-bb6c-c81bfb90810b  Rack1


-- CQL

-- create keyspace
CREATE KEYSPACE "ks_one" WITH REPLICATION = {
    'class': 'NetworkTopologyStrategy',
    'DC1': 3  -- use datacenter name from nodetool status and integer for replication factor
};

-- create table
CREATE TABLE ks_one.t_one (
    c_int int,
    c_text text,
    PRIMARY KEY (c_int)
);

-- insert values
insert into
    ks_one.t_one (c_int, c_text)
    values (1, 'one')
;

insert into
    ks_one.t_one (c_int, c_text)
    values (2, 'two')
;

insert into
    ks_one.t_one (c_int, c_text)
    values (3, 'three')
;

select * from ks_one.t_one;

#