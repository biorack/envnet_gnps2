from matplotlib.backends.backend_pdf import PdfPages
import pandas as pd
import argparse
import sys
import os

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../envnet/envnet/use')))
from analysis_tools import make_set_coverage_results, make_compound_class_analysis

def generate_set_cover_figs(ms1_data_path, ms2_data_path, plot_output_dir='.'):
    ms1_data = pd.read_csv(ms1_data_path)
    ms2_data = pd.read_csv(ms2_data_path)

    with PdfPages(os.path.join(plot_output_dir, 'set_cover_results.pdf')) as pdf:
        make_set_coverage_results(ms1_data, 'ms1', plot_output_dir=plot_output_dir, pdf=pdf)
        make_set_coverage_results(ms2_data, 'ms2', plot_output_dir=plot_output_dir, pdf=pdf)


def generate_compound_class_figs(output_file_path, files_group1_name, files_group2_name, max_pval, plot_output_dir='.'):
    output_data = pd.read_csv(output_file_path)

    with PdfPages(os.path.join(plot_output_dir, 'class_results.pdf')) as pdf:
        for c in ['class_results', 'superclass_results', 'pathway_results']:
            for p in ['_propagated', '']:
                make_compound_class_analysis(output_data, files_group1_name, files_group2_name, 
                                            class_column=c+p, max_pvalue=max_pval, plot_output_dir=plot_output_dir, pdf=pdf)


def arg_parser(parser=None):
    if parser is None:
        parser = argparse.ArgumentParser()

    parser.add_argument('-scd', '--cover_plots_dir', type=str, action='store', required=True)
    parser.add_argument('-cd', '--compound_plots_dir', type=str, action='store', required=True)
    parser.add_argument('-1fn', '--files_group1_name', type=str, action='store', required=True)
    parser.add_argument('-2fn', '--files_group2_name', type=str, action='store', required=True)
    parser.add_argument('-ms1', '--ms1_file_path', type=str, action='store', required=True)
    parser.add_argument('-ms2', '--ms2_file_path', type=str, action='store', required=True)
    parser.add_argument('-of', '--output_file_path', type=str, action='store', required=True)
    parser.add_argument('-mp', '--max_p_val', type=float, action='store', default=0.05, required=False)

    return parser


def main(args):
    if not os.path.exists(args.cover_plots_dir):
        os.makedirs(args.cover_plots_dir)
    if not os.path.exists(args.compound_plots_dir):
        os.makedirs(args.compound_plots_dir)

    generate_set_cover_figs(args.ms1_file_path, args.ms2_file_path, plot_output_dir=args.cover_plots_dir)
    generate_compound_class_figs(args.output_file_path, args.files_group1_name, args.files_group2_name, 
                                 args.max_p_val, plot_output_dir=args.compound_plots_dir)


if __name__ == '__main__':
    parser = arg_parser()
    args = parser.parse_args()

    main(args)