CREATE EXTENSION postgis;
CREATE TABLE budynki (id INTEGER, geometria GEOMETRY, nazwa VARCHAR(50), wysokosc INTEGER);
CREATE TABLE drogi (id INTEGER, geometria GEOMETRY, nazwa VARCHAR(50));
CREATE TABLE pktinfo (id INTEGER, geometria GEOMETRY, nazwa VARCHAR(50), liczprac INTEGER);
DROP TABLE new

INSERT INTO budynki VALUES(1, ST_GeomFromtext('POLYGON((3 8, 5 8, 5 6, 3 6, 3 8))', 0), 'BuildingC', 40);
INSERT INTO budynki VALUES(2, ST_GeomFromtext('POLYGON((4 7, 6 7, 6 5, 4 5, 4 7))', 0), 'BuildingB', 50);
INSERT INTO budynki VALUES(3, ST_GeomFromtext('POLYGON((9 9, 10 9, 10 8, 9 8, 9 9))', 0), 'BuildingD', 22);
INSERT INTO budynki VALUES(4, ST_GeomFromtext('POLYGON((8 4, 10.5 4, 10.5 1.5, 8 1.5, 8 4))', 0), 'BuildingA', 15);
INSERT INTO budynki VALUES(5, ST_GeomFromtext('POLYGON((1 2, 2 2, 2 1, 1 1, 1 2))', 0), 'BuildingF', 40);

SELECT *, ST_AsText(geometria) as WKT from budynki;

INSERT INTO drogi VALUES(1, ST_GeomFromtext('LINESTRING(0 4.5, 12 4.5)', 0), 'roadX');
INSERT INTO drogi VALUES(2, ST_GeomFromtext('LINESTRING(7.5 10.5, 7.5 0)', 0), 'roadY');

SELECT *, ST_AsText(geometria) as WKT from drogi;

INSERT INTO pktinfo VALUES(1, ST_GeomFromtext('POINT(6 9.5)', 0), 'K', 10);
INSERT INTO pktinfo VALUES(2, ST_GeomFromtext('POINT(6.5 6)', 0), 'J', 15);
INSERT INTO pktinfo VALUES(3, ST_GeomFromtext('POINT(9.5 6)', 0), 'K', 15);
INSERT INTO pktinfo VALUES(4, ST_GeomFromtext('POINT(1 3.5)', 0), 'G', 4);
INSERT INTO pktinfo VALUES(5, ST_GeomFromtext('POINT(5.5 1.5)', 0), 'H', 8);

SELECT *, ST_AsText(geometria) as WKT from pktinfo;
--zad1
SELECT SUM(ST_Length(geometria)) from drogi;
--zad2

SELECT nazwa, ST_AsText(geometria) as WKT, ST_Area(geometria) as pole, ST_Perimeter(geometria) as obwod from budynki
WHERE nazwa LIKE 'BuildingA';
--zad3
SELECT nazwa, ST_Area(geometria) as pole from budynki
ORDER BY nazwa;
--zad4
SELECT nazwa, ST_Perimeter(geometria) as obwod
from budynki
ORDER BY ST_Area(geometria) DESC
LIMIT 2;
--zad5
SELECT ST_Distance(budynki.geometria, pktinfo.geometria) AS najkrotszaOdleglosc
FROM budynki, pktinfo
WHERE budynki.nazwa = 'BuildingC' AND pktinfo.nazwa = 'G'
ORDER BY najkrotszaOdleglosc
LIMIT 1;
--zad6 ??

SELECT ST_Area(ST_Difference(C.geometria, ST_Buffer(B.geometria, 0.5))) as area
from budynki as C, budynki as B
WHERE C.id = B.id-1
LIMIT 1

--zad7
SELECT b.nazwa as budynek from budynki as b, drogi as d
where d.id = 1
AND
ST_Y(ST_Centroid(b.geometria)) > ST_Y(ST_EndPoint(d.geometria));

--zad 8

SELECT (ST_Area(ST_Difference(geometria, 'POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))'::GEOMETRY)))+(ST_Area(ST_Difference('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))'::GEOMETRY, geometria))) as pole
FROM budynki
WHERE budynki.id = 1