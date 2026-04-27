import pandas as pd
import glob
import os

DATA_DIR = "week-11/data"
OUTPUT_FILE = "baby_names.parquet"

def load_all_files(data_dir):
    all_files = glob.glob(os.path.join(data_dir, "yob*.txt"))
    
    dfs = []

    for file in all_files:
        # Extract year from filename (yobYYYY.txt)
        year = int(os.path.basename(file)[3:7])

        df = pd.read_csv(
            file,
            names=["name", "sex", "count"],
            dtype={
                "name": "string",
                "sex": "category",
                "count": "int32"
            }
        )

        df["year"] = year

        dfs.append(df)

    return pd.concat(dfs, ignore_index=True)


def add_rank(df):
    # Rank within (year, sex) based on count descending
    df["rank"] = (
        df.sort_values(["year", "sex", "count"], ascending=[True, True, False])
          .groupby(["year", "sex"])
          .cumcount() + 1
    )
    return df


def main():
    df = load_all_files(DATA_DIR)

    # Optional but useful
    df = add_rank(df)

    # Reorder columns
    df = df[["year", "sex", "name", "count", "rank"]]

    # Save to Parquet (fast + compressed)
    df.to_parquet(
        OUTPUT_FILE,
        engine="pyarrow",
        compression="snappy",
        index=False
    )

    print(f"Saved {len(df):,} rows to {OUTPUT_FILE}")


if __name__ == "__main__":
    main()