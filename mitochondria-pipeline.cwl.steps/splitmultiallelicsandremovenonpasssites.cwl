cwlVersion: v1.2
class: CommandLineTool
label: SplitMultiAllelicsAndRemoveNonPassSites
$namespaces:
  sbg: https://sevenbridges.com

requirements:
- class: DockerRequirement
  dockerPull: images.sbgenomics.com/pavle.marinkovic/gatk_4-1-9-0:0
- class: InitialWorkDirRequirement
  listing:
  - entryname: original.wdl
    writable: false
    entry: |+
      call SplitMultiAllelicsAndRemoveNonPassSites {
          input:
            ref_fasta = mt_fasta,
            ref_fai = mt_fasta_index,
            ref_dict = mt_dict,
            filtered_vcf = InitialFilter.filtered_vcf,
            gatk_override = gatk_override,
            gatk_docker_override = gatk_docker_override
        }

      task SplitMultiAllelicsAndRemoveNonPassSites {
        input {
          File ref_fasta
          File ref_fai
          File ref_dict
          File filtered_vcf
          Int? preemptible_tries
          File? gatk_override
          String? gatk_docker_override
        }

        command {
          set -e
          export GATK_LOCAL_JAR=~{default="/root/gatk.jar" gatk_override}
          gatk LeftAlignAndTrimVariants \
            -R ~{ref_fasta} \
            -V ~{filtered_vcf} \
            -O split.vcf \
            --split-multi-allelics \
            --dont-trim-alleles \
            --keep-original-ac

            gatk SelectVariants \
              -V split.vcf \
              -O splitAndPassOnly.vcf \
              --exclude-filtered
        
        }
        output {
          File vcf_for_haplochecker = "splitAndPassOnly.vcf"
        }
        runtime {
            docker: select_first([gatk_docker_override, "us.gcr.io/broad-gatk/gatk:4.1.7.0"])
            memory: "3 MB"
            disks: "local-disk 20 HDD"
            preemptible: select_first([preemptible_tries, 5])
        } 
      }

  - entryname: split_multi_alleles.sh
    writable: false
    entry: |-
      /opt/gatk LeftAlignAndTrimVariants \
          -R $(inputs.reference.path) \
          -V $(inputs.vcf.path) \
          -O split.vcf \
          --split-multi-allelics \
          --dont-trim-alleles \
          --keep-original-ac

      /opt/gatk SelectVariants \
          -V split.vcf \
          -O splitAndPassOnly.vcf \
          --exclude-filtered
- class: InlineJavascriptRequirement

inputs:
- id: reference
  type: File
  secondaryFiles:
  - pattern: .fai
    required: true
  - pattern: ^.dict
    required: true
  sbg:fileTypes: FASTA
- id: vcf
  type: File
  sbg:fileTypes: VCF

outputs:
- id: all_vcfs
  type: File?
  outputBinding:
    glob: '*.vcf'
- id: splitAndPassOnly_vcf
  type: File?
  outputBinding:
    glob: splitAndPassOnly.vcf

baseCommand:
- bash
- split_multi_alleles.sh

hints:
- class: sbg:SaveLogs
  value: '*.sh'
id: dave/build-mitochondria-pipeline/splitmultiallelicsandremovenonpasssites/8
sbg:appVersion:
- v1.2
sbg:content_hash: a586217a9c3ca064f39c3602d7977352ef8a310dcb5d4d0549c262e41dda63c70
sbg:contributors:
- dave
sbg:createdBy: dave
sbg:createdOn: 1624044211
sbg:id: dave/build-mitochondria-pipeline/splitmultiallelicsandremovenonpasssites/8
sbg:image_url:
sbg:latestRevision: 8
sbg:modifiedBy: dave
sbg:modifiedOn: 1624646927
sbg:project: dave/build-mitochondria-pipeline
sbg:projectName: 'BUILD: Mitochondria Pipeline'
sbg:publisher: sbg
sbg:revision: 8
sbg:revisionNotes: ''
sbg:revisionsInfo:
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1624044211
  sbg:revision: 0
  sbg:revisionNotes:
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1624044344
  sbg:revision: 1
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1624044679
  sbg:revision: 2
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1624044700
  sbg:revision: 3
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1624044728
  sbg:revision: 4
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1624045105
  sbg:revision: 5
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1624045559
  sbg:revision: 6
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1624644669
  sbg:revision: 7
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1624646927
  sbg:revision: 8
  sbg:revisionNotes: ''
sbg:sbgMaintained: false
sbg:validationErrors: []
