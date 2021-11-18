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
    memory: "8 GB"
    cpu: 4
    docker: "quay.io/staphb/abricate:1.0.0"
    disks: "local-disk 100 HDD"
  }
}
