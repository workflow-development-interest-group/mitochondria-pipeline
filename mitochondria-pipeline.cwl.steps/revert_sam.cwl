cwlVersion: v1.2
class: CommandLineTool
label: revert-sam
$namespaces:
  sbg: https://sevenbridges.com

requirements:
- class: ShellCommandRequirement
- class: DockerRequirement
  dockerPull: us.gcr.io/broad-gotc-prod/genomes-in-the-cloud:2.4.2-1552931386
- class: InitialWorkDirRequirement
  listing:
  - entryname: original.wdl
    writable: false
    entry: |-
      task RevertSam {
        input {
          File input_bam
          String basename = basename(input_bam, ".bam")

          # runtime
          Int? preemptible_tries
        }
        Int disk_size = ceil(size(input_bam, "GB") * 2.5) + 20

        meta {
          description: "Removes alignment information while retaining recalibrated base qualities and original alignment tags"
        }
        parameter_meta {
          input_bam: "aligned bam"
        }
        command {
          java -Xmx1000m -jar /usr/gitc/picard.jar \
          RevertSam \
          INPUT=~{input_bam} \
          OUTPUT_BY_READGROUP=false \
          OUTPUT=~{basename}.bam \
          VALIDATION_STRINGENCY=LENIENT \
          ATTRIBUTE_TO_CLEAR=FT \
          ATTRIBUTE_TO_CLEAR=CO \
          SORT_ORDER=queryname \
          RESTORE_ORIGINAL_QUALITIES=false
        }
        runtime {
          disks: "local-disk " + disk_size + " HDD"
          memory: "2 GB"
          docker: "us.gcr.io/broad-gotc-prod/genomes-in-the-cloud:2.4.2-1552931386"
          preemptible: select_first([preemptible_tries, 5])
        }
        output {
          File unmapped_bam = "~{basename}.bam"
        }
      }


       RevertSam  INPUT=~{input_bam} \ OUTPUT_BY_READGROUP=false \
          OUTPUT=~{basename}.bam \
          VALIDATION_STRINGENCY=LENIENT \
          ATTRIBUTE_TO_CLEAR=FT \
          ATTRIBUTE_TO_CLEAR=CO \
          SORT_ORDER=queryname \
          RESTORE_ORIGINAL_QUALITIES=false
- class: InlineJavascriptRequirement

inputs:
- id: bam
  type: File
  secondaryFiles:
  - pattern: .bai
    required: false
  inputBinding:
    prefix: INPUT=
    position: 0
    separate: false
    shellQuote: false
  sbg:fileTypes: BAM

outputs:
- id: unaligned_bam
  type: File?
  outputBinding:
    glob: '*.bam'

baseCommand:
- java
- -Xmx1000m
- -jar
- /usr/gitc/picard.jar
- RevertSam
- OUTPUT_BY_READGROUP=false
- VALIDATION_STRINGENCY=LENIENT
- ATTRIBUTE_TO_CLEAR=FT
- ATTRIBUTE_TO_CLEAR=CO
- SORT_ORDER=queryname
- RESTORE_ORIGINAL_QUALITIES=false
arguments:
- prefix: OUTPUT=
  position: 0
  valueFrom: $(inputs.bam.nameroot + "_u" + ".bam")
  separate: false
  shellQuote: false
id: dave/build-mitochondria-pipeline/revert-sam/5
sbg:appVersion:
- v1.2
sbg:content_hash: a7c97f4c0e0ac482a6f90458680eb53d1201c37d7d8da42092e4cf41b764694b2
sbg:contributors:
- dave
sbg:createdBy: dave
sbg:createdOn: 1620309974
sbg:id: dave/build-mitochondria-pipeline/revert-sam/5
sbg:image_url:
sbg:latestRevision: 5
sbg:modifiedBy: dave
sbg:modifiedOn: 1622053186
sbg:project: dave/build-mitochondria-pipeline
sbg:projectName: 'BUILD: Mitochondria Pipeline'
sbg:publisher: sbg
sbg:revision: 5
sbg:revisionNotes: ''
sbg:revisionsInfo:
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1620309974
  sbg:revision: 0
  sbg:revisionNotes:
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1620310016
  sbg:revision: 1
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1622052547
  sbg:revision: 2
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1622052847
  sbg:revision: 3
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1622052920
  sbg:revision: 4
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1622053186
  sbg:revision: 5
  sbg:revisionNotes: ''
sbg:sbgMaintained: false
sbg:validationErrors: []
