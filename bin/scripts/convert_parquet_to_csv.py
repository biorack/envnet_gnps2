from pathlib import Path
import pandas as pd
import argparse
import os

def convert_parquet_to_csv(parquet_file):
    """Convert a Parquet file to CSV format."""
    cleaned_parquet_file = parquet_file[0].replace('[', '').replace(']', '')
    df = pd.read_parquet(cleaned_parquet_file)

    csv_file = Path(cleaned_parquet_file).with_suffix('.csv')
    new_csv_file = Path(csv_file.parent.name) / csv_file.name
    print(new_csv_file)

    os.makedirs(new_csv_file.parent, exist_ok=True)
    df.to_csv(new_csv_file, index=False)


def arg_parser(parser=None):
    if parser is None:
        parser = argparse.ArgumentParser()

    parser.add_argument('-f', '--parquet_in', nargs='+', required=True)

    return parser


def main(args):
    convert_parquet_to_csv(args.parquet_in)


if __name__ == '__main__':
    parser = arg_parser()
    args = parser.parse_args()

    main(args)
