cwlVersion: v1.2
class: CommandLineTool
label: Get Contamination
$namespaces:
  sbg: https://sevenbridges.com

requirements:
- class: DockerRequirement
  dockerPull: us.gcr.io/broad-dsde-methods/haplochecker:haplochecker-0124
- class: InitialWorkDirRequirement
  listing:
  - $(inputs.vcf)
  - entryname: get_contamination.sh
    writable: false
    entry: |-
      set -e
      java -jar /usr/mtdnaserver/haplocheckCLI.jar ./

      sed 's/\"//g' output > output-noquotes

      grep "SampleID" output-noquotes > headers
      FORMAT_ERROR="Bad contamination file format"
       if [ `awk '{print $2}' headers` != "Contamination" ]; then
          echo $FORMAT_ERROR; exit 1
        fi

        if [ `awk '{print $6}' headers` != "HgMajor" ]; then
          echo $FORMAT_ERROR; exit 1
        fi

        if [ `awk '{print $8}' headers` != "HgMinor" ]; then
          echo $FORMAT_ERROR; exit 1
        fi

        if [ `awk '{print $14}' headers` != "MeanHetLevelMajor" ]; then
          echo $FORMAT_ERROR; exit 1
        fi

        if [ `awk '{print $15}' headers` != "MeanHetLevelMinor" ]; then
          echo $FORMAT_ERROR; exit 1
        fi

        grep -v "SampleID" output-noquotes > output-data
        awk -F "\t" '{print $2}' output-data > contamination.txt
        awk -F "\t" '{print $6}' output-data > major_hg.txt
        awk -F "\t" '{print $8}' output-data > minor_hg.txt
        awk -F "\t" '{print $14}' output-data > mean_het_major.txt
        awk -F "\t" '{print $15}' output-data > mean_het_minor.txt
- class: InlineJavascriptRequirement

inputs:
- id: vcf
  type: File

outputs:
- id: output_noquotes
  type: File?
  outputBinding:
    glob: output-noquotes
    loadContents: true
- id: contamination
  type: File?
  outputBinding:
    glob: contamination.txt
    loadContents: true
- id: headers
  type: File?
  outputBinding:
    glob: headers
    loadContents: true
- id: major_hg
  type: File?
  outputBinding:
    glob: major_hg.txt
    loadContents: true
- id: output
  type: File[]?
  outputBinding:
    glob: output*
    loadContents: true
- id: mean_het_maj_minor
  type: File[]?
  outputBinding:
    glob: mean*
    loadContents: true
- id: minor_hg
  type: File?
  outputBinding:
    glob: minor_hg.txt
    loadContents: true
stdout: standard.out

baseCommand:
- bash
- get_contamination.sh

hints:
- class: sbg:SaveLogs
  value: '*.sh'
- class: sbg:SaveLogs
  value: standard.out
id: dave/build-mitochondria-pipeline/get-contamination/9
sbg:appVersion:
- v1.2
sbg:content_hash: aceac11dac2ce1996c815cd4e0fb7ec8f0fb6c37bb8e1b0a07af80ea5e166285c
sbg:contributors:
- dave
sbg:createdBy: dave
sbg:createdOn: 1624646405
sbg:id: dave/build-mitochondria-pipeline/get-contamination/9
sbg:image_url:
sbg:latestRevision: 9
sbg:modifiedBy: dave
sbg:modifiedOn: 1625072148
sbg:project: dave/build-mitochondria-pipeline
sbg:projectName: 'BUILD: Mitochondria Pipeline'
sbg:publisher: sbg
sbg:revision: 9
sbg:revisionNotes: ''
sbg:revisionsInfo:
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1624646405
  sbg:revision: 0
  sbg:revisionNotes:
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1624646819
  sbg:revision: 1
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1624647344
  sbg:revision: 2
  sbg:revisionNotes: pwd
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1625069316
  sbg:revision: 3
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1625070253
  sbg:revision: 4
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1625070344
  sbg:revision: 5
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1625070603
  sbg:revision: 6
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1625070724
  sbg:revision: 7
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1625071550
  sbg:revision: 8
  sbg:revisionNotes: ./
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1625072148
  sbg:revision: 9
  sbg:revisionNotes: ''
sbg:sbgMaintained: false
sbg:validationErrors: []
