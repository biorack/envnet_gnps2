import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import networkx as nx
import argparse

metadata_cols = ['id',
 'envnet_formula',
 'envnet_experiment_id',
 'envnet_precursor_mz',
 'envnet_color_compound_class',
 'envnet_class_results_propagated',
 'envnet_superclass_results_propagated',
 'envnet_pathway_results_propagated',
 'envnet_color_compound_class_propagated',
 'envnet_name_ref_mdm_identity',
 'envnet_name_identity',
 'envnet_smiles_identity',
 'envnet_pathway_results',
 'envnet_class_results',
 'envnet_superclass_results',
 'num_datapoints',
 'peak_area',
 'peak_height',
 'mz_centroid',
 'rt_peak',
 'lcmsrun_observed',
 'precursor_mz',
 'ppm_error',
 'ms2_score',
 'ms2_matches',
 'ms2_best_match_method',
 'ms2_lcmsrun_observed',
 'peak_values_normalized',
 'peak_value_used',
 'p_value',
 't_score',
 'log2_foldchange',
 'log2_foldchange_color']

stats_prefixes = ['mean', 'median', 'standard_error', 'std_dev']


def generate_cosmograph_data(graph_file_path, output_file_path, min_log2=-4, max_log=4, log_cmap='coolwarm', pathway_cmap='hsv'):
    G = nx.read_graphml(graph_file_path)
    metadata = pd.read_csv(output_file_path)
    metadata['log2_foldchange'].fillna(0, inplace=True)
    metadata.rename(columns={'envnet_node_id': 'id'}, inplace=True)

    edge_data = [(u, v, d) for u, v, d in G.edges(data=True)]
    edges_df = pd.DataFrame(edge_data, columns=['source', 'target', 'attributes'])

    edges_df['rem_blink_score'] = edges_df.attributes.apply(lambda x: x['rem_blink_score'])
    edges_df.drop(columns=['attributes'], inplace=True)

    log2_fold_change = metadata['log2_foldchange']
    log2_fold_change_clipped = log2_fold_change.clip(min_log2, max_log)
    norm = (log2_fold_change_clipped - min_log2) / (max_log - min_log2)

    cmap = plt.get_cmap(log_cmap)
    metadata['log2_foldchange_color'] = norm.apply(lambda x: plt.cm.colors.to_hex(cmap(x)))

    categories = metadata['envnet_pathway_results_propagated'].unique()
    palette = iter(plt.cm.rainbow(np.linspace(0, 1, len(categories))))
    color_map = {category: plt.cm.colors.to_hex(color) for category, color in zip(categories, palette)}

    metadata['envnet_pathway_propagated_colors'] = metadata['envnet_pathway_results_propagated'].map(color_map)

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