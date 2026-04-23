# Data

## Parquet File Overview Logs

```sh
=========================================================================== DATA OVERVIEW ===========================================================================
Loaded Data (11.197 MB): week-11/data/canonical/baby_names.parquet
Shape (Rows x Columns): (2149477 x 5)
Date Range (145 Years): 1880 to 2024
Duplicates: 0

-----------------------------------------------------------------------------------------------------------------------------
COLUMN         TYPE                                                        MISSING        EMPTY          UNIQUE
-----------------------------------------------------------------------------------------------------------------------------
year           int64                                                       0              0              145
sex            dictionary<values=string, indices=int8, ordered=0>          0              0              2
name           large_string                                                0              0              104819
count          int32                                                       0              0              13942
rank           int64                                                       0              0              20582


----------------------------------- NUMERIC SUMMARY -----------------------------------
           count         mean          std     min     25%     50%     75%      max
year   2149477.0  1979.664982    35.159228  1880.0  1956.0  1990.0  2008.0   2024.0
count  2149477.0   173.069612  1463.576138     5.0     7.0    12.0    32.0  99693.0
rank   2149477.0  5687.880194  4602.859884     1.0  1962.0  4368.0  8621.0  20582.0


----------------------------------- COVERAGE CONSISTENCY -----------------------------------
   count         mean          std    min     25%     50%       75%      max
0  290.0  7411.989655  5428.963892  938.0  3976.5  5405.0  11438.75  20582.0


----------------------------------- SANITY CHECKS -----------------------------------
Negative Counts: 0
Rank <= 0: 0
Years Out of Range: 0
Rank Consistency (expect 0): 0
Rank vs Count Alignment (expect 0): 0


----------------------------------- EXTRA DETAILS -----------------------------------
Top 10 names share of total:       0.1062
Most popular name overall:         James
Peak birth year:                   1957
Unisex name ratio:                 0.1119
Top-1 name dominance:              0.0141
```