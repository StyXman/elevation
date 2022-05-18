CREATE TABLE "contours" (gid serial, "id" int4, "height" numeric);
ALTER TABLE "contours" ADD PRIMARY KEY (gid);
SELECT AddGeometryColumn('','contours','way','0','MULTILINESTRING',2);
