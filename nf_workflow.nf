#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Parameters
params.inputfiles1 = "/mnt/c/test_data/files1/"
params.inputfiles2 = "/mnt/c/test_data/files2/"

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
TOOL_FOLDER = "$baseDir/bin/envnet/scripts"
REF_DIR = "$baseDir/bin/envnet/envnet/data"
CONDA_ENVS = "$baseDir/bin/conda_env_defs"
SCRIPTS_FOLDER = "$baseDir/bin/scripts"

process unzipData { 
    script: 
    """
    set -euo pipefail

    if [ ! -f "${REF_DIR}/envnet_network.graphml" ]; then
        echo "envnet_network.graphml not found. Unzipping..."
        unzip -o "${REF_DIR}/envnet_network.zip" -d ${REF_DIR}
    else
        echo "envnet_network.graphml already exists. Skipping."
    fi

    if [ ! -f "${REF_DIR}/envnet_deconvoluted_spectra.mgf" ]; then
        echo "envnet_deconvoluted_spectra.mgf not found. Unzipping..."
        unzip -o "${REF_DIR}/envnet_deconvoluted_spectra.zip" -d ${REF_DIR}
    else
        echo "envnet_deconvoluted_spectra.mgf already exists. Skipping."
    fi

    if [ ! -f "${REF_DIR}/envnet_original_spectra.mgf" ]; then
        echo "envnet_original_spectra.mgf not found. Unzipping..."
        unzip -o "${REF_DIR}/envnet_original_spectra.zip" -d ${REF_DIR}
    else
        echo "envnet_original_spectra.mgf already exists. Skipping."
    fi
    """
}

process collectMS1Hits {
    publishDir "$params.publishdir/nf_output/results", mode: 'copy'
    conda "$CONDA_ENVS/environment_analysis.yml"

    input:
    path mzml_files1
    path mzml_files2

    output:
    path "ms1_results/files1/ms1_annotations.parquet", emit: ms1_results1
    path "ms1_results/files2/ms1_annotations.parquet", emit: ms1_results2

    """
    export PYTHONPATH=$baseDir/bin/envnet

    python -m envnet.annotation.workflows ms1 \
    --output-dir ./ms1_results/files1 \
    --file-list $mzml_files1 \
    --envnet-graphml $REF_DIR/envnet_network.graphml \
    --envnet-deconv-mgf $REF_DIR/envnet_deconvoluted_spectra.mgf \
    --envnet-original-mgf $REF_DIR/envnet_original_spectra.mgf \
    --spectrum-types deconvoluted \
    --min-library-match-score $params.msms_score_min \
    --min-matches $params.msms_matches_min

    python -m envnet.annotation.workflows ms1 \
    --output-dir ./ms1_results/files2 \
    --file-list $mzml_files2 \
    --envnet-graphml $REF_DIR/envnet_network.graphml \
    --envnet-deconv-mgf $REF_DIR/envnet_deconvoluted_spectra.mgf \
    --envnet-original-mgf $REF_DIR/envnet_original_spectra.mgf \
    --spectrum-types deconvoluted \
    --min-library-match-score $params.msms_score_min \
    --min-matches $params.msms_matches_min
    """
}


process collectMS2Hits {
    publishDir "$params.publishdir/nf_output/results", mode: 'copy'
    conda "$CONDA_ENVS/environment_analysis.yml"

    input:
    path mzml_files1
    path mzml_files2

    output:
    path "ms2_results/files1/ms2_deconvoluted_annotations.parquet", emit: ms2_deconvoluted_results1

    path "ms2_results/files2/ms2_deconvoluted_annotations.parquet", emit: ms2_deconvoluted_results2

    """
    export PYTHONPATH=$baseDir/bin/envnet

    python -m envnet.annotation.workflows ms2 \
    --output-dir ./ms2_results/files1 \
    --file-list $mzml_files1 \
    --envnet-graphml $REF_DIR/envnet_network.graphml \
    --envnet-deconv-mgf $REF_DIR/envnet_deconvoluted_spectra.mgf \
    --envnet-original-mgf $REF_DIR/envnet_original_spectra.mgf \
    --spectrum-types deconvoluted \
    --min-library-match-score $params.msms_score_min \
    --min-matches $params.msms_matches_min

    python -m envnet.annotation.workflows ms2 \
    --output-dir ./ms2_results/files2 \
    --file-list $mzml_files2 \
    --envnet-graphml $REF_DIR/envnet_network.graphml \
    --envnet-deconv-mgf $REF_DIR/envnet_deconvoluted_spectra.mgf \
    --envnet-original-mgf $REF_DIR/envnet_original_spectra.mgf \
    --spectrum-types deconvoluted \
    --min-library-match-score $params.msms_score_min \
    --min-matches $params.msms_matches_min
    """
}


// process formatCosmographOutput {
//     publishDir "$params.publishdir/nf_output/results", mode: 'copy'
//     conda "$TOOL_FOLDER/environment_analysis.yml"

//     input:
//     path graph_file
//     path output_file

//     output:
//     path "cosmograph_edges.csv"
//     path "cosmograph_metadata.csv"

//     """
//     python $SCRIPTS_FOLDER/make_cosmograph_output.py \
//     --graph_file $graph_file \
//     --output_file $output_file \
//     --max_log_change $params.max_log_change \
//     """

// }


// process generateCompoundClassOutputs {
//     publishDir "$params.publishdir/nf_output/results", mode: 'copy'
//     conda "$TOOL_FOLDER/environment_analysis.yml"

//     input:
//     path all_ms1_data
//     path all_ms2_data
//     path output_file

//     output:
//     path "set_cover_plots/*"
//     path "compound_class_plots/*"

//     """
//     python $SCRIPTS_FOLDER/make_class_and_cover_output.py \
//     --cover_plots_dir set_cover_plots \
//     --compound_plots_dir compound_class_plots \
//     --files_group1_name "$params.inputfiles1_name" \
//     --files_group2_name "$params.inputfiles2_name" \
//     --ms1_file_path $all_ms1_data \
//     --ms2_file_path $all_ms2_data \
//     --output_file_path $output_file \
//     --max_p_val $params.max_pval \
//     """

// }

workflow {
    // unzip data files if compressed
    unzipData()

    files1 = Channel.fromPath("${params.inputfiles1}/*").collect()
    files2 = Channel.fromPath("${params.inputfiles2}/*").collect()

    collectMS1Hits(files1, files2)
    collectMS2Hits(files1, files2)
    
    // formatCosmographOutput(collectNetworkHits.out.graph_file,
    //                        collectNetworkHits.out.output_file)

    // generateCompoundClassOutputs(collectNetworkHits.out.all_ms1_data, 
    //                              collectNetworkHits.out.all_ms2_data, 
    //                              collectNetworkHits.out.output_file)
}
