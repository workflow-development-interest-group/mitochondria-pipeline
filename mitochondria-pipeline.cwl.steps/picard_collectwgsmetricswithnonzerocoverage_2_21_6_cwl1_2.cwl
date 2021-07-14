cwlVersion: v1.2
class: CommandLineTool
label: Picard CollectWgsMetricsWithNonZeroCoverage CWL1.0
doc: |-
  **Picard CollectWgsMetricsWithNonZeroCoverage** evaluates the coverage and performance of whole genome sequencing experiments [1].

  *A list of **all inputs and parameters** with corresponding descriptions can be found at the end of the page.*

  ### Common Use Cases

  **Picard CollectWgsMetricsWithNonZeroCoverage** can be used for quality control of WGS data.

  ### Changes Introduced by Seven Bridges

  No significant changes were introduced. 

  ### Common Issues and Important Notes

  * Input  **Input SAM or BAM file** is required and the file should be coordinate sorted. 
  * Input **Reference** is required.

  ### Performance Benchmarking

  Performance of the tool depends on the size of the input alignments file. Analysing 30x (40 GB) and 50x (72.3 GB) coverage WGS BAM files on the default on-demand AWS instances took 2 h 9 min ($0.86) and 3 h 32 min ($1.41), respectively.

  *Cost can be significantly reduced by **spot instance** usage. Visit the [Knowledge Center](https://docs.sevenbridges.com/docs/about-spot-instances) for more details.*  

  ### References

  [1] [Picard documentation](http://broadinstitute.github.io/picard/command-line-overview.html#CollectWgsMetricsWithNonZeroCoverage)
$namespaces:
  sbg: https://sevenbridges.com

requirements:
- class: ShellCommandRequirement
- class: ResourceRequirement
  coresMin: 1
  ramMin: |-
    ${
        if ((inputs.mem_per_job) && (inputs.mem_overhead_per_job))
        {
            return inputs.mem_per_job + inputs.mem_overhead_per_job
        }
        else if (inputs.mem_per_job)
        {
            return inputs.mem_per_job + 128
        }
        else if (inputs.mem_overhead_per_job)
        {
            return 2048 + inputs.mem_overhead_per_job
        }
        else
        {
        return 2048
        }
    }
- class: DockerRequirement
  dockerPull: images.sbgenomics.com/jovana_vranic/picard-2-21-6:1
  dockerImageId: eab0e70b6629
- class: InitialWorkDirRequirement
  listing: []
- class: InlineJavascriptRequirement
  expressionLib:
  - |-
    var updateMetadata = function(file, key, value) {
        file['metadata'][key] = value;
        return file;
    };


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
        }
        if (!Array.isArray(o1)) {
            o1 = setMetadata(o1, commonMetadata)
        } else {
            for (var i = 0; i < o1.length; i++) {
                o1[i] = setMetadata(o1[i], commonMetadata)
            }
        }
        return o1;
    };

    var toArray = function(file) {
        return [].concat(file);
    };

    var groupBy = function(files, key) {
        var groupedFiles = [];
        var tempDict = {};
        for (var i = 0; i < files.length; i++) {
            var value = files[i]['metadata'][key];
            if (value in tempDict)
                tempDict[value].push(files[i]);
            else tempDict[value] = [files[i]];
        }
        for (var key in tempDict) {
            groupedFiles.push(tempDict[key]);
        }
        return groupedFiles;
    };

    var orderBy = function(files, key, order) {
        var compareFunction = function(a, b) {
            if (a['metadata'][key].constructor === Number) {
                return a['metadata'][key] - b['metadata'][key];
            } else {
                var nameA = a['metadata'][key].toUpperCase();
                var nameB = b['metadata'][key].toUpperCase();
                if (nameA < nameB) {
                    return -1;
                }
                if (nameA > nameB) {
                    return 1;
                }
                return 0;
            }
        };

        files = files.sort(compareFunction);
        if (order == undefined || order == "asc")
            return files;
        else
            return files.reverse();
    };
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
        } else {
            for (var i = 0; i < o1.length; i++) {
                o1[i] = setMetadata(o1[i], commonMetadata)
            }
        }
        return o1;
    };

inputs:
- id: chart_output
  label: Output chart file name
  doc: Output chart file name.
  type: string?
  default: 0
  inputBinding:
    prefix: CHART_OUTPUT=
    position: 7
    valueFrom: |-
      ${
          if (self == 0) {
              self = null;
              inputs.chart_output = null
          };


          if (inputs.chart_output) {
              return inputs.chart_output.concat('.pdf')
          } else {
              filename = [].concat(inputs.in_alignments)[0].nameroot
              return filename.concat('.pdf')
          }
      }
    separate: false
    shellQuote: false
  sbg:altPrefix: CHART=
