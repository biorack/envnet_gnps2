import pandas as pd
import argparse

ms2_cols = ['score_deconvoluted_match', 'matches_deconvoluted_match',
            'ref_deconvoluted_match', 'precursor_mz_query_deconvoluted_match',
            'precursor_mz_ref_deconvoluted_match',
            'original_index_deconvoluted_match', 'mz_diff_deconvoluted_match',
            'mz_diff_ppm_deconvoluted_match', 'ms2_data_index_deconvoluted_match', 'rt', 'count', 'precursor_mz',
            'isolated_precursor_mz', 'filename', 'basename',
            'nearest_precursor', 'mz_diff', 'mz_diff_ppm', 'annotation_method',
            'spectrum_type', 'confidence_level']


node_cols = ['original_index', 'precursor_mz', 'obs',
            'isolated_precursor_mz', 'basename', 'assumed_adduct', 'predicted_formula', 'estimated_fdr', 
            'rt_peak', 'score', 'matches',
            'library_formula', 'library_precursor_mz', 'inchi_key', 'compound_name',
            'smiles', 'dbe', 'dbe_ai', 'dbe_ai_mod', 'ai_mod', 'ai', 'nosc', 'h_to_c',
            'o_to_c', 'n_to_c', 'p_to_c', 'n_to_p', 'c', 'h', 'o', 'n', 's', 'p',
            'has_library_match', 'is_singleton', 'NPC#pathway',
            'NPC#pathway Probability', 'NPC#superclass',
            'NPC#superclass Probability', 'NPC#class', 'NPC#class Probability']

def merge_data(input_node_data, input_stats, input_ms2, output_csv):

    node_data = pd.read_csv(input_node_data, usecols=node_cols)
    stats_data = pd.read_csv(input_stats)
    ms2_data = pd.read_parquet(input_ms2, columns=ms2_cols)

    top_hits = ms2_data.sort_values('score_deconvoluted_match', ascending=False).groupby('original_index_deconvoluted_match').head(1)
    merged_output_table = node_data[node_cols].copy().add_prefix('node_').rename(columns={'node_original_index': 'original_index'})

    merged_output_table = pd.merge(merged_output_table, stats_data, on='original_index', how='left')
    merged_output_table = pd.merge(merged_output_table, top_hits.add_prefix('ms2_').rename(columns={'ms2_original_index_deconvoluted_match': 'original_index'}), on="original_index", how="left")

    merged_output_table[pd.notna(merged_output_table['log2_foldchange'])].to_csv(output_csv, index=False)

def arg_parser(parser=None):
    if parser is None:
        parser = argparse.ArgumentParser()

    parser.add_argument('-ind', '--input_node_data', required=True)
    parser.add_argument('-is', '--input_stats', required=True)
    parser.add_argument('-im2', '--input_ms2', required=True)
    parser.add_argument('-o', '--output_csv', required=True)

    return parser


def main(args):
    merge_data(args.input_node_data, args.input_stats, args.input_ms2, args.output_csv)


if __name__ == '__main__':
    parser = arg_parser()
    args = parser.parse_args()

    main(args)