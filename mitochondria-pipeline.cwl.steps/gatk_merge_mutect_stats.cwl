cwlVersion: v1.2
class: CommandLineTool
label: gatk-merge-mutect-stats
$namespaces:
  sbg: https://sevenbridges.com

requirements:
- class: DockerRequirement
  dockerPull: images.sbgenomics.com/pavle.marinkovic/gatk_4-1-9-0:0
- class: InitialWorkDirRequirement
  listing:
  - entryname: orig.wdl
    writable: false
    entry: |-
      task MergeStats {
        input {
          File shifted_stats
          File non_shifted_stats
          Int? preemptible_tries
          File? gatk_override
          String? gatk_docker_override
        }
      
        command{
          set -e
      
          export GATK_LOCAL_JAR=~{default="/root/gatk.jar" gatk_override}
      
          gatk MergeMutectStats --stats ~{shifted_stats} --stats ~{non_shifted_stats} -O raw.combined.stats
        }
        output {
          File stats = "raw.combined.stats"
        }
        runtime {
            docker: select_first([gatk_docker_override, "us.gcr.io/broad-gatk/gatk:4.1.7.0"])
            memory: "3 MB"
            disks: "local-disk 20 HDD"
            preemptible: select_first([preemptible_tries, 5])
        }
      }
  - entryname: gatk-merge-mutect-stats.sh
    writable: false
    entry: |2-


      /opt/gatk MergeMutectStats \
          --stats $(inputs.stats[0].path) \
          --stats $(inputs.stats[1].path) \
          -O raw.combined.stats
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
- id: stats
  type: File[]

outputs:
- id: merged_stats
  type: File?
  outputBinding:
    glob: '*.stats'
    outputEval: $(inheritMetadata(self, inputs.shifted_stats))

baseCommand:
- bash
- gatk-merge-mutect-stats.sh
id: dave/build-mitochondria-pipeline/gatk-merge-mutect-stats/1
sbg:appVersion:
- v1.2
sbg:content_hash: a2327c196f362fabfa41cf1975af4fe8523f67bb6fd11f999a24ad3c1e1de7492
sbg:contributors:
- dave
sbg:createdBy: dave
sbg:createdOn: 1623268194
sbg:id: dave/build-mitochondria-pipeline/gatk-merge-mutect-stats/1
sbg:image_url:
sbg:latestRevision: 1
sbg:modifiedBy: dave
sbg:modifiedOn: 1623268734
sbg:project: dave/build-mitochondria-pipeline
sbg:projectName: 'BUILD: Mitochondria Pipeline'
sbg:publisher: sbg
sbg:revision: 1
sbg:revisionNotes: ''
sbg:revisionsInfo:
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1623268194
  sbg:revision: 0
  sbg:revisionNotes:
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1623268734
  sbg:revision: 1
  sbg:revisionNotes: ''
sbg:sbgMaintained: false
sbg:validationErrors: []
