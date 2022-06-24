version 1.0

task prokka {
  input {
    File assembly
    String samplename
    Int cpu = 8
    Int memory = 16
    # Parameters 
    #  proteins recommended: when you have good quality reference genomes and want to ensure gene naming is consistent [false]
    #  prodigal_tf: prodigal training file
    # prokka_arguments: free string to add any other additional prokka arguments
    Boolean proteins = false
    Boolean compliant = true
    File? prodigal_tf
    String? prokka_arguments
  }
  command <<<
  date | tee DATE
  prokka --version | tee PROKKA_VERSION
    
  prokka \
    ~{prokka_arguments} \
    --cpus 0 \
    --prefix ~{samplename} \
    ~{true='--compliant' false='' compliant} \
    ~{true='--proteins' false='' proteins} \
    ~{'--prodigaltf ' + prodigal_tf} \
    ~{assembly}
  
    
  >>>
  output {
    File prokka_gff = "~{samplename}.gff"
    File prokka_gbk = "~{samplename}.gbk"
    File prokka_sqn = "~{samplename}.sqn"
    Array[File] prokka_outs = glob("~{samplename}*")
    String prokka_version = read_string("PROKKA_VERSION")
  }
  runtime {
    memory: "~{memory} GB"
    cpu: cpu
    docker: "quay.io/staphb/abricate:1.0.0"
    disks: "local-disk 100 HDD"
  }
}
