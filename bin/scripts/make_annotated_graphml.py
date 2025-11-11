import networkx as nx
import pandas as pd
import os
from pathlib import Path
import argparse

def _clean_input_file(input_file):
    return input_file[0].replace('[', '').replace(']', '')

def annotate_graphml(input_graphml_file, stats_output_file):
    
    G = nx.read_graphml(input_graphml_file)
    stats_df = pd.read_csv(_clean_input_file(stats_output_file), index_col=0, dtype={'original_index': str})

    envnet_all_nodes = pd.DataFrame(G.nodes(), columns=['original_index'])
    stats_df_merged = pd.merge(envnet_all_nodes, stats_df, on='original_index', how='left').set_index('original_index')

    for stats_col in stats_df_merged.columns:
        attr_dict = stats_df_merged[stats_col].to_dict()
        nx.set_node_attributes(G, attr_dict, name=stats_col)

    output_graphml_file = Path(input_graphml_file.replace(".graphml", "_annotated.graphml")).name
    nx.write_graphml(G, output_graphml_file)

def arg_parser(parser=None):
    if parser is None:
        parser = argparse.ArgumentParser()

    parser.add_argument('-fg', '--input_graphml', required=True)
    parser.add_argument('-fs', '--input_stats', nargs='+', required=True)

    return parser


def main(args):
    annotate_graphml(args.input_graphml, args.input_stats)


if __name__ == '__main__':
    parser = arg_parser()
    args = parser.parse_args()

    main(args)
