cwlVersion: v1.2
class: CommandLineTool
label: FilterMutectCalls
$namespaces:
  sbg: https://sevenbridges.com

requirements:
- class: DockerRequirement
  dockerPull: images.sbgenomics.com/pavle.marinkovic/gatk_4-1-9-0:0
- class: InitialWorkDirRequirement
  listing:
  - entryname: FilterMutectCalls.sh
    writable: false
    entry: |
      # We need to create these files regardless, even if they stay empty
      touch bamout.bam

      /opt/gatk --java-options "-Xmx2500m" FilterMutectCalls \
      -V $(inputs.vcf.path) \
      -R $(inputs.fasta.path) \
      -O filtered.vcf \
      --stats $(inputs.raw_vcf_stats.path) \
      --max-alt-allele-count $(inputs.max_alt_allele_count) \
      --mitochondria-mode \
      ${if(inputs.min_allele_fraction)
      {return "--min-allele-fraction " + inputs.min_allele_fraction}else{return ""}} \
      ${if(inputs.f_score_beta)
      {return "--f-score-beta " + inputs.f_score_beta}else{return ""}} \
      ${if(inputs.max_contamination)
      {return "--contamination-estimate " + inputs.max_contamination}else{return ""}}


      /opt/gatk VariantFiltration -V filtered.vcf \
      -O $(inputs.vcf.nameroot + "_filtered.vcf") \
      --apply-allele-specific-filters \
      --mask $(inputs.blacklisted_sites.path) \
      --mask-name "blacklisted_site"
- class: InlineJavascriptRequirement

inputs:
- id: vcf
  type: File
  sbg:fileTypes: VCF
- id: fasta
  type: File
  secondaryFiles:
  - pattern: .fai
    required: true
  - pattern: ^.dict
    required: true
  sbg:fileTypes: FASTA
- id: raw_vcf_stats
  type: File
- id: max_alt_allele_count
  type: int
- id: min_allele_fraction
  type: float?
- id: f_score_beta
  type: float?
- id: max_contamination
  type: float?
- id: blacklisted_sites
  type: File
  secondaryFiles:
  - pattern: .idx
    required: true

outputs:
- id: filter_vcf
  type: File?
  secondaryFiles:
  - pattern: .idx
    required: false
  outputBinding:
    glob: '*.vcf'
- id: merged_and_filtered_vcf
  type: File?
  outputBinding:
    glob: merged*.vcf
- id: tsv
  type: File?
  outputBinding:
    glob: '*.tsv'

baseCommand:
- bash
- FilterMutectCalls.sh

hints:
- class: sbg:SaveLogs
  value: '*.sh'
id: dave/build-mitochondria-pipeline/filtermutectcalls/11
sbg:appVersion:
- v1.2
sbg:content_hash: a58244da122e83da560e048c8e7b7fb00e4ce34a4ab18e97ad7d9fbecb02e3fd0
sbg:contributors:
- dave
sbg:createdBy: dave
sbg:createdOn: 1623705308
sbg:id: dave/build-mitochondria-pipeline/filtermutectcalls/11
sbg:image_url:
sbg:latestRevision: 11
sbg:modifiedBy: dave
sbg:modifiedOn: 1624644786
sbg:project: dave/build-mitochondria-pipeline
sbg:projectName: 'BUILD: Mitochondria Pipeline'
sbg:publisher: sbg
sbg:revision: 11
sbg:revisionNotes: ''
sbg:revisionsInfo:
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1623705308
  sbg:revision: 0
  sbg:revisionNotes:
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1623706761
  sbg:revision: 1
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1623708046
  sbg:revision: 2
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1623708663
  sbg:revision: 3
  sbg:revisionNotes: switched docker
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1623708943
  sbg:revision: 4
  sbg:revisionNotes: if
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1623709237
  sbg:revision: 5
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1623878589
  sbg:revision: 6
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1623879201
  sbg:revision: 7
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1623879738
  sbg:revision: 8
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1623880150
  sbg:revision: 9
  sbg:revisionNotes: .idx bed file
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1624644656
  sbg:revision: 10
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1624644786
  sbg:revision: 11
  sbg:revisionNotes: ''
sbg:sbgMaintained: false
sbg:validationErrors: []
