cwlVersion: v1.2
class: CommandLineTool
label: picard-lift-over-and-merge
doc: |-
  ```
  shifted_vcf: "VCF of control region on shifted reference"
      vcf: "VCF of the rest of chrM on original reference"
      ref_fasta: "Original (not shifted) chrM reference"
      shift_back_chain: "Chain file to lift over from shifted reference to original chrM"
  ```
$namespaces:
  sbg: https://sevenbridges.com

requirements:
- class: DockerRequirement
  dockerPull: images.sbgenomics.com/jovana_vranic/picard-2-21-6:1
- class: InitialWorkDirRequirement
  listing:
  - entryname: picard-lift-over-merge.sh
    writable: false
    entry: |2-


      java -Xmx7500M -jar /opt/picard-2.21.6/picard.jar LiftoverVcf \
            I=$(inputs.shifted_vcf.path) \
            O=$(inputs.shifted_vcf.nameroot).shifted_back.vcf \
            R=$(inputs.reference.path) \
            CHAIN=$(inputs.chain.path) \
            REJECT=$(inputs.shifted_vcf.nameroot).rejected.vcf

      java -Xmx7500M -jar /opt/picard-2.21.6/picard.jar MergeVcfs \
            I=$(inputs.shifted_vcf.nameroot).shifted_back.vcf \
            I=$(inputs.non_shifted_vcf.path) \
            O=merged.vcf
  - entryname: orig.wdl
    writable: false
    entry: |-
      task LiftoverAndCombineVcfs {
        input {
          File shifted_vcf
          File vcf
          String basename = basename(shifted_vcf, ".vcf")
      
          File ref_fasta
          File ref_fasta_index
          File ref_dict
      
          File shift_back_chain
      
          # runtime
          Int? preemptible_tries
        }
      
        Float ref_size = size(ref_fasta, "GB") + size(ref_fasta_index, "GB")
        Int disk_size = ceil(size(shifted_vcf, "GB") + ref_size) + 20
      
        meta {
          description: "Lifts over shifted vcf of control region and combines it with the rest of the chrM calls."
        }
        parameter_meta {
          shifted_vcf: "VCF of control region on shifted reference"
          vcf: "VCF of the rest of chrM on original reference"
          ref_fasta: "Original (not shifted) chrM reference"
          shift_back_chain: "Chain file to lift over from shifted reference to original chrM"
        }
        command<<<
          set -e
          java -jar /usr/gitc/picard.jar LiftoverVcf \
            I=~{shifted_vcf} \
            O=~{basename}.shifted_back.vcf \
            R=~{ref_fasta} \
            CHAIN=~{shift_back_chain} \
            REJECT=~{basename}.rejected.vcf
      
          java -jar /usr/gitc/picard.jar MergeVcfs \
            I=~{basename}.shifted_back.vcf \
            I=~{vcf} \
            O=~{basename}.merged.vcf
          >>>
          runtime {
            disks: "local-disk " + disk_size + " HDD"
            memory: "1200 MB"
            docker: "us.gcr.io/broad-gotc-prod/genomes-in-the-cloud:2.4.2-1552931386"
            preemptible: select_first([preemptible_tries, 5])
          }
          output{
              # rejected_vcf should always be empty
              File rejected_vcf = "~{basename}.rejected.vcf"
              File merged_vcf = "~{basename}.merged.vcf"
              File merged_vcf_index = "~{basename}.merged.vcf.idx"
          }
      }
- class: InlineJavascriptRequirement
  expressionLib:
  - |2-

    var setMetadata = function(file, metadata) {
        if (!('metadata' in file)) {
            file['metadata'] = {}
        }
        for (var key in metadata) {
            file['metadata'][key] = metadata[key];
        }
        return file
    };
    var inheritMetadata = function(o1, o2) {
        var commonMetadata = {};
        if (!o2) {
            return o1;
        };
        if (!Array.isArray(o2)) {
            o2 = [o2]
        }
        for (var i = 0; i < o2.length; i++) {
            var example = o2[i]['metadata'];
            for (var key in example) {
                if (i == 0)
                    commonMetadata[key] = example[key];
                else {
                    if (!(commonMetadata[key] == example[key])) {
                        delete commonMetadata[key]
                    }
                }
            }
            for (var key in commonMetadata) {
                if (!(key in example)) {
                    delete commonMetadata[key]
                }
            }
        }
        if (!Array.isArray(o1)) {
            o1 = setMetadata(o1, commonMetadata)
            if (o1.secondaryFiles) {
                o1.secondaryFiles = inheritMetadata(o1.secondaryFiles, o2)
            }
        } else {
            for (var i = 0; i < o1.length; i++) {
                o1[i] = setMetadata(o1[i], commonMetadata)
                if (o1[i].secondaryFiles) {
                    o1[i].secondaryFiles = inheritMetadata(o1[i].secondaryFiles, o2)
                }
            }
        }
        return o1;
    };

inputs:
- id: shifted_vcf
  type: File
- id: reference
  type: File
  secondaryFiles:
  - pattern: .fai
    required: true
  - pattern: ^.dict
    required: true
- id: chain
  type: File
- id: non_shifted_vcf
  type: File

outputs:
- id: merged_vcf
  type: File?
  outputBinding:
    glob: '*merged.vcf'
    outputEval: $(inheritMetadata(self, inputs.non_shifted_vcf))

baseCommand:
- bash
- picard-lift-over-merge.sh
id: dave/build-mitochondria-pipeline/picard-lift-over-and-merge/4
sbg:appVersion:
- v1.2
sbg:content_hash: a87473dd4e1de9b9b388c45ab17c7d2a8225acd5a435b8bb7a5004bd7ece1c125
sbg:contributors:
- dave
sbg:createdBy: dave
sbg:createdOn: 1623266615
sbg:id: dave/build-mitochondria-pipeline/picard-lift-over-and-merge/4
sbg:image_url:
sbg:latestRevision: 4
sbg:modifiedBy: dave
sbg:modifiedOn: 1623269343
sbg:project: dave/build-mitochondria-pipeline
sbg:projectName: 'BUILD: Mitochondria Pipeline'
sbg:publisher: sbg
sbg:revision: 4
sbg:revisionNotes: -Xmx7500M
sbg:revisionsInfo:
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1623266615
  sbg:revision: 0
  sbg:revisionNotes:
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1623267074
  sbg:revision: 1
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1623267690
  sbg:revision: 2
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1623267860
  sbg:revision: 3
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1623269343
  sbg:revision: 4
  sbg:revisionNotes: -Xmx7500M
sbg:sbgMaintained: false
sbg:validationErrors: []
