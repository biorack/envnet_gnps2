#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Parameters
params.inputfiles1 = "/mnt/c/test_data/no_ms2/exctrl/"
params.inputfiles2 = "/mnt/c/test_data/no_ms2/sample/"

params.inputfiles1_name = "exctrl"
params.inputfiles2_name = "sample"

params.normalize_ints = 1
params.peak_value = 'peak_area'

// Analysis Parameters
params.mz_tolerance = 10
params.rt_min = 1
params.rt_max = 9
params.pk_height_min = 1e4
params.num_data_min = 5
params.frag_mz_tol = 0.05
params.msms_score_min = 0.5
params.msms_matches_min = 3

// FTICR Parameters
params.fticr = 0
params.formula_match = 0

// Cosmograph Parameters
params.max_log_change = 0.5

// Pathway and Set Cover Parameters
params.max_pval = 0.05

params.publishdir = "$baseDir"
TOOL_FOLDER = "$baseDir/bin/envnet/envnet/use"
SCRIPTS_FOLDER = "$baseDir/bin/scripts"


process collectNetworkHits {
    publishDir "$params.publishdir/nf_output/results", mode: 'copy'
    conda "$TOOL_FOLDER/environment_analysis.yml"

    input:
    path mzml_files1
    path mzml_files2

    output:
    path "all_ms1_data.csv", emit: all_ms1_data
    path "all_ms2_data.csv", emit: all_ms2_data
    path "output_group1-vs-group2.csv", emit: output_file
    path "AnnotatedENVnet.graphml", emit: graph_file

    """
    python $TOOL_FOLDER/analyze_metatlas_data_cli.py \
    --files_group1 $mzml_files1 \
    --files_group2 $mzml_files2 \
    --files_group1_name "$params.inputfiles1_name" \
    --files_group2_name "$params.inputfiles2_name" \
    --fticr $params.fticr \
    --formula_match $params.formula_match \
    --mz_tol $params.mz_tolerance \
    --rt_min $params.rt_min \
    --rt_max $params.rt_max \
    --pk_height_min $params.pk_height_min \
    --num_data_min $params.num_data_min \
    --frag_mz_tol $params.frag_mz_tol \
    --msms_score_min $params.msms_score_min \
    --msms_matches_min $params.msms_matches_min \
    --normalize_intensities $params.normalize_ints \
    --peak_value $params.peak_value \
    """
}


process formatCosmographOutput {
    publishDir "$params.publishdir/nf_output/results", mode: 'copy'
    conda "$TOOL_FOLDER/environment_analysis.yml"

    input:
    path graph_file
    path output_file

    output:
    path "cosmograph_edges.csv"
    path "cosmograph_metadata.csv"

    """
    python $SCRIPTS_FOLDER/make_cosmograph_output.py \
    --graph_file $graph_file \
    --output_file $output_file \
    --max_log_change $params.max_log_change \
    """

}


process generateCompoundClassOutputs {
    publishDir "$params.publishdir/nf_output/results", mode: 'copy'
    conda "$TOOL_FOLDER/environment_analysis.yml"

    input:
    path all_ms1_data
    path all_ms2_data
    path output_file

    output:
    path "set_cover_plots/*"
    path "compound_class_plots/*"

    """
    python $SCRIPTS_FOLDER/make_class_and_cover_output.py \
    --cover_plots_dir set_cover_plots \
    --compound_plots_dir compound_class_plots \
    --files_group1_name "$params.inputfiles1_name" \
    --files_group2_name "$params.inputfiles2_name" \
    --ms1_file_path $all_ms1_data \
    --ms2_file_path $all_ms2_data \
    --output_file_path $output_file \
    --max_p_val $params.max_pval \
    """

}


workflow {
    files1 = Channel.fromPath("${params.inputfiles1}/*").collect()
    
    def files2
    if (params.inputfiles2 && params.inputfiles2.trim()) {
        files2 = Channel.fromPath("${params.inputfiles2}/*").collect()
    } else {
        files2 = Channel.of(["${baseDir}/tests/integration/data/dummy.txt"])
    }

    collectNetworkHits(files1, files2)
    
    formatCosmographOutput(collectNetworkHits.out.graph_file,
                           collectNetworkHits.out.output_file)

    generateCompoundClassOutputs(collectNetworkHits.out.all_ms1_data, 
                                 collectNetworkHits.out.all_ms2_data, 
                                 collectNetworkHits.out.output_file)
}
