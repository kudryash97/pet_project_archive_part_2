SELECT * FROM system.clusters;

CREATE DATABASE company_db ON CLUSTER 'rzvde_cluster';

CREATE TABLE company_db.events ON CLUSTER 'rzvde_cluster' (
    time DateTime,
    uid  Int64,
    type LowCardinality(String)
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{cluster}/{shard}/events', '{replica}')
PARTITION BY toDate(time)
ORDER BY (uid);

CREATE TABLE company_db.events_distr ON CLUSTER 'rzvde_cluster' AS company_db.events
ENGINE = Distributed('rzvde_cluster', company_db, events, uid);

INSERT INTO company_db.events_distr VALUES
    ('2020-01-01 10:00:00', 100, 'view'),
    ('2020-01-01 10:05:00', 101, 'view'),
    ('2020-01-01 11:00:00', 100, 'contact'),
    ('2020-01-01 12:10:00', 101, 'view'),
    ('2020-01-02 08:10:00', 100, 'view'),
    ('2020-01-03 13:00:00', 103, 'view');

SELECT * FROM company_db.events;
select * from remote('clickhouse02:9000', company_db.events);
select * from remote('clickhouse03:9000', company_db.events);
select * from remote('clickhouse04:9000', company_db.events);

SELECT * FROM company_db.events_distr;