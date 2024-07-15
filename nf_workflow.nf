#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Parameters
params.inputfiles1 = "/home/tharwood/repos/test_data/files1/"
params.inputfiles2 = "/home/tharwood/repos/test_data/files2/"

params.inputfiles1_name = "supern-WAVE-NatCom-NLDM-Day0"
params.inputfiles2_name = "supern-WAVE-NatCom-NLDM-Day7"

params.publishdir = "$baseDir"
TOOL_FOLDER = "$baseDir/bin/envnet/envnet/use"
SCRIPTS_FOLDER = "$baseDir/bin/scripts"

process analyzeDataWithNetwork {
    publishDir "$params.publishdir/nf_output/results", mode: 'copy'
    conda "$TOOL_FOLDER/environment_analysis.yml"

    input:
    path mzml_files1
    path mzml_files2

    output:
    path "all_ms1_data.csv"
    path "all_ms2_data.csv"
    path "output_group1-vs-group2.csv", emit: output_file
    path "AnnotatedCarbonNetwork.graphml", emit: graph_file

    """
    python $TOOL_FOLDER/analyze_metatlas_data_cli.py \
    --files_group1 $mzml_files1 \
    --files_group2 $mzml_files2 \
    --files_group1_name $params.inputfiles1_name \
    --files_group2_name $params.inputfiles2_name \
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
    """

}


workflow {
    mzml_files1 = Channel.fromPath("${params.inputfiles1}/*.mzML").collect()
    mzml_files2 = Channel.fromPath("${params.inputfiles2}/*.mzML").collect()

    analyzeDataWithNetwork(mzml_files1, mzml_files2)
    
    formatCosmographOutput(analyzeDataWithNetwork.out.graph_file, 
                           analyzeDataWithNetwork.out.output_file)
}