- id: compression_level
  label: Compression level
  doc: |-
    Compression level for all compressed files created (e.g. BAM and GELI). Default value: 5. This option can be set to 'null' to clear the default value.
  type: int?
  inputBinding:
    prefix: COMPRESSION_LEVEL=
    position: 8
    separate: false
    shellQuote: false
  sbg:category: Options
  sbg:toolDefaultValue: '5'
- id: count_unpaired
  label: Count unpaired
  doc: |-
    If option true is selected, unpaired reads and paired reads with one unmapped end will be counted. Possible values: {true, false}.
  type:
  - 'null'
  - name: count_unpaired
    type: enum
    symbols:
    - 'true'
    - 'false'
  inputBinding:
    prefix: COUNT_UNPAIRED=
    position: 4
    separate: false
    shellQuote: false
  sbg:category: Options
  sbg:toolDefaultValue: 'false'
- id: coverage_cap
  label: Coverage cap
  doc: |-
    This option provides a maximum value for base coverage. Bases with coverage exceeding the given coverage value will be treated as they if they had such maximum value.
  type: int?
  inputBinding:
    prefix: COVERAGE_CAP=
    position: 11
    separate: false
    shellQuote: false
  sbg:altPrefix: CAP
  sbg:category: Options
  sbg:toolDefaultValue: '250'
- id: include_bq_histogram
  label: Include base quality histogram
  doc: |-
    This parameter determines whether to include the base quality histogram in the metrics file.  Possible values: {true, false}.
  type:
  - 'null'
  - name: include_bq_histogram
    type: enum
    symbols:
    - 'true'
    - 'false'
  inputBinding:
    prefix: INCLUDE_BQ_HISTOGRAM=
    position: 4
    separate: false
    shellQuote: false
  sbg:category: Options
  sbg:toolDefaultValue: 'false'
- id: in_alignments
  label: Input SAM or BAM file
  doc: |-
    Input SAM or BAM file.  Required. Note: Sort order should be coordinate based and not query name based.
  type: File
  inputBinding:
    prefix: INPUT=
    position: 4
    separate: false
    shellQuote: false
  sbg:altPrefix: I
  sbg:category: File inputs
  sbg:fileTypes: SAM, BAM
- id: intervals
  label: Intervals file
  doc: Intervals file.
  type: File?
  inputBinding:
    prefix: INTERVALS=
    position: 7
    separate: false
    shellQuote: false
  sbg:category: File inputs
  sbg:fileTypes: INTERVAL_LIST
- id: max_records_in_ram
  label: Max records in RAM
  doc: |-
    When writing SAM files that need to be sorted, this parameter will specify the number of records stored in RAM before spilling to disk. Increasing this number reduces the number of file handles needed to sort a SAM file, and increases the amount of RAM needed. Default value: 500000. This option can be set to 'null' to clear the default value.
  type: int?
  inputBinding:
    prefix: MAX_RECORDS_IN_RAM=
    position: 8
    separate: false
    shellQuote: false
  sbg:category: Options
  sbg:toolDefaultValue: '500000'
- id: mem_per_job
  label: Memory per job [MB]
  doc: |-
    Amount of RAM memory to be used per job. Defaults to 2048MB for single threaded jobs.
  type: int?
  sbg:category: Platform options
  sbg:toolDefaultValue: '2048'
- id: minimum_base_quality
  label: Minimum base quality
  doc: Minimum base quality for a base to contribute coverage.
  type: int?
  inputBinding:
    prefix: MINIMUM_BASE_QUALITY=
    position: 11
    separate: false
    shellQuote: false
  sbg:altPrefix: Q
  sbg:category: Options
  sbg:toolDefaultValue: '20'
- id: minimum_mapping_quality
  label: Minimum mapping quality
  doc: Minimum mapping quality for a read to contribute coverage.
  type: int?
  inputBinding:
    prefix: MINIMUM_MAPPING_QUALITY=
    position: 11
    separate: false
    shellQuote: false
  sbg:altPrefix: MQ
  sbg:category: Options
  sbg:toolDefaultValue: '20'
- id: quiet
  label: Quiet
  doc: |-
    Whether to suppress job-summary info on System.err. Default value: false. This option can be set to 'null' to clear the default value. Possible values: {true, false}.
  type:
  - 'null'
  - name: quiet
    type: enum
    symbols:
    - 'true'
    - 'false'
  inputBinding:
    prefix: QUIET=
    position: 8
    separate: false
    shellQuote: false
  sbg:category: Options
  sbg:toolDefaultValue: 'false'
