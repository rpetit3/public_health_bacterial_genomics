version 1.0

import "../tasks/task_taxon_id.wdl" as taxon
import "../tasks/task_versioning.wdl" as versioning

workflow pmga_wf {
  input {
    File assembly
    String samplename
    String? species_name = "neisseria"
    }
  call taxon.pmga_one_sample {
    input:
      assembly = assembly,
      samplename = samplename,
      species_name = species_name
    }
  call versioning.version_capture{
    input:
  }
  output {
    String pmga_wf_version = version_capture.pmga_version
    String pmga_wf_analysis_date = version_capture.date

    File pmga_wf_report = pmga_one_sample.pmga_output_file
    File pmga_wf_gff_output = pmga_one_sample.pmga_gff_output
    File pmga_wf_loci_counts = pmga_one_sample.pmga_loci_counts
    File pmga_wf_blast_raw = pmga_one_sample.pmga_blast_raw
    File pmga_wf_blast_final_results = pmga_one_sample.pmga_blast_final_results
    File pmga_wf_allele_matrix = pmga_one_sample.pmga_allele_matrix

    String pmga_wf_species = pmga_one_sample.pmga_species
    String pmga_wf_prediction = pmga_one_sample.pmga_prediction
    String pmga_wf_genes_present = pmga_one_sample.pmga_genes_present
    String pmga_wf_notes = pmga_one_sample.pmga_notes
    }
 }
