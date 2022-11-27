--TWORZENIE RASTRÓW Z ISTNIEJĄYCH RASTRÓW I INTERAKCJA Z WEKTORAMI

--przykład 1 - ST_Intersects
CREATE TABLE schema_kruszona.intersects AS
SELECT a.rast, b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';

alter table schema_kruszona.intersects
add column rid SERIAL PRIMARY KEY;

CREATE INDEX idx_intersects_rast_gist ON schema_kruszona.intersects
USING gist (ST_ConvexHull(rast));

-- schema::name table_name::name raster_column::name
SELECT AddRasterConstraints('schema_kruszona'::name,
'intersects'::name,'rast'::name);



--przykład 2 ST_Clip
CREATE TABLE schema_kruszona.clip AS
SELECT ST_Clip(a.rast, b.geom, true), b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO';



--przykład 3 ST_Union
CREATE TABLE schema_kruszona.union AS
SELECT ST_Union(ST_Clip(a.rast, b.geom, true))
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast);





--TWORZENIE RASTRÓW Z WEKTORÓW (RASTROWANIE)

--przykład 1 - ST_AsRaster
CREATE TABLE schema_kruszona.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';



--Przykład 2 - ST_Union
DROP TABLE schema_kruszona.porto_parishes; --> drop table porto_parishes first
CREATE TABLE schema_kruszona.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';



--przykład 3 ST_Tile
DROP TABLE schema_kruszona.porto_parishes; --> drop table porto_parishes first
CREATE TABLE schema_kruszona.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1 )
SELECT st_tile(st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-
32767)),128,128,true,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';





--KONWERTOWANIE RASTRÓW NA WEKTORY(WEKTORYZACJA)

--Przykład 1 - ST_Intersection
--ST_Clip zwraca raster, a ST_Intersection zwraca zestaw par wartości geometria-piksel
create table schema_kruszona.intersection as
SELECT
a.rid,(ST_Intersection(b.geom,a.rast)).geom,(ST_Intersection(b.geom,a.rast)
).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);



--przykład 2 - ST_DumpAsAPolygons
--ST_DumpAsPolygons konwertuje rastry w wektory (poligony).
CREATE TABLE schema_kruszona.dumppolygons AS
SELECT
a.rid,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).geom,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);





--ANALIZA RASTRÓW

--Przykład 1 - ST_Band
--Funkcja ST_Band służy do wyodrębniania pasm z rastra
CREATE TABLE schema_kruszona.landsat_nir AS
SELECT rid, ST_Band(rast,4) AS rast
FROM rasters.landsat8;



--Przykład 2 - ST_Clip
CREATE TABLE schema_kruszona.paranhos_dem AS
SELECT a.rid,ST_Clip(a.rast, b.geom,true) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);



--Przykład 3 - ST_Slope
--ST_Slope wygeneruje nachylenie przy użyciu poprzednio wygenerowanej tabeli (wzniesienie)
CREATE TABLE schema_kruszona.paranhos_slope AS
SELECT a.rid,ST_Slope(a.rast,1,'32BF','PERCENTAGE') as rast
FROM schema_kruszona.paranhos_dem AS a;



--Przykład 4 - ST_Reclass
--zreklasyfikowanie rastra
CREATE TABLE schema_kruszona.paranhos_slope_reclass AS
SELECT a.rid,ST_Reclass(a.rast,1,']0-15]:1, (15-30]:2, (30-9999:3',
'32BF',0)
FROM schema_kruszona.paranhos_slope AS a;



--Przykład 5 - ST_SummaryStats
SELECT st_summarystats(a.rast) AS stats
FROM schema_kruszona.paranhos_dem AS a;



--Przykład 6 - ST_SummaryStats oraz Union
--Przy użyciu UNION można wygenerować jedną statystykę wybranego rastra.
SELECT st_summarystats(ST_Union(a.rast))
FROM schema_kruszona.paranhos_dem AS a;



--Przykład 7 - ST_SummaryStats z lepszą kontrolą złożonego typu danych
WITH t AS (
SELECT st_summarystats(ST_Union(a.rast)) AS stats
FROM schema_kruszona.paranhos_dem AS a)
SELECT (stats).min,(stats).max,(stats).mean FROM t;



---Przykład 8 - ST_SummaryStats w połączeniu z GROUP BY
WITH t AS (
SELECT b.parish AS parish, st_summarystats(ST_Union(ST_Clip(a.rast,
b.geom,true))) AS stats
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
group by b.parish)
SELECT parish,(stats).min,(stats).max,(stats).mean FROM t;