- id: in_reference
  label: Reference
  doc: |-
    The reference sequence in FASTA format to which reads will be aligned.  Required.
  type: File
  inputBinding:
    prefix: REFERENCE_SEQUENCE=
    position: 7
    separate: false
    shellQuote: false
  sbg:altPrefix: R=
  sbg:category: File inputs
  sbg:fileTypes: FASTA, FA, FASTA.GZ
- id: stop_after
  label: Stop after
  doc: |-
    For debugging purposes, stop after processing the given number of genomic bases.  Default value: -1. This option can be set to 'null' to clear the default value.
  type: int?
  inputBinding:
    prefix: STOP_AFTER=
    position: 13
    separate: false
    shellQuote: false
  sbg:category: Options
  sbg:toolDefaultValue: '-1'
- id: validation_stringency
  label: Validation stringency
  doc: |-
    Validation stringency for all SAM files read by this program. Setting stringency to SILENT can improve performance when processing a BAM file in which variable-length data (read, qualities, tags) do not otherwise need to be decoded. Default value: STRICT. This option can be set to 'null' to clear the default value. Possible values: {STRICT, LENIENT, SILENT}.
  type:
  - 'null'
  - name: validation_stringency
    type: enum
    symbols:
    - STRICT
    - LENIENT
    - SILENT
  default: 0
  inputBinding:
    prefix: VALIDATION_STRINGENCY=
    position: 8
    valueFrom: |-
      ${
          if (self == 0) {
              self = null;
              inputs.validation_stringency = null
          };


          if (inputs.validation_stringency) {
              return inputs.validation_stringency
          } else {
              return "SILENT"
          }
      }
    separate: false
    shellQuote: false
  sbg:category: Options
  sbg:toolDefaultValue: SILENT
- id: verbosity
  label: Verbosity
  doc: |-
    Control verbosity of logging. Default value: INFO. This option can be set to 'null' to clear the default value. Possible values: {ERROR, WARNING, INFO, DEBUG}.
  type:
  - 'null'
  - name: verbosity
    type: enum
    symbols:
    - ERROR
    - WARNING
    - INFO
    - DEBUG
  inputBinding:
    prefix: VERBOSITY=
    position: 10
    separate: false
    shellQuote: false
  sbg:category: Options
  sbg:toolDefaultValue: INFO
- id: output_prefix
  label: Output metrics file prefix
  doc: Output metrics file prefix.
  type: string?
  sbg:altPrefix: O
- id: locus_accumulation_cap
  label: Locus accumulation cap
  doc: |-
    At positions with coverage exceeding this value, completely ignore reads that accumulate beyond this value (so that they will not be considered for PCT_EXC_CAPPED).  Used to keep memory consumption in check, but could create bias if set too low.
  type: int?
  inputBinding:
    prefix: LOCUS_ACCUMULATION_CAP=
    position: 10
    separate: false
    shellQuote: false
  sbg:category: Options
  sbg:toolDefaultValue: '100000'
- id: sample_size
  label: Sample size for theoretical het sensitivity sampling
  doc: Sample Size used for theoretical het sensitivity sampling. Default is 10000.
  type: int?
  inputBinding:
    prefix: SAMPLE_SIZE=
    position: 12
    separate: false
    shellQuote: false
  sbg:category: Options
  sbg:toolDefaultValue: '10000'
- id: theoretical_sensitivity_output
  label: Output file name prefix for theoretical sensitivity
  doc: Outpu file namet prefix for theoretical sensitivity metrics.
  type: string?
  inputBinding:
    prefix: THEORETICAL_SENSITIVITY_OUTPUT=
    position: 13
    valueFrom: |-
      ${
          if (self == 0) {
              self = null;
              inputs.theoretical_sensitivity_output = null
          };


          if (inputs.theoretical_sensitivity_output) {
              return inputs.theoretical_sensitivity_output.concat('.ths.txt')
          } else {
              filename = [].concat(inputs.in_alignments)[0].nameroot
              return filename.concat('.ths.txt')
          }
      }
    separate: false
    shellQuote: false
  sbg:category: Options
- id: allele_fraction
  label: Allele fraction for theoretical sensitivity
  doc: |-
    Allele fraction for which to calculate theoretical sensitivity.  Default value: [0.001,
     0.005, 0.01, 0.02, 0.05, 0.1, 0.2, 0.3, 0.5].
  type:
  - 'null'
  - type: array
    inputBinding:
      prefix: ALLELE_FRACTION=
      separate: false
    items: float
  inputBinding:
    prefix: ''
    position: 14
    separate: false
    shellQuote: false
  sbg:category: Options
- id: use_fast_algorithm
  label: Use fast algorithm
  doc: Use fast algorithm.
  type:
  - 'null'
  - name: use_fast_algorithm
    type: enum
    symbols:
    - 'true'
    - 'false'
  inputBinding:
    prefix: USE_FAST_ALGORITHM=
    position: 15
    separate: false
    shellQuote: false
  sbg:category: Options
