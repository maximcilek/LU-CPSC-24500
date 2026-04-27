import pandas as pd
import pathlib
import pyarrow.parquet as pq
import json

def load_parquet(fp):
    chunks = []
    for batch in parquet_file.iter_batches(batch_size=10000):
        chunk = batch.to_pandas()
        chunks.append(chunk)
    return pd.concat(chunks, ignore_index=True)

if __name__ == "__main__":

    # =========================
    # LOAD DATA
    # =========================
    DATA_DIR = pathlib.Path(__file__).resolve().parent.parent / "data"
    FILE_PATH = DATA_DIR / "canonical/baby_names.parquet"
    parquet_file = pq.ParquetFile(FILE_PATH)
    df = load_parquet(parquet_file)

    parquet_file_info = parquet_file.metadata.to_dict()
    total_byte_size = sum(int(rg.get("total_byte_size", 0)) for rg in parquet_file_info.get("row_groups", []))
    missing = df.isna().sum()
    empty = df.apply(lambda col: (col == "").sum() if col.dtype == "object" or str(col.dtype).startswith("string") else 0)
    unique = df.nunique()

    print(f"{'='*75} DATA OVERVIEW {'='*75}")
    print(f"Loaded Data ({next(f'{total_byte_size / (1024 ** i):.3f} {u}' for i, u in enumerate(['B','KB','MB','GB','TB']) if total_byte_size < 1024 ** (i + 1))}): {FILE_PATH.absolute().relative_to(pathlib.Path.cwd())}")
    print(f"Shape (Rows x Columns): ({parquet_file_info.get('num_rows', None)} x {parquet_file_info.get('num_columns', None)})")
    print(f"Date Range ({df['year'].nunique()} Years): {df['year'].min()} to {df['year'].max()}")
    print(f"Duplicates: {df.duplicated().sum()}")
    print(f"\n{'-' * 125}\n{'COLUMN':<15}{'TYPE':<60}{'MISSING':<15}{'EMPTY':<15}{'UNIQUE'}\n{'-' * 125}")
    [print(f"{f.name:<15}{str(f.type):<60}{missing.get(f.name, 0):<15}{empty.get(f.name, 0):<15}{unique.get(f.name, 0)}") for f in parquet_file.schema_arrow]


    print(f"\n\n{'-'*35} NUMERIC SUMMARY {'-'*35}")
    print(df.describe().T)

    print(f"\n\n{'-'*35} COVERAGE CONSISTENCY {'-'*35}")
    print(df.groupby(['year','sex']).size().describe().to_frame().T)

    print(f"\n\n{'-'*35} SANITY CHECKS {'-'*35}")
    print(f"Negative Counts: {(df['count'] < 0).sum()}")
    print(f"Rank <= 0: {(df['rank'] <= 0).sum()}")
    print(f"Years Out of Range: {(df['year'] < df['year'].min()).sum() + (df['year'] > df['year'].max()).sum()}")
    print(f"Rank Consistency (expect 0): {(df.groupby(['year', 'sex'])['rank'].nunique() != df.groupby(['year', 'sex']).size()).sum()}")
    print(f"Rank vs Count Alignment (expect 0): {(df.sort_values(['year','sex','rank']).groupby(['year','sex'])['count'].diff().gt(0).sum())}")

    print(f"\n\n{'-'*35} EXTRA DETAILS {'-'*35}")
    print(f"{'Top 10 names share of total:':<35}{df.groupby('name')['count'].sum().sort_values(ascending=False).head(10).sum() / df['count'].sum():.4f}")
    print(f"{'Most popular name overall:':<35}{df.groupby('name')['count'].sum().idxmax()}")
    print(f"{'Peak birth year:':<35}{df.groupby('year')['count'].sum().idxmax()}")
    print(f"{'Unisex name ratio:':<35}{(df.groupby('name')['sex'].nunique() > 1).mean():.4f}")
    print(f"{'Top-1 name dominance:':<35}{df.groupby('name')['count'].sum().max() / df['count'].sum():.4f}")

    print(df["count"].max())