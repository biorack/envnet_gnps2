#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Parameters
params.inputfiles1 = "/mnt/c/raw_data/pfrost_20m"
params.inputfiles2 = "/mnt/c/raw_data/pfrost_55m"

params.inputfiles1_name = "20M"
params.inputfiles2_name = "55M"

params.normalize_ints = 1
params.peak_value = 'peak_area'

// Analysis Parameters
params.mz_tolerance = 10
params.rt_min = 1
params.rt_max = 9
params.num_data_min = 5
params.msms_score_min = 0.5
params.msms_matches_min = 3
params.require_ms2_support = 0

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

process generateMetadataFile {
    conda "$CONDA_ENVS/environment_analysis.yml"
    
    input:
    val mzml_files1
    val mzml_files2

    output:
    path "file_metadata.csv", emit: file_metadata

    """
    python $SCRIPTS_FOLDER/make_metadata_file.py -f1 $mzml_files1 -f2 $mzml_files2 -sc1 $params.inputfiles1_name -sc2 $params.inputfiles2_name
    """

}

process collectMS1Hits {
    publishDir "$params.publishdir/nf_output/results", mode: 'copy'
    conda "$CONDA_ENVS/environment_analysis.yml"

    input:
    path file_metadata

    output:
    path "ms1_results/ms1_annotations.parquet", emit: ms1_results

    """
    export PYTHONPATH=$baseDir/bin/envnet

    python -m envnet.annotation.workflows ms1 \
    --output-dir ./ms1_results/ \
    --csv-file $file_metadata \
    --envnet-graphml $REF_DIR/envnet_network.graphml \
    --envnet-deconv-mgf $REF_DIR/envnet_deconvoluted_spectra.mgf \
    --envnet-original-mgf $REF_DIR/envnet_original_spectra.mgf \
    --spectrum-types deconvoluted \
    --min-library-match-score $params.msms_score_min \
    --min-matches $params.msms_matches_min \
    --ppm-tolerance $params.mz_tolerance \
    --rt-min $params.rt_min \
    --rt-max $params.rt_max \
    --min-ms1-datapoints $params.num_data_min
    """
}

process collectMS2Hits {
    publishDir "$params.publishdir/nf_output/results", mode: 'copy'
    conda "$CONDA_ENVS/environment_analysis.yml"

    input:
    path file_metadata

    output:
    path "ms2_results/ms2_deconvoluted_annotations.parquet", emit: ms2_deconvoluted_results

    """
    export PYTHONPATH=$baseDir/bin/envnet

    python -m envnet.annotation.workflows ms2 \
    --output-dir ./ms2_results/ \
    --csv-file $file_metadata \
    --envnet-graphml $REF_DIR/envnet_network.graphml \
    --envnet-deconv-mgf $REF_DIR/envnet_deconvoluted_spectra.mgf \
    --envnet-original-mgf $REF_DIR/envnet_original_spectra.mgf \
    --spectrum-types deconvoluted \
    --min-library-match-score $params.msms_score_min \
    --min-matches $params.msms_matches_min \
    --ppm-tolerance $params.mz_tolerance \
    --rt-min $params.rt_min \
    --rt-max $params.rt_max \
    --min-ms1-datapoints $params.num_data_min
    """
}

process runStatsAnalysis {
    publishDir "$params.publishdir/nf_output/results", mode: 'copy'
    conda "$CONDA_ENVS/environment_analysis.yml"

    input:
    path file_metadata
    path ms1_results
    path ms2_deconvoluted_results

    output:
    path "analysis_results/statistical_results.csv", emit: stats_results

    """
    export PYTHONPATH=$baseDir/bin/envnet

    if [ "$params.require_ms2_support" = 1 ]; then

        python -m envnet.analysis.workflows stats \
        --output-dir ./analysis_results/ \
        --ms1-file $ms1_results \
        --ms2-deconv-file $ms2_deconvoluted_results \
        --file-metadata $file_metadata \
        --require-ms2-support \
        --control-group $params.inputfiles1_name \
        --treatment-group $params.inputfiles2_name \
        --envnet-data $REF_DIR/envnet_node_data.csv \
        --peak-value $params.peak_value \
        --max-pvalue $params.max_pval

    else

        python -m envnet.analysis.workflows stats \
        --output-dir ./analysis_results/ \
        --ms1-file $ms1_results \
        --ms2-deconv-file $ms2_deconvoluted_results \
        --file-metadata $file_metadata \
        --control-group $params.inputfiles1_name \
        --treatment-group $params.inputfiles2_name \
        --envnet-data $REF_DIR/envnet_node_data.csv \
        --peak-value $params.peak_value \
        --max-pvalue $params.max_pval

    fi
    """
}

process runEnrichAnalysis {
    publishDir "$params.publishdir/nf_output/results", mode: 'copy'
    conda "$CONDA_ENVS/environment_analysis.yml"

    input:
    path stats_results

    output:
    path "analysis_results/compound_class_enrichment.pdf"

    """
    export PYTHONPATH=$baseDir/bin/envnet

    python -m envnet.analysis.workflows enrichment \
    --output-dir ./analysis_results/ \
    --stats-results $stats_results \
    --control-group $params.inputfiles1_name \
    --treatment-group $params.inputfiles2_name \
    --envnet-data $REF_DIR/envnet_node_data.csv \
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

workflow {
    // unzip data files if compressed
    unzipData()

    files1 = Channel.fromPath("${params.inputfiles1}/*").collect()
    files2 = Channel.fromPath("${params.inputfiles2}/*").collect()

    // generate metadata file
    file_metadata = generateMetadataFile(files1, files2).collect()

    ms1_results = collectMS1Hits(file_metadata).collect()
    ms2_deconvoluted_results = collectMS2Hits(file_metadata).collect()

    stats_results = runStatsAnalysis(file_metadata, ms1_results, ms2_deconvoluted_results).collect()
    runEnrichAnalysis(stats_results)

    // formatCosmographOutput(collectNetworkHits.out.graph_file,
    //                        collectNetworkHits.out.output_file)

}
