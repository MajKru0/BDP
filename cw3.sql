--zad1
SELECT b.polygon_id, b.geom FROM t2018_kar_buildings a, t2019_kar_buildings b
WHERE ST_Equals(a.geom,b.geom) = false

--zad 2
drop table t2019_kar_street_node

SELECT b.poi_id as polid, b.geom as geometry INTO zad1cw3
FROM t2018_kar_buildings a, t2019_kar_buildings b
WHERE ST_Equals(a.geom,b.geom) = false

SELECT * FROM zad1cw3

SELECT count(b.geom), b.type FROM t2018_kar_poi_table a, t2019_kar_poi_table b, zad1cw3 as c
WHERE ST_Equals(a.geom,b.geom) = false
AND ST_Within(b.geom, ST_Buffer((c.geometry)::geography, 500)::geometry) = true
GROUP BY b.type

---zad3
SELECT ST_Transform(geom, 3068) INTO streets_reprojected FROM t2019_kar_streets
SELECT * FROM streets_reprojected

--zad 4
CREATE TABLE input_points (id INT, geom GEOMETRY);
INSERT INTO input_points VALUES(1, ST_GeomFromtext('POINT(8.36093 49.03174)', 4326));
INSERT INTO input_points VALUES(2, ST_GeomFromtext('POINT(8.39876 49.00644)', 4326));

SELECT * FROM input_points
--zad5
UPDATE input_points
SET geom = ST_AsText(ST_Transform(geom, 3068))

--zad6
SELECT count(*) FROM t2019_kar_street_node as node
WHERE ST_Within(node.geom, ST_Buffer(ST_MakeLine
				 ((ST_GeomFromtext('POINT(8.36093 49.03174)', 4326)),
				  (ST_GeomFromtext('POINT(8.39876 49.00644)', 4326)))::geography,
				 200)::geometry) = true
				 
--zad7
SELECT count(*) FROM t2019_kar_poi_table as poi, t2019_kar_land_use_a as a
WHERE poi.type = 'Sporting Goods Store'
AND ST_Within(poi.geom, ST_Buffer(a.geom::geography, 300)::geometry)

--zad 8
SELECT ST_Intersection(r.geom, w.geom) 
INTO T2019_KAR_BRIDGES 
FROM t2019_kar_railways r, t2019_kar_water_lines w

SELECT * FROM T2019_KAR_BRIDGES 