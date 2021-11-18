version 1.0

task abricate_one_sample {
  input {
    File assembly_fasta
    String samplename
    String database="ncbi"
  }
  command {
    abricate --db ~{database} ~{assembly_fasta} > ~{samplename}_abricate_hits.tsv
    
  }
  output {
    File abricate_results = "~{samplename}_abricate_hits.tsv"
    String abricate_database = database
  }
  runtime {
    memory: "1 GB"
    cpu: 1
    docker: "quay.io/theiagen/utility:1.1"
    disks: "local-disk 10 HDD"
    dx_instance_type: "mem1_ssd1_v2_x2" 
  }
}