--Przykład 9 - ST_Value
--ST_Value pozwala wyodrębnić wartość piksela z punktu
--należy przekonwertować geometrię wielopunktową na geometrię jednopunktową za pomocą funkcji (ST_Dump(b.geom)).geom
SELECT b.name,st_value(a.rast,(ST_Dump(b.geom)).geom)
FROM
rasters.dem a, vectors.places AS b
WHERE ST_Intersects(a.rast,b.geom)
ORDER BY b.name;





--Topographic Position Index (TPI)
/*
TPI porównuje wysokość każdej komórki w DEM ze średnią wysokością określonego sąsiedztwa
wokół tej komórki. Wartości dodatnie reprezentują lokalizacje, które są wyższe niż średnia ich
otoczenia, zgodnie z definicją sąsiedztwa (grzbietów). Wartości ujemne reprezentują lokalizacje,
które są niższe niż ich otoczenie (doliny). Wartości TPI bliskie zeru to albo płaskie obszary (gdzie
nachylenie jest bliskie zeru), albo obszary o stałym nachyleniu.
*/

--Przykład 10 - ST_TPI
--Funkcja ST_Value pozwala na utworzenie mapy TPI z DEM wysokości.
--30 sekund:
CREATE TABLE schema_kruszona.tpi30 as
select ST_TPI(a.rast,1) as rast
from rasters.dem a;
--dodawanie indexu przestrzennego 
CREATE INDEX idx_tpi30_rast_gist ON schema_kruszona.tpi30
USING gist (ST_ConvexHull(rast));
--dodanie constraints
SELECT AddRasterConstraints('schema_kruszona'::name,
'tpi30'::name,'rast'::name);
--SKRACANIE CZASU:
DROP TABLE schema_kruszona.tpi30_short
--1,5 sekundy:
CREATE TABLE schema_kruszona.tpi30_short as
select ST_TPI(a.rast,1) as rast
from rasters.dem a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';





--ALGEBRA MAP
--NDVI=(NIR-Red)/(NIR+Red)

--Przykład 1 - Wyrażenie Algebry Map
CREATE TABLE schema_kruszona.porto_ndvi AS
WITH r AS (
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
r.rid,ST_MapAlgebra(
r.rast, 1,
r.rast, 4,
'([rast2.val] - [rast1.val]) / ([rast2.val] +
[rast1.val])::float','32BF'
) AS rast
FROM r;

CREATE INDEX idx_porto_ndvi_rast_gist ON schema_kruszona.porto_ndvi
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('schema_kruszona'::name,
'porto_ndvi'::name,'rast'::name);



--Przykład 2 – Funkcja zwrotna
create or replace function schema_kruszona.ndvi(
value double precision [] [] [],
pos integer [][],
VARIADIC userargs text []
)
RETURNS double precision AS
$$
BEGIN
--RAISE NOTICE 'Pixel Value: %', value [1][1][1];-->For debug purposes
RETURN (value [2][1][1] - value [1][1][1])/(value [2][1][1]+value
[1][1][1]); --> NDVI calculation!
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE COST 1000;

CREATE TABLE schema_kruszona.porto_ndvi2 AS
WITH r AS (
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
r.rid,ST_MapAlgebra(
	r.rast, ARRAY[1,4],
	'schema_kruszona.ndvi(double precision[],integer[],text[])'::regprocedure,
	'32BF'::text) AS rast
FROM r;

CREATE INDEX idx_porto_ndvi2_rast_gist ON schema_kruszona.porto_ndvi2
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('schema_kruszona'::name,
'porto_ndvi2'::name,'rast'::name);





--EKSPORT DANYCH

--Przykład 1 - ST_AsTiff
--ST_AsTiff tworzy dane wyjściowe jako binarną reprezentację pliku tiff
SELECT ST_AsTiff(ST_Union(rast))
FROM schema_kruszona.porto_ndvi;



--Przykład 2 - ST_AsGDALRaster
--ST_AsGDALRaster zapisuje dane wyjściowe jako reprezentacje binarną dowolnego formatu GDAL
SELECT ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE','PREDICTOR=2', 'PZLEVEL=9'])
FROM schema_kruszona.porto_ndvi;



--Przykład 3 - Zapisywanie danych na dysku za pomocą dużego obiektu (large object,lo)
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
) AS loid
FROM schema_kruszona.porto_ndvi;

SELECT * FROM public.table_privileges LIMIT 5;

--sprawdzic dostęp do folderow
SELECT lo_export(loid, 'C:\myraster.tiff')
FROM tmp_out;
----------------------------------------------
SELECT lo_unlink(loid)
FROM tmp_out; --> Delete the large object.






