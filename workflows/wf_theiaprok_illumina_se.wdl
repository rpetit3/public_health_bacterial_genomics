version 1.0

import "wf_read_QC_trim_se.wdl" as read_qc
import "wf_merlin_magic.wdl" as merlin_magic
import "../tasks/assembly/task_shovill.wdl" as shovill
import "../tasks/quality_control/task_quast.wdl" as quast
import "../tasks/quality_control/task_cg_pipeline.wdl" as cg_pipeline
import "../tasks/quality_control/task_screen.wdl" as screen
import "../tasks/taxon_id/task_gambit.wdl" as gambit
import "../tasks/gene_typing/task_amrfinderplus.wdl" as amrfinderplus
import "../tasks/species_typing/task_serotypefinder.wdl" as serotypefinder
import "../tasks/species_typing/task_ts_mlst.wdl" as ts_mlst
import "../tasks/task_versioning.wdl" as versioning
import "../tasks/utilities/task_broad_terra_tools.wdl" as terra_tools

workflow theiaprok_illumina_se {
  meta {
    description: "De-novo genome assembly, taxonomic ID, and QC of paired-end bacterial NGS data"
  }
  input {
    String samplename
    String seq_method = "ILLUMINA"
    File read1_raw
    String? run_id
    String? collection_date
    String? originating_lab
    String? city
    String? county
    String? zip
    File? taxon_tables
    String terra_project="NA"
    String terra_workspace="NA"
  }
  call versioning.version_capture{
    input:
  }
  call screen.check_reads_se as raw_check_reads {
    input:
      read1 = read1_raw,
  }
  if (raw_check_reads.read_screen=="PASS") {
    call read_qc.read_QC_trim {
      input:
        samplename = samplename,
        read1_raw = read1_raw,
    }
    call screen.check_reads_se as clean_check_reads {
      input:
        read1 = read_QC_trim.read1_clean,
    }
    if (clean_check_reads.read_screen=="PASS") {
      call shovill.shovill_se {
        input:
          samplename = samplename,
          read1_cleaned = read_QC_trim.read1_clean,
      }
      call quast.quast {
        input:
          assembly = shovill_se.assembly_fasta,
          samplename = samplename
      }
      call cg_pipeline.cg_pipeline {
        input:
          read1 = read1_raw,
          samplename = samplename,
          genome_length = clean_check_reads.est_genome_length
      }
      call gambit.gambit {
        input:
          assembly = shovill_se.assembly_fasta,
          samplename = samplename
      }
      call amrfinderplus.amrfinderplus_nuc as amrfinderplus_task {
        input:
          assembly = shovill_se.assembly_fasta,
          samplename = samplename,
          organism = gambit.gambit_predicted_taxon
      }
      call ts_mlst.ts_mlst {
        input: 
          assembly = shovill_se.assembly_fasta,
          samplename = samplename
      }
      # call merlin_magic.merlin_magic {
      #   input:
      #     merlin_tag = gambit.merlin_tag,
      #     assembly = shovill_se.assembly_fasta,
      #     samplename = samplename,
      #     read1 = read_QC_trim.read1_clean,
      # }
      # if(defined(taxon_tables)) {
      #   call terra_tools.export_taxon_tables_se {
      #     input:
      #       terra_project = terra_project,
      #       terra_workspace = terra_workspace,
      #       sample_taxon = gambit.gambit_predicted_taxon,
      #       taxon_tables = taxon_tables,
      #       samplename = samplename,
      #       read1 = read1_raw,
      #       run_id = run_id,
      #       collection_date = collection_date,
      #       originating_lab = originating_lab,
      #       city = city,
      #       county = county,
      #       zip = zip,
      #       theiaprok_illumina_se_version = version_capture.phbg_version,
      #       theiaprok_illumina_se_analysis_date = version_capture.date,
      #       seq_platform = seq_method,
      #       fastqc_number_reads = read_QC_trim.fastqc_number_reads,
      #       fastqc_version = read_QC_trim.fastqc_version,
      #       fastqc_clean_number_reads = read_QC_trim.fastqc_clean_number_reads,
      #       trimmomatic_version = read_QC_trim.trimmomatic_version,
      #       bbduk_docker = read_QC_trim.bbduk_docker,
      #       r1_mean_q = cg_pipeline.r1_mean_q,
      #       assembly_fasta = shovill_se.assembly_fasta,
      #       contigs_gfa = shovill_se.contigs_gfa,
      #       shovill_se_version = shovill_se.shovill_version,
      #       quast_report = quast.quast_report,
      #       quast_version = quast.version,
      #       genome_length = quast.genome_length,
      #       number_contigs = quast.number_contigs,
      #       n50_value = quast.n50_value,
      #       cg_pipeline_report = cg_pipeline.cg_pipeline_report,
      #       cg_pipeline_docker = cg_pipeline.cg_pipeline_docker,
      #       est_coverage = cg_pipeline.est_coverage,
      #       gambit_report = gambit.gambit_report_file,
      #       gambit_predicted_taxon = gambit.gambit_predicted_taxon,
      #       gambit_predicted_taxon_rank = gambit.gambit_predicted_taxon_rank,
      #       gambit_version = gambit.gambit_version,
      #       gambit_db_version = gambit.gambit_db_version,
      #       gambit_docker = gambit.gambit_docker,
      #       amrfinderplus_all_report = amrfinderplus_task.amrfinderplus_all_report,
      #       amrfinderplus_amr_report = amrfinderplus_task.amrfinderplus_amr_report,
      #       amrfinderplus_stress_report = amrfinderplus_task.amrfinderplus_stress_report,
      #       amrfinderplus_virulence_report = amrfinderplus_task.amrfinderplus_virulence_report,
      #       amrfinderplus_amr_genes = amrfinderplus_task.amrfinderplus_amr_genes,
      #       amrfinderplus_stress_genes = amrfinderplus_task.amrfinderplus_stress_genes,
      #       amrfinderplus_virulence_genes = amrfinderplus_task.amrfinderplus_virulence_genes,
      #       amrfinderplus_version = amrfinderplus_task.amrfinderplus_version,
      #       amrfinderplus_db_version = amrfinderplus_task.amrfinderplus_db_version,
      #       ts_mlst_results = ts_mlst.ts_mlst_results,
      #       ts_mlst_predicted_st = ts_mlst.ts_mlst_predicted_st,
      #       ts_mlst_pubmlst_scheme = ts_mlst.ts_mlst_pubmlst_scheme,
      #       ts_mlst_version = ts_mlst.ts_mlst_version,
      #       serotypefinder_report = merlin_magic.serotypefinder_report,
      #       serotypefinder_docker = merlin_magic.serotypefinder_docker,
      #       serotypefinder_serotype = merlin_magic.serotypefinder_serotype,
      #       ectyper_results = merlin_magic.ectyper_results,
      #       ectyper_version = merlin_magic.ectyper_version,
      #       ectyper_predicted_serotype = merlin_magic.ectyper_predicted_serotype,
      #       lissero_results = merlin_magic.lissero_results,
      #       lissero_version = merlin_magic.lissero_version,
      #       sistr_results = merlin_magic.sistr_results,
      #       sistr_allele_json = merlin_magic.sistr_allele_json,
      #       sister_allele_fasta = merlin_magic.sistr_allele_fasta,
      #       sistr_cgmlst = merlin_magic.sistr_cgmlst,
      #       sistr_version = merlin_magic.sistr_version,
      #       sistr_predicted_serotype = merlin_magic.sistr_predicted_serotype,
      #       seqsero2_report = merlin_magic.seqsero2_report,
      #       seqsero2_version = merlin_magic.seqsero2_version,
      #       seqsero2_predicted_antigenic_profile = merlin_magic.seqsero2_predicted_antigenic_profile,
      #       seqsero2_predicted_serotype = merlin_magic.seqsero2_predicted_serotype,
      #       seqsero2_predicted_contamination = merlin_magic.seqsero2_predicted_contamination,
      #       kleborate_output_file = merlin_magic.kleborate_output_file,
      #       kleborate_version = merlin_magic.kleborate_version,
      #       kleborate_key_resistance_genes = merlin_magic.kleborate_key_resistance_genes,
      #       kleborate_genomic_resistance_mutations = merlin_magic.kleborate_genomic_resistance_mutations,
      #       kleborate_mlst_sequence_type = merlin_magic.kleborate_mlst_sequence_type,
      #       tbprofiler_output_file = merlin_magic.tbprofiler_output_file,
      #       tbprofiler_output_bam = merlin_magic.tbprofiler_output_bam,
      #       tbprofiler_output_bai = merlin_magic.tbprofiler_output_bai,
      #       tbprofiler_version = merlin_magic.tbprofiler_version,
      #       tbprofiler_main_lineage = merlin_magic.tbprofiler_main_lineage,
      #       tbprofiler_sub_lineage = merlin_magic.tbprofiler_sub_lineage,
      #       tbprofiler_dr_type = merlin_magic.tbprofiler_dr_type,
      #       tbprofiler_resistance_genes = merlin_magic.tbprofiler_resistance_genes
      #   }
      # }
    }
  }
  output {
    #Version Captures
    String theiaprok_illumina_se_version = version_capture.phbg_version
    String theiaprok_illumina_se_analysis_date = version_capture.date
    #Read Metadata
    String seq_platform = seq_method
    #Sample Screening
    String raw_read_screen = raw_check_reads.read_screen
    String? clean_read_screen = clean_check_reads.read_screen
    #Read QC
    Int? fastqc_number_reads = read_QC_trim.fastqc_number_reads
    String? fastqc_version = read_QC_trim.fastqc_version
    Int? fastqc_clean_number_reads = read_QC_trim.fastqc_clean_number_reads
    String? trimmomatic_version = read_QC_trim.trimmomatic_version
    String? bbduk_docker = read_QC_trim.bbduk_docker
    Float? r1_mean_q = cg_pipeline.r1_mean_q
    #Assembly and Assembly QC
    File? assembly_fasta = shovill_se.assembly_fasta
    File? contigs_gfa = shovill_se.contigs_gfa
    String? shovill_se_version = shovill_se.shovill_version
    File? quast_report = quast.quast_report
    String? quast_version = quast.version
    Int? genome_length = quast.genome_length
    Int? number_contigs = quast.number_contigs
    Int? n50_value = quast.n50_value
    File? cg_pipeline_report = cg_pipeline.cg_pipeline_report
    String? cg_pipeline_docker = cg_pipeline.cg_pipeline_docker
    Float? est_coverage = cg_pipeline.est_coverage
    #Taxon ID
    File? gambit_report = gambit.gambit_report_file
    File? gambit_closest_genomes = gambit.gambit_closest_genomes_file
    String? gambit_predicted_taxon = gambit.gambit_predicted_taxon
    String? gambit_predicted_taxon_rank = gambit.gambit_predicted_taxon_rank
    String? gambit_version = gambit.gambit_version
    String? gambit_db_version = gambit.gambit_db_version
    String? gambit_docker = gambit.gambit_docker
    # NCBI-AMRFinderPlus Outputs
    File? amrfinderplus_all_report = amrfinderplus_task.amrfinderplus_all_report
    File? amrfinderplus_amr_report = amrfinderplus_task.amrfinderplus_amr_report
    File? amrfinderplus_stress_report = amrfinderplus_task.amrfinderplus_stress_report
    File? amrfinderplus_virulence_report = amrfinderplus_task.amrfinderplus_virulence_report
    String? amrfinderplus_amr_genes = amrfinderplus_task.amrfinderplus_amr_genes
    String? amrfinderplus_stress_genes = amrfinderplus_task.amrfinderplus_stress_genes
    String? amrfinderplus_virulence_genes = amrfinderplus_task.amrfinderplus_virulence_genes
    String? amrfinderplus_version = amrfinderplus_task.amrfinderplus_version
    String? amrfinderplus_db_version = amrfinderplus_task.amrfinderplus_db_version
    #MLST Typing
    File? ts_mlst_results = ts_mlst.ts_mlst_results
    String? ts_mlst_predicted_st = ts_mlst.ts_mlst_predicted_st
    String? ts_mlst_version = ts_mlst.ts_mlst_version
    String? ts_mlst_pubmlst_scheme = ts_mlst.ts_mlst_pubmlst_scheme
    # Ecoli Typing
  #   File? serotypefinder_report = merlin_magic.serotypefinder_report
  #   String? serotypefinder_docker = merlin_magic.serotypefinder_docker
  #   String? serotypefinder_serotype = merlin_magic.serotypefinder_serotype
  #   File? ectyper_results = merlin_magic.ectyper_results
  #   String? ectyper_version = merlin_magic.ectyper_version
  #   String? ectyper_predicted_serotype = merlin_magic.ectyper_predicted_serotype
  #   #Listeria Typing
  #   File? lissero_results = merlin_magic.lissero_results
  #   String? lissero_version = merlin_magic.lissero_version
  #   #Salmonella Typing
  #   File? sistr_results = merlin_magic.sistr_results
  #   File? sistr_allele_json = merlin_magic.sistr_allele_json
  #   File? sister_allele_fasta = merlin_magic.sistr_allele_fasta
  #   File? sistr_cgmlst = merlin_magic.sistr_cgmlst
  #   String? sistr_version = merlin_magic.sistr_version
  #   String? sistr_predicted_serotype = merlin_magic.sistr_predicted_serotype
  #   File? seqsero2_report = merlin_magic.seqsero2_report
  #   String? seqsero2_version = merlin_magic.seqsero2_version
  #   String? seqsero2_predicted_antigenic_profile = merlin_magic.seqsero2_predicted_antigenic_profile
  #   String? seqsero2_predicted_serotype = merlin_magic.seqsero2_predicted_serotype
  #   String? seqsero2_predicted_contamination = merlin_magic.seqsero2_predicted_contamination
  #   #Klebsiella Typing
  #   File? kleborate_output_file = merlin_magic.kleborate_output_file
  #   String? kleborate_version = merlin_magic.kleborate_version
  #   String? kleborate_key_resistance_genes = merlin_magic.kleborate_key_resistance_genes
  #   String? kleborate_genomic_resistance_mutations = merlin_magic.kleborate_genomic_resistance_mutations
  #   String? kleborate_mlst_sequence_type = merlin_magic.kleborate_mlst_sequence_type
  #   # Mycobacterium Typing
  #   File? tbprofiler_output_file = merlin_magic.tbprofiler_output_file
  #   File? tbprofiler_output_bam = merlin_magic.tbprofiler_output_bam
  #   File? tbprofiler_output_bai = merlin_magic.tbprofiler_output_bai
  #   String? tbprofiler_version = merlin_magic.tbprofiler_version
  #   String? tbprofiler_main_lineage = merlin_magic.tbprofiler_main_lineage
  #   String? tbprofiler_sub_lineage = merlin_magic.tbprofiler_sub_lineage
  #   String? tbprofiler_dr_type = merlin_magic.tbprofiler_dr_type
  #   String? tbprofiler_resistance_genes = merlin_magic.tbprofiler_resistance_genes
   }
}
