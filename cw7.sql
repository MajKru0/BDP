CREATE INDEX idx ON cw7.uk_250k
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('cw7'::name,
'uk_250k'::name,'rast'::name);

/*
CREATE TABLE cw7.mozaika AS
SELECT ST_UNION(uk.rast)
FROM cw7.uk_250k AS uk
*/

SELECT ST_AsTiff(ST_Union(rast))
FROM cw7.uk_250k;

SELECT * FROM cw7.granicePN

CREATE TABLE cw7.uk_lake_district AS
SELECT a.rast
FROM cw7.uk_250 AS a, cw7.granicePN AS b
WHERE ST_Intersects(a.rast, b.rast);

CREATE TABLE cw7.dumppolygons AS
SELECT
rid,(ST_DumpAsPolygons(rast)).geom,(ST_DumpAsPolygons(rast)).val
FROM cw7.granicepn
select * from cw7.dumppolygons

DROP TABLE cw7.ndvi

CREATE TABLE cw7.ndvi AS
WITH r AS (
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM cw7.sentinel AS a, cw7.dumppolygons AS b
WHERE ST_Intersects(b.geom,a.rast)
)
SELECT
r.rid,ST_MapAlgebra(
r.rast, 1,
r.rast, 4,
'([rast2.val] - [rast1.val]) / ([rast2.val] +
[rast1.val])::float','32BF'
) AS rast
FROM r;

select * from cw7.ndvi


select Find_SRID('cw7', 'sentinel', 'rast')
select ST_SRID(geom) from cw7.dumppolygons
select ST_SRID(rast) from cw7.sentinel
UPDATE cw7.dumppolygons
SET geom = ST_Transform(geom,27700);

