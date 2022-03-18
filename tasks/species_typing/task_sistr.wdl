version 1.0

task sistr {
  meta {
    description: "Serovar prediction of Salmonella assemblies"
  }
  input {
    File assembly
    String samplename
    String docker = "quay.io/biocontainers/sistr_cmd:1.1.1--pyh864c0ab_2"
    Int? cpu = 4

    # Parameters
    # --use-full-cgmlst-db  Use the full set of cgMLST alleles which can include highly similar alleles. By default the smaller "centroid" alleles or representative alleles are used for each marker.
    Boolean use_full_cgmlst_db = false
  }
  command <<<
    echo $(sistr --version 2>&1) | sed 's/^.*sistr_cmd //; s/ .*\$//' | tee VERSION
    sistr \
      --qc \
      ~{true="--use-full-cgmlst-db" false="" use_full_cgmlst_db} \
      --threads ~{cpu} \
      --alleles-output ~{samplename}-allele.json \
      --novel-alleles ~{samplename}-allele.fasta \
      --cgmlst-profiles ~{samplename}-cgmlst.csv \
      --output-prediction ~{samplename} \
      --output-format tab \
      ~{assembly}

    mv ~{samplename}.tab ~{samplename}.tsv
    cat "~{samplename}.tsv" > input.tsv
    python3 <<CODE
    import csv
    import codecs
    with codecs.open("./input.tsv",'r') as tsv_file:
      tsv_reader=csv.reader(tsv_file, delimiter="\t")
      tsv_data=list(tsv_reader)
      if len(tsv_data)==1:
        tsv_data.append(['NA']*len(tsv_data[0]))
      tsv_dict=dict(zip(tsv_data[0], tsv_data[1]))
      with codecs.open ("SISTR_SG", 'wt') as Sistr_SG:
        sistr_sg=tsv_dict['serogroup']
        if sistr_sg=='':
          sistr_sg='NA'
        else:
          sistr_sg=sistr_sg
        Sistr_SG.write(sistr_sg)
      with codecs.open ("SISTR_CGMLST_ST", 'wt') as Sistr_cgmlst_ST:
        sistr_cgmlst_st=tsv_dict['cgmlst_ST']
        if sistr_cgmlst_st=='':
          sistr_cgmlst_st='NA'
        else:
          sistr_cgmlst_st=sistr_cgmlst_st
        Sistr_cgmlst_ST.write(sistr_cgmlst_st)
      with codecs.open ("SISTR_SV", 'wt') as Sist_SV:
        sistr_sv=tsv_dict['serovar']
        if sistr_sv=='':
          sistr_sv='NA'
        else:
          sistr_sv=sistr_sv
        Sistr_SV.write(sistr_sv)
    CODE
  >>>
  output {
    File sistr_results = "~{samplename}.tsv"
    File sistr_allele_json = "~{samplename}-allele.json"
    File sistr_allele_fasta = "~{samplename}-allele.fasta"
    File sistr_cgmlst = "~{samplename}-cgmlst.csv"
    String sistr_serogroup = read_string("SISTR_SG")
    String sistr_cgmlst_ST = read_string("SISTR_CGMLST_ST")
    String sistr_serovar = read_string("SISTR_SV")
    String sistr_version = read_string("VERSION")
  }
  runtime {
    docker: "~{docker}"
    memory: "8 GB"
    cpu: 4
    disks: "local-disk 50 SSD"
    preemptible: 0
  }
}