- id: read_length
  label: Average read length
  doc: Average read length in the file. Default is 150.
  type: int?
  inputBinding:
    prefix: READ_LENGTH=
    position: 16
    separate: false
    shellQuote: false
  sbg:category: Options
  sbg:toolDefaultValue: '150'
- id: mem_overhead_per_job
  label: Memory overhead per job [MB]
  doc: Memory overhead per job [MB].
  type: int?
  sbg:category: Platform Options
  sbg:toolDefaultValue: '128'

outputs:
- id: output_chart
  label: Output chart
  doc: Output chart.
  type: File?
  outputBinding:
    glob: '*.pdf'
    outputEval: "${\n    return inheritMetadata(self, inputs.in_alignments)\n\n}"
  sbg:fileTypes: PDF
- id: wgs_metrics
  label: WGS metrics
  doc: Output metrics file.
  type: File?
  outputBinding:
    glob: '*.wgs_metrics.txt'
    outputEval: $(inheritMetadata(self, inputs.in_alignments))
  sbg:fileTypes: TXT
- id: theoretical_sensitivity_out_file
  label: Theoretical sensitivity output file
  doc: Theoretical sensitivity output file.
  type: File?
  outputBinding:
    glob: '*.ths.txt'
    outputEval: $(inheritMetadata(self, inputs.in_alignments))
  sbg:fileTypes: TXT

baseCommand:
- java
arguments:
- prefix: ''
  position: 0
  valueFrom: |-
    ${
        if (inputs.mem_per_job) {
            return '-Xmx'.concat(inputs.mem_per_job, 'M')
        }
        return '-Xmx2048M'
    }
  shellQuote: false
- position: 1
  valueFrom: -jar
  shellQuote: false
- prefix: ''
  position: 2
  valueFrom: /opt/picard-2.21.6/picard.jar
  shellQuote: false
- position: 3
  valueFrom: CollectWgsMetricsWithNonZeroCoverage
  shellQuote: false
- prefix: OUTPUT=
  position: 4
  valueFrom: |-
    ${
        if (inputs.output_prefix)
        {
            return inputs.output_prefix.concat(".wgs_metrics.txt")
        }
        else if (inputs.in_alignments) {
            filename = [].concat(inputs.in_alignments)[0].nameroot

            return filename.concat(".wgs_metrics.txt")
        }
    }
  separate: false
  shellQuote: false
id: |-
  dave/build-mitochondria-pipeline/picard-collectwgsmetricswithnonzerocoverage-2-21-6-cwl1-0/1
sbg:appVersion:
- v1.2
sbg:categories:
- SAM/BAM-Processing
- Quality-Control
- CWL1.0
sbg:cmdPreview: |-
  java -Xmx2048M -jar /opt/picard.jar CollectWgsMetricsWithNonZeroCoverage INPUT=/root/folder/example.bam OUTPUT=example.wgs_metrics.txt REFERENCE_SEQUENCE=/second/folder/human.fasta
sbg:content_hash: aa7fb123a0b435d3e287ed99cc531fb694bb191bb5ce90c4755504b13cbda1bb1
sbg:contributors:
- dave
sbg:createdBy: dave
sbg:createdOn: 1622863845
sbg:expand_workflow: false
sbg:id: |-
  dave/build-mitochondria-pipeline/picard-collectwgsmetricswithnonzerocoverage-2-21-6-cwl1-0/1
sbg:image_url:
sbg:latestRevision: 1
sbg:license: MIT License
sbg:links:
- id: http://broadinstitute.github.io/picard/
  label: Homepage
- id: https://github.com/broadinstitute/picard/releases/tag/1.140
  label: Source Code
- id: http://broadinstitute.github.io/picard/
  label: Wiki
- id: https://github.com/broadinstitute/picard/zipball/master
  label: Download
- id: http://broadinstitute.github.io/picard/
  label: Publication
sbg:modifiedBy: dave
sbg:modifiedOn: 1622864324
sbg:project: dave/build-mitochondria-pipeline
sbg:projectName: 'BUILD: Mitochondria Pipeline'
sbg:publisher: sbg
sbg:revision: 1
sbg:revisionNotes: ''
sbg:revisionsInfo:
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1622863845
  sbg:revision: 0
  sbg:revisionNotes: |-
    Copy of admin/sbg-public-data/picard-collectwgsmetricswithnonzerocoverage-2-21-6-cwl1-0/3
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1622864324
  sbg:revision: 1
  sbg:revisionNotes: ''
sbg:sbgMaintained: false
sbg:toolAuthor: Broad Institute
sbg:toolkit: Picard
sbg:toolkitVersion: 2.21.6
sbg:validationErrors: []
