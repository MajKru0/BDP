CREATE TABLE obiekty (id INTEGER, nazwa VARCHAR(50), geom GEOMETRY);


INSERT INTO obiekty VALUES (1, 'obiekt1',
							ST_GeomFromText(
								'COMPOUNDCURVE( (0 1, 1 1), CIRCULARSTRING(1 1, 2 0, 3 1), CIRCULARSTRING(3 1, 4 2, 5 1), (5 1, 6 1))'));
INSERT INTO obiekty VALUES(2, 'obiekt2', ST_GeomFromText(
	'CURVEPOLYGON(COMPOUNDCURVE( (10 2, 10 6, 14 6),
	CIRCULARSTRING(14 6, 16 4, 14 2), CIRCULARSTRING(14 2, 12 0, 10 2)), CIRCULARSTRING(11 2, 13 2, 11 2))'));
INSERT INTO obiekty VALUES(3, 'obiekt3', ST_GeomFromText('POLYGON((10 17,12 13,7 15,10 17))'));
INSERT INTO obiekty VALUES(4, 'obiekt4', ST_GeomFromText('LINESTRING(20 20,25 25,27 24,25 22,26 21,22 19,20.5 19.5)'));
INSERT INTO obiekty VALUES(5, 'obiekt5',  ST_GeomFromText('MULTIPOINT( (30 30 59), (38 32 234) )'));
INSERT INTO obiekty VALUES(6, 'obiekt6', ST_GeomFromText('GEOMETRYCOLLECTION(LINESTRING(1 1, 3 2), POINT(4 2))'));

SELECT * FROM obiekty
drop table obiekty

SELECT ST_AREA(ST_BUFFER(ST_SHORTESTLINE((SELECT geom FROM obiekty WHERE id=3),(SELECT geom FROM obiekty WHERE id=4)),5));

INSERT INTO obiekty VALUES(7,'pol_obiekt4',ST_MakePolygon(ST_AddPoint((SELECT geom FROM obiekty WHERE id=4),ST_StartPoint((SELECT geom FROM obiekty WHERE id=4)))));
--

INSERT INTO obiekty VALUES (8,'obiekt7',ST_COLLECT((SELECT geom FROM obiekty WHERE id=3),(SELECT geom FROM obiekty WHERE id=4)));

SELECT SUM(ST_Area(ST_Buffer(geom,5))) FROM obiekty
WHERE ST_HasArc(geom) = FALSE;
