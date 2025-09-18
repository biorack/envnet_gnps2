from pathlib import Path
import pandas as pd
import argparse

def create_metadata_file(files1, files2, sample_cat1, sample_cat2):
    """Generates and saves a metadata file from nextflow parameters"""
    metadata_cols = ['original_file_type', 'sample_category', 'lcmsrun_observed', 'parquet', 'h5', 'mzml']
    df1 = pd.DataFrame(columns=metadata_cols)
    df2 = pd.DataFrame(columns=metadata_cols)

    # clean up file paths from nextflow
    clean_files1 = [file.replace('[', '').replace(']', '').replace(',', '') for file in files1]
    clean_files2 = [file.replace('[', '').replace(']', '').replace(',', '') for file in files2]
    df1['mzml'] = clean_files1
    df2['mzml'] = clean_files2
    
    df1['sample_category'] = sample_cat1
    df2['sample_category'] = sample_cat2

    metadata_df = pd.concat([df1, df2]).reset_index(drop=True)
    metadata_df['original_file_type'] = 'mzml'
    metadata_df['lcmsrun_observed'] = metadata_df['mzml'].apply(lambda x: Path(x).with_suffix(''))

    metadata_df['parquet'] = metadata_df['mzml'].apply(lambda f: Path(f).with_suffix(".parquet"))
    metadata_df['h5'] = metadata_df['mzml'].apply(lambda f: Path(f).with_suffix(".h5"))

    metadata_file = 'file_metadata.csv'
    metadata_df.to_csv(metadata_file)

def arg_parser(parser=None):
    if parser is None:
        parser = argparse.ArgumentParser()

    parser.add_argument('-f1', '--files1', nargs='+', required=True)
    parser.add_argument('-f2', '--files2', nargs='+', required=True)
    parser.add_argument('-sc1', '--sample_category1', type=str, action='store', required=True)
    parser.add_argument('-sc2', '--sample_category2', type=str, action='store', required=True)

    return parser


def main(args):
    create_metadata_file(args.files1, args.files2, args.sample_category1, args.sample_category2)


if __name__ == '__main__':
    parser = arg_parser()
    args = parser.parse_args()

    main(args)
