#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Parameters
params.inputfiles1 = "/home/tharwood/repos/test_data/files1/"
params.inputfiles2 = "/home/tharwood/repos/test_data/files2/"

params.inputfiles1_name = "supern-WAVE-NatCom-NLDM-Day0"
params.inputfiles2_name = "supern-WAVE-NatCom-NLDM-Day7"

params.exp_name = "wavestab1"

params.publishdir = "$baseDir"
TOOL_FOLDER = "$baseDir/bin/envnet/envnet/use"

process analyzeDataWithNetwork {
    publishDir "$params.publishdir/nf_output/results", mode: 'copy'

    conda "$TOOL_FOLDER/environment_analysis.yml"

    input:
    path params.inputfiles1
    path params.inputfiles2

    output:
    path "all_ms1_data.csv"
    path "all_ms2_data.csv"
    path "OUTPUT_${params.exp_name}_${params.inputfiles1_name}-vs-${params.inputfiles2_name}.csv"
    path "AnnotatedCarbonNetwork.graphml"

    """
    files1=\$(find $params.inputfiles1 ~+ -type f -name '*.mzML')
    files2=\$(find $params.inputfiles2 ~+ -type f -name '*.mzML')

    python $TOOL_FOLDER/analyze_metatlas_data_cli.py \
    --files_group1 \${files1} \
    --files_group2 \${files2} \
    --files_group1_name $params.inputfiles1_name \
    --files_group2_name $params.inputfiles2_name \
    --exp_name $params.exp_name \
    """
}


workflow {
    analyzeDataWithNetwork(params.inputfiles1, params.inputfiles2)
}
