import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import networkx as nx
import argparse

metadata_cols = ['id',
 'c',
 'h',
 'o',
 's',
 'n',
 'p',
 'n_to_c',
 'h_to_c',
 'p_to_c',
 'n_to_p',
 'o_to_c',
 'experiment_id',
 'mz_centroid_ms1',
 'formula',
 'rt',
 'precursor_mz',
 'num_datapoints_ms1',
 'mass_error',
 'rt_peak_ms1',
 'predicted_mass',
 'peak_height_ms1',
 'name_ref_original_identity',
 'max_score_identity',
 'precursor_mz_mdm_identity',
 'inchi_key_ref_mdm_identity',
 'predicted_formula_original_identity',
 'precursor_mz_identity',
 'name_ref_mdm_identity',
 'original_p2d2_index_ref_identity',
 'precursor_mz_ref_mdm_identity',
 'predicted_formula_mdm_identity',
 'formula_identity',
 'smiles_identity',
 'precursor_mz_original_identity',
 'query_identity',
 'name_identity',
 'best_match_method_identity',
 'coisolated_precursor_count_query_identity',
 'ref_mdm_identity',
 'formula_ref_mdm_identity',
 'original_p2d2_index_identity',
 'max_matches_identity',
 'ref_original_identity',
 'formula_ref_original_identity',
 'original_index_query_identity',
 'precursor_mz_query_identity',
 'inchi_key_identity',
 'inchi_key_ref_original_identity',
 'precursor_mz_ref_original_identity',
 'class_results',
 'superclass_results',
 'pathway_results',
 'class_results_propagated',
 'superclass_results_propagated',
 'pathway_results_propagated',
 'dataset_massive',
 'num_datapoints',
 'peak_area',
 'peak_height',
 'mz_centroid',
 'rt_peak',
 'lcmsrun_observed',
 'precursor_mz_best_hit',
 'ppm_error',
 'ms2_node_id',
 'ms2_score',
 'ms2_matches',
 'ms2_best_match_method',
 'ms2_lcmsrun_observed',
 'p_value',
 't_score',
 'log2_foldchange',
 'log2_foldchange_color',
 'pathway_propagated_colors']

stats_prefixes = ['mean', 'median', 'standard_error', 'std_dev']


def generate_cosmograph_data(graph_file_path, output_file_path, min_log2=-4, max_log=4, log_cmap='coolwarm', pathway_cmap='hsv'):
    G = nx.read_graphml(graph_file_path)
    metadata = pd.read_csv(output_file_path)
    metadata['log2_foldchange'].fillna(0, inplace=True)
    metadata.rename(columns={'node_id': 'id'}, inplace=True)

    edge_data = [(u, v, d) for u, v, d in G.edges(data=True)]
    edges_df = pd.DataFrame(edge_data, columns=['source', 'target', 'attributes'])

    edges_df['rem_blink_score'] = edges_df.attributes.apply(lambda x: x['rem_blink_score'])
    edges_df.drop(columns=['attributes'], inplace=True)

    log2_fold_change = metadata['log2_foldchange']
    log2_fold_change_clipped = log2_fold_change.clip(min_log2, max_log)
    norm = (log2_fold_change_clipped - min_log2) / (max_log - min_log2)

    cmap = plt.get_cmap(log_cmap)
    metadata['log2_foldchange_color'] = norm.apply(lambda x: plt.cm.colors.to_hex(cmap(x)))

    categories = metadata['pathway_results_propagated'].unique()
    palette = iter(plt.cm.rainbow(np.linspace(0, 1, len(categories))))
    color_map = {category: plt.cm.colors.to_hex(color) for category, color in zip(categories, palette)}

    metadata['pathway_propagated_colors'] = metadata['pathway_results_propagated'].map(color_map)

    stats_cols = [col for col in metadata.columns if col.split('-')[0] in stats_prefixes]

    edges_df.to_csv('cosmograph_edges.csv')
    metadata[metadata_cols + stats_cols].to_csv('cosmograph_metadata.csv')


def arg_parser(parser=None):
    if parser is None:
        parser = argparse.ArgumentParser()

    parser.add_argument('-gf', '--graph_file', type=str, action='store', required=True)
    parser.add_argument('-of', '--output_file', type=str, action='store', required=True)
    parser.add_argument('-ml', '--max_log_change', type=int, action='store', required=False, default=2)

    return parser


def main(args):
    generate_cosmograph_data(args.graph_file, args.output_file)


if __name__ == '__main__':
    parser = arg_parser()
    args = parser.parse_args()

    main(args)