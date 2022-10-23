

--zad 4

SELECT COUNT(*)
FROM popp, rivers
WHERE popp.f_codedesc LIKE 'Building'
AND ST_Distance(popp.geom, rivers.geom) < 1000

SELECT popp.gid, popp.geom INTO tableB
FROM popp, rivers
WHERE popp.f_codedesc LIKE 'Building'
AND ST_Distance(popp.geom, rivers.geom) < 1000

SELECT * FROM tableB

--zad 5

SELECT name, geom, elev INTO airportsNew
FROM airports
SELECT * FROM airportsNew
--a
SELECT name as wschod, ST_X(geom) from airportsNew
ORDER BY ST_X(geom)
LIMIT 1

SELECT name as zachod, ST_X(geom) from airportsNew
ORDER BY ST_X(geom) desc
LIMIT 1
--b
INSERT INTO airportsNew VALUES('airportB', 
							   (SELECT ST_Centroid(ST_Makeline (
			(SELECT geom FROM airportsNew WHERE name LIKE 'ANNETTE ISLAND'), 
			(SELECT geom FROM airportsNew WHERE name LIKE 'ATKA')))),
	42.000)
--zad 6
SELECT ST_Area(ST_Buffer(ST_MakeLine(ST_Centroid(l.geom), a.geom), 1000)) FROM lakes as l, airports as a
WHERE l.names LIKE 'Iliamna Lake'
AND a.name LIKE 'AMBLER'

--zad 7
SELECT SUM(trees.area_km2), trees.vegdesc FROM trees, swamp, tundra
WHERE ST_Within(trees.geom, swamp.geom)
OR ST_Within(trees.geom, tundra.geom)
GROUP BY trees.vegdesc

