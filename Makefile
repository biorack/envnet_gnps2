run:
	nextflow run ./nf_workflow.nf -resume -c nextflow.config

run_tests:
	nextflow run ./nf_workflow.nf -c nextflow.config -profile test_lcms
	nextflow run ./nf_workflow.nf -c nextflow.config -profile test_fticr

run_hpcc:
	nextflow run ./nf_workflow.nf -resume -c nextflow_hpcc.config

run_docker:
	nextflow run ./nf_workflow.nf -resume -with-docker <CONTAINER NAME>