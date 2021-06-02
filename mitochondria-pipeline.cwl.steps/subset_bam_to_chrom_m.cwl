cwlVersion: v1.2
class: CommandLineTool
label: subset-bam-to-chrom-m
$namespaces:
  sbg: https://sevenbridges.com

requirements:
- class: ShellCommandRequirement
- class: DockerRequirement
  dockerPull: us.gcr.io/broad-gatk/gatk:4.1.7.0
- class: InitialWorkDirRequirement
  listing:
  - entryname: original.wdl
    writable: false
    entry: |-
      task SubsetBamToChrM {
        input {
          File input_bam
          File input_bai
          String contig_name
          String basename = basename(basename(input_bam, ".cram"), ".bam")
          String? requester_pays_project
          File? ref_fasta
          File? ref_fasta_index
          File? ref_dict

          File? gatk_override
          String? gatk_docker_override

          # runtime
          Int? preemptible_tries
        }
        Float ref_size = if defined(ref_fasta) then size(ref_fasta, "GB") + size(ref_fasta_index, "GB") + size(ref_dict, "GB") else 0
        Int disk_size = ceil(size(input_bam, "GB") + ref_size) + 20

        meta {
          description: "Subsets a whole genome bam to just Mitochondria reads"
        }
        parameter_meta {
          ref_fasta: "Reference is only required for cram input. If it is provided ref_fasta_index and ref_dict are also required."
          input_bam: {
            localization_optional: true
          }
          input_bai: {
            localization_optional: true
          }
        }
        command <<<
          set -e
          export GATK_LOCAL_JAR=~{default="/root/gatk.jar" gatk_override}

          gatk PrintReads \
            ~{"-R " + ref_fasta} \
            -L ~{contig_name} \
            --read-filter MateOnSameContigOrNoMappedMateReadFilter \
            --read-filter MateUnmappedAndUnmappedReadFilter \
            ~{"--gcs-project-for-requester-pays " + requester_pays_project} \
            -I ~{input_bam} \
            --read-index ~{input_bai} \
            -O ~{basename}.bam
        >>>
        runtime {
          memory: "3 GB"
          disks: "local-disk " + disk_size + " HDD"
          docker: select_first([gatk_docker_override, "us.gcr.io/broad-gatk/gatk:4.1.7.0"])
          preemptible: select_first([preemptible_tries, 5])
        }
        output {
          File output_bam = "~{basename}.bam"
          File output_bai = "~{basename}.bai"
        }
      }
      d
- class: InlineJavascriptRequirement

inputs:
- id: cram
  type: File?
  secondaryFiles:
  - pattern: .crai
    required: true
  inputBinding:
    prefix: -I
    position: 0
    shellQuote: false
- id: contig_name
  type: string?
  inputBinding:
    prefix: -L
    position: 0
    shellQuote: false
- id: ref_fasta
  type: File?
  secondaryFiles:
  - pattern: .fai
    required: true
  - pattern: ^.dict
    required: true
  inputBinding:
    prefix: -R
    position: 0
    shellQuote: false
  sbg:fileTypes: FASTA

outputs:
- id: chrM_bam
  type: File?
  secondaryFiles:
  - pattern: '*.bam.bai'
    required: false
  outputBinding:
    glob: '*.bam'

baseCommand:
- gatk
- PrintReads
- --read-filter
- MateOnSameContigOrNoMappedMateReadFilter
- --read-filter
- MateUnmappedAndUnmappedReadFilter
arguments:
- prefix: --read-index
  position: 0
  valueFrom: $(inputs.cram.path + ".crai")
  shellQuote: false
- prefix: -O
  position: 0
  valueFrom: $(inputs.cram.nameroot + "_chrM.bam")
  shellQuote: false
id: dave/build-mitochondria-pipeline/subset-bam-to-chrom-m/5
sbg:appVersion:
- v1.2
sbg:content_hash: a8ed2320b344c2a12c20404c9b7c638c05da2197f2c4f07f88e58576eaf576320
sbg:contributors:
- dave
sbg:createdBy: dave
sbg:createdOn: 1620309846
sbg:id: dave/build-mitochondria-pipeline/subset-bam-to-chrom-m/5
sbg:image_url:
sbg:latestRevision: 5
sbg:modifiedBy: dave
sbg:modifiedOn: 1621989342
sbg:project: dave/build-mitochondria-pipeline
sbg:projectName: 'BUILD: Mitochondria Pipeline'
sbg:publisher: sbg
sbg:revision: 5
sbg:revisionNotes: ''
sbg:revisionsInfo:
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1620309846
  sbg:revision: 0
  sbg:revisionNotes:
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1620309931
  sbg:revision: 1
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1621978713
  sbg:revision: 2
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1621979134
  sbg:revision: 3
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1621979192
  sbg:revision: 4
  sbg:revisionNotes: FASTA
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1621989342
  sbg:revision: 5
  sbg:revisionNotes: ''
sbg:sbgMaintained: false
sbg:validationErrors: []
