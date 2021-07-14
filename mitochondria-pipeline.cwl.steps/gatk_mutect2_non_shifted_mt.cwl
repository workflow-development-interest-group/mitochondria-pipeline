cwlVersion: v1.2
class: CommandLineTool
label: GATK Mutect2 CWL1.0
doc: |-
  **Mutect2** is used to call somatic SNVs and indels via local assembly of haplotypes.

  ###Common Use Cases
  Example commands show how to run Mutect2 for typical scenarios. The three modes are (i) tumor-normal mode where a tumor sample is matched with a normal sample in analysis, (ii) tumor-only mode where a single sample's alignment data undergoes analysis, and (iii) mitochondrial mode where sensitive calling at high depths is desirable.

  - As of v4.1, there is no longer a need to specify the tumor sample name with -tumor. You need only specify the normal sample name with -normal, if you include a normal.

  - Starting with v4.0.4.0, GATK recommends the default setting of --af-of-alleles-not-in-resource, which the tool dynamically adjusts for different modes. tumor-only calling sets the default to 5e-8, tumor-normal calling sets it to 1e-6 and mitochondrial mode sets it to 4e-3. For previous versions, the default was 0.001, the average heterozygosity of humans. For other organisms, change --af-of-alleles-not-in-resource to 1/(ploidy*samples in resource).

  **Tumor with matched normal**
  Given a matched normal, Mutect2 is designed to call somatic variants only. The tool includes logic to skip emitting variants that are clearly present in the germline based on provided evidence, e.g. in the matched normal. This is done at an early stage to avoid spending computational resources on germline events. If the variant's germline status is borderline, then Mutect2 will emit the variant to the callset for subsequent filtering by FilterMutectCalls and review.

  ```
  gatk Mutect2 \
       -R reference.fa \
       -I tumor.bam \
       -I normal.bam \
       -normal normal_sample_name \
       --germline-resource af-only-gnomad.vcf.gz \
       --panel-of-normals pon.vcf.gz \
       -O somatic.vcf.gz
  ```

  Mutect2 also generates a stats file names [output vcf].stats. That is, in the above example the stats file would be named somatic.vcf.gz.stats and would be in the same folder as somatic.vcf.gz. As of GATK 4.1.1 this file is a required input to FilterMutectCalls.
  - As of v4.1 Mutect2 supports joint calling of multiple tumor and normal samples from the same individual. The only difference is that -I and -normal must be specified for the extra samples.
  ```
   gatk Mutect2 \
       -R reference.fa \
       -I tumor1.bam \
       -I tumor2.bam \
       -I normal1.bam \
       -I normal2.bam \
       -normal normal1_sample_name \
       -normal normal2_sample_name \
       --germline-resource af-only-gnomad.vcf.gz \
       --panel-of-normals pon.vcf.gz \
       -O somatic.vcf.gz
  ```
  **Tumor-only mode**
  This mode runs on a single type of sample, e.g. the tumor or the normal. To create a PoN, call on each normal sample in this mode, then use CreateSomaticPanelOfNormals to generate the PoN.
  ```
    gatk Mutect2 \
         -R reference.fa \
         -I sample.bam \
         -O single_sample.vcf.gz
  ```
  To call mutations on a tumor sample, call in this mode using a PoN and germline resource. After FilterMutectCalls filtering, consider additional filtering by functional significance with Funcotator.
  ```
    gatk Mutect2 \
         -R reference.fa \
         -I sample.bam \
         --germline-resource af-only-gnomad.vcf.gz \
         --panel-of-normals pon.vcf.gz \
         -O single_sample.vcf.gz
  ```
  **Mitochondrial mode**
  Mutect2 automatically sets parameters appropriately for calling on mitochondria with the --mitochondria flag. Specifically, the mode sets –-initial-tumor-lod to 0, –-tumor-lod-to-emit to 0, --af-of-alleles-not-in-resource to 4e-3, and the advanced parameter --pruning-lod-threshold to -4.
  ```
  gatk Mutect2 \
       -R reference.fa \
       -L chrM \
       --mitochondria \
       --median-autosomal-coverage 30 \
       -I mitochondria.bam \
       -O mitochondria.vcf.gz
  ```
  Setting the advanced option --median-autosomal-coverage argument (default 0) activates a recommended filter against likely erroneously mapped NuMTs (nuclear mitochondrial DNA segments). For the value, provide the median coverage expected in autosomal regions with coverage. The mode accepts only a single sample, which can be provided in multiple files.

  **Force-calling mode**
  This mode force-calls all alleles in force-call-alleles.vcf in addition to any other variants Mutect2 discovers.
  ```
  gatk Mutect2 \
       -R reference.fa \
       -I sample.bam \
       -alleles force-call-alleles.vcf
       -O single_sample.vcf.gz
  ```
  If the sample is suspected to exhibit orientation bias artifacts (such as in the case of FFPE tumor samples) one should also collect F1R2 metrics by adding an --f1r2-tar-gz argument as shown below. This file contains information that can then be passed to LearnReadOrientationModel, which generate an artifact prior table for each tumor sample for FilterMutectCalls to use.

  ```
   gatk Mutect2 \
       -R reference.fa \
       -I sample.bam \
       --f1r2-tar-gz f1r2.tar.gz \
       -O single_sample.vcf.gz
  ```

  ###Changes Introduced by Seven Bridges
  - **Output filename** (`--output`)  parameter, if not provided explicitly, will be generated automatically based on other inputs. Namely, if **Tumor sample** and **Normal sample** are provided, they will be used to generate the output name; if not provided input file names will be used.
  - String array argument **Extra Arguments** has been added for ease of use in certain workflows.

  ###Common Issues and Important Notes
  None
  ###Performance Benchmarking
$namespaces:
  sbg: https://sevenbridges.com

requirements:
- class: ShellCommandRequirement
- class: ResourceRequirement
  coresMin: |-
    ${
        var cpus = 1;
        if (inputs.cpu_per_job){
            cpus = inputs.cpu_per_job;
        }
        return cpus;
    }
  ramMin: |-
    ${
        var memory = 7500;
        if (inputs.mem_per_job){
            memory = inputs.mem_per_job;
        }
        var overhead = 500;
        if (inputs.mem_overhead_per_job || inputs.mem_overhead_per_job == 0){
            overhead = inputs.mem_overhead_per_job;
        }
        return memory + overhead;
    }
- class: DockerRequirement
  dockerPull: images.sbgenomics.com/pavle.marinkovic/gatk_4-1-9-0:0
- class: InitialWorkDirRequirement
  listing: []
- class: InlineJavascriptRequirement

inputs:
- id: in_alignments
  label: Input
  doc: |-
    BAM/SAM/CRAM file containing reads this argument must be specified at least once.
  type: File
  secondaryFiles:
  - pattern: .bai
  inputBinding:
    prefix: --input
    position: 3
    shellQuote: false
  sbg:altPrefix: -I
  sbg:category: Required Arguments
  sbg:fileTypes: BAM
- id: output_filename
  label: Output File Name
  doc: File to which variants should be written.
  type: string?
  sbg:altPrefix: -O
  sbg:category: Required Arguments
- id: in_reference_and_index
  label: Reference FASTA and index
  doc: Reference FASTA or FA sequence file and associated index and dict.
  type: File
  secondaryFiles:
  - pattern: .fai
    required: true
  - pattern: ^.dict
    required: true
  inputBinding:
    prefix: --reference
    position: 4
    shellQuote: false
  sbg:altPrefix: -R
  sbg:category: Required Arguments
  sbg:fileTypes: FASTA, FA
- id: activity_profile_out
  label: Activity profile out
  doc: Output the raw activity profile results in igv format.
  type: string?
  inputBinding:
    prefix: --activity-profile-out
    position: 4
    shellQuote: false
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: 'null'
- id: add_output_sam_program_record
  label: Add output sam program record
  doc: If true, adds a pg tag to created sam/bam/cram files.
  type:
  - 'null'
  - name: add_output_sam_program_record
    type: enum
    symbols:
    - 'true'
    - 'false'
  inputBinding:
    prefix: --add-output-sam-program-record
    position: 4
    shellQuote: false
  sbg:altPrefix: -add-output-sam-program-record
  sbg:category: Optional Common Arguments
  sbg:toolDefaultValue: 'true'
- id: add_output_vcf_command_line
  label: Add output vcf command line
  doc: If true, adds a command line header line to created vcf files.
  type:
  - 'null'
  - name: add_output_vcf_command_line
    type: enum
    symbols:
    - 'true'
    - 'false'
  inputBinding:
    prefix: --add-output-vcf-command-line
    position: 4
    shellQuote: false
  sbg:altPrefix: -add-output-vcf-command-line
  sbg:category: Optional Common Arguments
  sbg:toolDefaultValue: 'true'
- id: af_of_alleles_not_in_resource
  label: Af of alleles not in resource
  doc: |-
    Population allele fraction assigned to alleles not found in germline resource. Please see docs/mutect/mutect2.pdf fora derivation of the default value. 0.
    Population allele fraction assigned to alleles not found in germline resource.
  type: float?
  inputBinding:
    prefix: --af-of-alleles-not-in-resource
    position: 4
    shellQuote: false
  sbg:altPrefix: -default-af
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: '-1'
- id: alleles
  label: Alleles
  doc: The set of alleles for which to force genotyping regardless of evidence.
  type: File?
  secondaryFiles:
  - pattern: |-
      ${
          if (self.nameext == ".vcf")
          {
              return self.basename + ".idx";
          }
          else
          {
              return self.basename + ".tbi";
          }
      }
  inputBinding:
    prefix: --alleles
    position: 4
    shellQuote: false
  sbg:category: Optional Tool Arguments
  sbg:fileTypes: VCF, VCF.GZ
  sbg:toolDefaultValue: 'null'
- id: annotation
  label: Annotation
  doc: One or more specific annotations to add to variant calls.
  type:
  - 'null'
  - type: array
    items:
      name: annotation
      type: enum
      symbols:
      - AlleleFraction
      - AS_BaseQualityRankSumTest
      - AS_FisherStrand
      - AS_InbreedingCoeff
      - AS_MappingQualityRankSumTest
      - AS_QualByDepth
      - AS_ReadPosRankSumTest
      - AS_RMSMappingQuality
      - AS_StrandOddsRatio
      - BaseQuality
      - BaseQualityRankSumTest
      - ChromosomeCounts
      - ClippingRankSumTest
      - CountNs
      - Coverage
      - DepthPerAlleleBySample
      - DepthPerSampleHC
      - ExcessHet
      - FisherStrand
      - FragmentLength
      - GenotypeSummaries
      - InbreedingCoeff
      - LikelihoodRankSumTest
      - MappingQuality
      - MappingQualityRankSumTest
      - MappingQualityZero
      - OrientationBiasReadCounts
      - OriginalAlignment
      - PossibleDeNovo
      - QualByDepth
      - ReadPosition
      - ReadPosRankSumTest
      - ReferenceBases
      - RMSMappingQuality
      - SampleList
      - StrandBiasBySample
      - StrandOddsRatio
      - TandemRepeat
      - UniqueAltReadCount
  inputBinding:
    prefix: ''
    position: 4
    valueFrom: |-
      ${
          var output = "";
          for (var i=0; i<inputs.annotation.length; i++)
          {
              output = output + "--annotation " + inputs.annotation[i] + " ";
          }
          return output;
      }
    itemSeparator: ' '
    shellQuote: false
  sbg:altPrefix: -A
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: 'null'
- id: annotation_group
  label: Annotation group
  doc: One or more groups of annotations to apply to variant calls.
  type:
  - 'null'
  - type: array
    items:
      name: annotation_group
      type: enum
      symbols:
      - AS_StandardAnnotation
      - ReducibleAnnotation
      - StandardAnnotation
      - StandardHCAnnotation
      - StandardMutectAnnotation
  inputBinding:
    prefix: ''
    position: 4
    valueFrom: |-
      ${
          var output = "";
          for (var i=0; i<inputs.annotation_group.length; i++)
          {
              output = output + "--annotation-group " + inputs.annotation_group[i] + " ";
          }
          return output;
      }
    shellQuote: false
  sbg:altPrefix: -G
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: 'null'
- id: annotations_to_exclude
  label: Annotations to exclude
  doc: One or more specific annotations to exclude from variant calls.
  type:
  - 'null'
  - type: array
    items:
      name: annotations_to_exclude
      type: enum
      symbols:
      - BaseQuality
      - Coverage
      - DepthPerAlleleBySample
      - DepthPerSampleHC
      - FragmentLength
      - MappingQuality
      - OrientationBiasReadCounts
      - ReadPosition
      - StrandBiasBySample
      - TandemRepeat
  inputBinding:
    prefix: ''
    position: 4
    valueFrom: |-
      ${
          var output = "";
          for (var i=0; i<inputs.annotations_to_exclude.length; i++)
          {
              output = output + "--annotations-to-exclude " + inputs.annotations_to_exclude[i] + " ";
          }
          return output;
      }
    shellQuote: false
  sbg:altPrefix: -AX
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: 'null'
- id: arguments_file
  label: Arguments file
  doc: Read one or more arguments files and add them to the command line.
  type: File[]?
  inputBinding:
    prefix: ''
    position: 4
    valueFrom: |-
      ${
          var output = "";
          for (var i=0; i<inputs.arguments_file.length; i++)
          {
              output = output + "--arguments_file " + inputs.arguments_file[i].path + " ";
          }
          return output;
      }
    shellQuote: false
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: 'null'
- id: assembly_region_out
  label: Assembly region out
  doc: Output the assembly region to this igv formatted file.
  type: string?
  inputBinding:
    prefix: --assembly-region-out
    position: 4
    shellQuote: false
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: 'null'
- id: base_quality_score_threshold
  label: Base quality score threshold
  doc: Base qualities below this threshold will be reduced to the minimum (6).
  type: int?
  inputBinding:
    prefix: --base-quality-score-threshold
    position: 4
    shellQuote: false
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: '18'
- id: callable_depth
  label: Callable depth
  doc: |-
    Minimum depth to be considered callable for mutect stats. Does not affect genotyping.
  type: int?
  inputBinding:
    prefix: --callable-depth
    position: 4
    shellQuote: false
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: '10'
- id: cloud_index_prefetch_buffer
  label: Cloud index prefetch buffer
  doc: |-
    Size of the cloud-only prefetch buffer (in mb; 0 to disable). Defaults to cloudprefetchbuffer if unset.
  type: int?
  inputBinding:
    prefix: --cloud-index-prefetch-buffer
    position: 4
    shellQuote: false
  sbg:altPrefix: -CIPB
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: '-1'
- id: cloud_prefetch_buffer
  label: Cloud prefetch buffer
  doc: Size of the cloud-only prefetch buffer (in mb; 0 to disable).
  type: int?
  inputBinding:
    prefix: --cloud-prefetch-buffer
    position: 4
    shellQuote: false
  sbg:altPrefix: -CPB
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: '40'
- id: create_output_bam_index
  label: Create output bam index
  doc: If true, create a bam/cram index when writing a coordinate-sorted bam/cram
    file.
  type: boolean?
  inputBinding:
    prefix: --create-output-bam-index
    position: 4
    shellQuote: false
  sbg:altPrefix: -OBI
  sbg:category: Optional Common Arguments
  sbg:toolDefaultValue: 'true'
- id: create_output_bam_md5
  label: Create output bam md5
  doc: If true, create a md5 digest for any BAM/SAM/CRAM file created.
  type: boolean?
  inputBinding:
    prefix: --create-output-bam-md5
    position: 4
    shellQuote: false
  sbg:altPrefix: -OBM
  sbg:category: Optional Common Arguments
  sbg:toolDefaultValue: 'false'
- id: create_output_variant_index
  label: Create output variant index
  doc: If true, create a vcf index when writing a coordinate-sorted vcf file.
  type: boolean?
  inputBinding:
    prefix: --create-output-variant-index
    position: 4
    shellQuote: false
  sbg:altPrefix: -OVI
  sbg:category: Optional Common Arguments
  sbg:toolDefaultValue: 'true'
- id: create_output_variant_md5
  label: Create output variant md5
  doc: If true, create a a md5 digest any vcf file created.
  type: boolean?
  inputBinding:
    prefix: --create-output-variant-md5
    position: 4
    shellQuote: false
  sbg:altPrefix: -OVM
  sbg:category: Optional Common Arguments
  sbg:toolDefaultValue: 'false'
- id: disable_bam_index_caching
  label: Disable bam index caching
  doc: |-
    If true, don't cache bam indexes, this will reduce memory requirements but may harm performance if many intervals are specified. Caching is automatically disabled if there are no intervals specified.
  type: boolean?
  inputBinding:
    prefix: --disable-bam-index-caching
    position: 4
    shellQuote: false
  sbg:altPrefix: -DBIC
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: 'false'
- id: disable_read_filter
  label: Disable read filter
  doc: Read filters to be disabled before analysis.
  type:
  - 'null'
  - type: array
    items:
      name: disable_read_filter
      type: enum
      symbols:
      - GoodCigarReadFilter
      - MappedReadFilter
      - MappingQualityAvailableReadFilter
      - MappingQualityNotZeroReadFilter
      - MappingQualityReadFilter
      - NonChimericOriginalAlignmentReadFilter
      - NonZeroReferenceLengthAlignmentReadFilter
      - NotDuplicateReadFilter
      - NotSecondaryAlignmentReadFilter
      - PassesVendorQualityCheckReadFilter
      - ReadLengthReadFilter
      - WellformedReadFilter
  inputBinding:
    prefix: ''
    position: 4
    valueFrom: |-
      ${
          var output = "";
          for (var i=0; i<inputs.disable_read_filter.length; i++)
          {
              output = output + "--disable-read-filter " + inputs.disable_read_filter[i] + " ";
          }
          return output;
      }
    shellQuote: false
  sbg:altPrefix: -DF
  sbg:category: Optional Common Arguments
  sbg:toolDefaultValue: 'null'
- id: disable_sequence_dictionary_validation
  label: Disable sequence dictionary validation
  doc: |-
    If specified, do not check the sequence dictionaries from our inputs for compatibility. Use at your own risk!
  type: boolean?
  inputBinding:
    prefix: --disable-sequence-dictionary-validation
    position: 4
    shellQuote: false
  sbg:altPrefix: -disable-sequence-dictionary-validation
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: 'false'
- id: downsampling_stride
  label: Downsampling stride
  doc: Downsample a pool of reads starting within a range of one or more bases.
  type: int?
  inputBinding:
    prefix: --downsampling-stride
    position: 4
    shellQuote: false
  sbg:altPrefix: -stride
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: '1'
- id: exclude_intervals
  label: Exclude intervals
  doc: Or more genomic intervals to exclude from processing.
  type: string[]?
  inputBinding:
    prefix: ''
    position: 4
    valueFrom: |-
      ${
          var output = "";
          for (var i=0; i<inputs.exclude_intervals.length; i++)
          {
              output = output + "--exclude-intervals " + inputs.exclude_intervals[i] + " ";
          }
          return output;
      }
    shellQuote: false
  sbg:altPrefix: -XL
  sbg:category: Optional Common Arguments
  sbg:toolDefaultValue: 'null'
- id: f1r2_max_depth
  label: F1r2 max depth
  doc: Sites with depth higher than this value will be grouped.
  type: int?
  inputBinding:
    prefix: --f1r2-max-depth
    position: 4
    shellQuote: false
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: '200'
- id: f1r2_median_mq
  label: F1r2 median mq
  doc: Skip sites with median mapping quality below this value.
  type: int?
  inputBinding:
    prefix: --f1r2-median-mq
    position: 4
    shellQuote: false
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: '50'
- id: f1r2_min_bq
  label: F1r2 min bq
  doc: Exclude bases below this quality from pileup.
  type: int?
  inputBinding:
    prefix: --f1r2-min-bq
    position: 4
    shellQuote: false
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: '20'
- id: f1r2_tar_gz
  label: F1r2 filename
  doc: If specified, collect f1r2 counts and output files into this tar.gz file.
  type: string?
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: 'null'
- id: founder_id
  label: Founder id
  doc: Samples representing the population "founders".
  type: string[]?
  inputBinding:
    prefix: ''
    position: 4
    valueFrom: |-
      ${
          var output = "";
          for (var i=0; i<inputs.founder_id.length; i++)
          {
              output = output + "--founder-id " + inputs.founder_id[i] + " ";
          }
          return output;
      }
    shellQuote: false
  sbg:altPrefix: -founder-id
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: 'null'
- id: gatk_config_file
  label: Gatk config file
  doc: A configuration file to use with the gatk.
  type: File?
  inputBinding:
    prefix: --gatk-config-file
    position: 4
    shellQuote: false
  sbg:category: Optional Common Arguments
  sbg:toolDefaultValue: 'null'
- id: gcs_max_retries
  label: Gcs max retries
  doc: |-
    If the gcs bucket channel errors out, how many times it will attempt to re-initiate the connection.
  type: int?
  inputBinding:
    prefix: --gcs-max-retries
    position: 4
    shellQuote: false
  sbg:altPrefix: -gcs-retries
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: '20'
- id: gcs_project_for_requester_pays
  label: Gcs project for requester pays
  doc: |-
    Project to bill when accessing "requester pays" buckets. If unset, these buckets cannot be accessed. Default value: .
  type: string?
  inputBinding:
    prefix: --gcs-project-for-requester-pays
    position: 4
    shellQuote: false
  sbg:category: Optional Tool Arguments
- id: genotype_germline_sites
  label: Genotype germline sites
  doc: |-
    (experimental) call all apparent germline site even though they will ultimately be filtered.
  type: boolean?
  inputBinding:
    prefix: --genotype-germline-sites
    position: 4
    shellQuote: false
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: 'false'
- id: genotype_pon_sites
  label: Genotype pon sites
  doc: Call sites in the pon even though they will ultimately be filtered.
  type: boolean?
  inputBinding:
    prefix: --genotype-pon-sites
    position: 4
    shellQuote: false
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: 'false'
- id: germline_resource
  label: Germline resource
  doc: |-
    Population vcf of germline sequencing containing allele fractions. (typically gNOMAD)
  type: File?
  secondaryFiles:
  - pattern: |-
      ${
          if (self.nameext == ".vcf")
          {
              return self.basename + ".idx";
          }
          else
          {
              return self.basename + ".tbi";
          }
      }
  inputBinding:
    prefix: --germline-resource
    position: 4
    shellQuote: false
  sbg:category: Optional Tool Arguments
  sbg:fileTypes: VCF, VCF.GZ
  sbg:toolDefaultValue: 'null'
- id: graph_output
  label: Graph output
  doc: Write debug assembly graph information to this file.
  type: string?
  inputBinding:
    prefix: --graph-output
    position: 4
    shellQuote: false
  sbg:altPrefix: -graph
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: 'null'
- id: ignore_itr_artifacts
  label: Ignore itr artifacts
  doc: |-
    Off read transformer that clips artifacts associated with end repair insertions near inverted tandem repeats.
  type: boolean?
  inputBinding:
    prefix: --ignore-itr-artifacts
    position: 4
    shellQuote: false
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: 'false'
- id: initial_tumor_lod
  label: Initial tumor lod
  doc: Log 10 odds threshold to consider pileup active. 0.
  type: float?
  inputBinding:
    prefix: --initial-tumor-lod
    position: 4
    shellQuote: false
  sbg:altPrefix: -init-lod
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: '2.0'
- id: interval_exclusion_padding
  label: Interval exclusion padding
  doc: Amount of padding (in bp) to add to each interval you are excluding.
  type: int?
  inputBinding:
    prefix: --interval-exclusion-padding
    position: 4
    shellQuote: false
  sbg:altPrefix: -ixp
  sbg:category: Optional Common Arguments
  sbg:toolDefaultValue: '0'
- id: interval_merging_rule
  label: Interval merging rule
  doc: Interval merging rule for abutting intervals.
  type:
  - 'null'
  - name: interval_merging_rule
    type: enum
    symbols:
    - ALL
    - OVERLAPPING_ONLY
  inputBinding:
    prefix: --interval-merging-rule
    position: 4
    shellQuote: false
  sbg:altPrefix: -imr
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: ALL
- id: interval_padding
  label: Interval padding
  doc: Of padding (in bp) to add to each interval you are including.
  type: int?
  inputBinding:
    prefix: --interval-padding
    position: 4
    shellQuote: false
  sbg:altPrefix: -ip
  sbg:category: Optional Common Arguments
  sbg:toolDefaultValue: '0'
- id: interval_set_rule
  label: Interval set rule
  doc: Set merging approach to use for combining interval inputs.
  type:
  - 'null'
  - name: interval_set_rule
    type: enum
    symbols:
    - UNION
    - INTERSECTION
  inputBinding:
    prefix: --interval-set-rule
    position: 4
    shellQuote: false
  sbg:altPrefix: -isr
  sbg:category: Optional Common Arguments
  sbg:toolDefaultValue: UNION
- id: intervals
  label: Intervals
  doc: One or more genomic intervals over which to operate.
  type: string[]?
  inputBinding:
    prefix: ''
    position: 4
    valueFrom: |-
      ${
          var output = "";
          for (var i=0; i<inputs.intervals.length; i++){
              output += " --intervals " + inputs.intervals[i];
          }
          return output;
      }
    shellQuote: false
  sbg:altPrefix: -L
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: 'null'
- id: lenient
  label: Lenient
  doc: Lenient processing of vcf files.
  type: boolean?
  inputBinding:
    prefix: --lenient
    position: 4
    shellQuote: false
  sbg:altPrefix: -LE
  sbg:category: Optional Common Arguments
  sbg:toolDefaultValue: 'false'
- id: max_population_af
  label: Max population af
  doc: Maximum population allele frequency in tumor-only mode. 01.
  type: float?
  inputBinding:
    prefix: --max-population-af
    position: 4
    shellQuote: false
  sbg:altPrefix: -max-af
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: '0.01'
- id: max_reads_per_alignment_start
  label: Max reads per alignment start
  doc: |-
    Maximum number of reads to retain per alignment start position. Reads above this threshold will be downsampled. Set to 0 to disable.
  type: int?
  inputBinding:
    prefix: --max-reads-per-alignment-start
    position: 4
    shellQuote: false
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: '50'
- id: min_base_quality_score
  label: Min base quality score
  doc: Minimum base quality required to consider a base for calling.
  type: string?
  inputBinding:
    prefix: --min-base-quality-score
    position: 4
    shellQuote: false
  sbg:altPrefix: -mbq
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: '10'
- id: mitochondria_mode
  label: Mitochondria mode
  doc: Mitochondria mode sets emission and initial lods to 0.
  type: boolean?
  inputBinding:
    prefix: --mitochondria-mode
    position: 4
    shellQuote: false
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: 'false'
- id: native_pair_hmm_threads
  label: Native pair hmm threads
  doc: How many threads should a native pairhmm implementation use.
  type: int?
  inputBinding:
    prefix: --native-pair-hmm-threads
    position: 4
    shellQuote: false
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: '4'
- id: native_pair_hmm_use_double_precision
  label: Native pair hmm use double precision
  doc: |-
    Use double precision in the native pairhmm. This is slower but matches the java implementation better.
  type: boolean?
  inputBinding:
    prefix: --native-pair-hmm-use-double-precision
    position: 4
    shellQuote: false
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: 'false'
- id: normal_lod
  label: Normal lod
  doc: Log 10 odds threshold for calling normal variant non-germline. 2.
  type: float?
  inputBinding:
    prefix: --normal-lod
    position: 4
    shellQuote: false
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: '2.2'
- id: normal_sample
  label: Normal sample
  doc: |-
    Sample name of normal(s), if any. May be url-encoded as output by getsamplename with -encode argument.
  type:
  - 'null'
  - type: array
    items:
    - string
    - 'null'
  inputBinding:
    position: 4
    valueFrom: |-
      ${
          var output = "";
          var normal_samples = [].concat(self);
          for (var i=0; i<normal_samples.length; i++)
          {
              if (normal_samples[i])
              {
                  output = output + '--normal-sample "' 
                          + normal_samples[i] + '" ';   
              }
          }
          return output;
      }
    shellQuote: false
  sbg:altPrefix: -normal
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: 'null'
- id: panel_of_normals
  label: Panel of normals
  doc: Vcf file of sites observed in normal.
  type: File?
  secondaryFiles:
  - pattern: |-
      ${
          if (self.nameext == ".vcf")
          {
              return self.basename + ".idx";
          }
          else
          {
              return self.basename + ".tbi";
          }
      }
  inputBinding:
    prefix: --panel-of-normals
    position: 4
    shellQuote: false
  sbg:altPrefix: -pon
  sbg:category: Optional Tool Arguments
  sbg:fileTypes: VCF, VCF.GZ
  sbg:toolDefaultValue: 'null'
- id: pcr_indel_qual
  label: Pcr indel qual
  doc: Phred-scaled pcr snv qual for overlapping fragments.
  type: int?
  inputBinding:
    prefix: --pcr-indel-qual
    position: 4
    shellQuote: false
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: '40'
- id: pcr_snv_qual
  label: Pcr snv qual
  doc: Phred-scaled pcr snv qual for overlapping fragments.
  type: int?
  inputBinding:
    prefix: --pcr-snv-qual
    position: 4
    shellQuote: false
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: '40'
- id: pedigree
  label: Pedigree
  doc: Pedigree file for determining the population "founders".
  type: File?
  inputBinding:
    prefix: --pedigree
    position: 4
    shellQuote: false
  sbg:altPrefix: -ped
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: 'null'
- id: read_filter
  label: Read filter
  doc: Read filters to be applied before analysis.
  type:
  - 'null'
  - type: array
    items:
      name: read_filter
      type: enum
      symbols:
      - AlignmentAgreesWithHeaderReadFilter
      - AllowAllReadsReadFilter
      - AmbiguousBaseReadFilter
      - CigarContainsNoNOperator
      - FirstOfPairReadFilter
      - FragmentLengthReadFilter
      - GoodCigarReadFilter
      - HasReadGroupReadFilter
      - IntervalOverlapReadFilter
      - LibraryReadFilter
      - MappedReadFilter
      - MappingQualityAvailableReadFilter
      - MappingQualityNotZeroReadFilter
      - MappingQualityReadFilter
      - MatchingBasesAndQualsReadFilter
      - MateDifferentStrandReadFilter
      - MateOnSameContigOrNoMappedMateReadFilter
      - MateUnmappedAndUnmappedReadFilter
      - MetricsReadFilter
      - NonChimericOriginalAlignmentReadFilter
      - NonZeroFragmentLengthReadFilter
      - NonZeroReferenceLengthAlignmentReadFilter
      - NotDuplicateReadFilter
      - NotOpticalDuplicateReadFilter
      - NotSecondaryAlignmentReadFilter
      - NotSupplementaryAlignmentReadFilter
      - OverclippedReadFilter
      - PairedReadFilter
      - PassesVendorQualityCheckReadFilter
      - PlatformReadFilter
      - PlatformUnitReadFilter
      - PrimaryLineReadFilter
      - ProperlyPairedReadFilter
      - ReadGroupBlackListReadFilter
      - ReadGroupReadFilter
      - ReadLengthEqualsCigarLengthReadFilter
      - ReadLengthReadFilter
      - ReadNameReadFilter
      - ReadStrandFilter
      - SampleReadFilter
      - SecondOfPairReadFilter
      - SeqIsStoredReadFilter
      - ValidAlignmentEndReadFilter
      - ValidAlignmentStartReadFilter
      - WellformedReadFilter
  inputBinding:
    prefix: ''
    position: 4
    valueFrom: |-
      ${
          var output = "";
          for (var i=0; i<inputs.read_filter.length; i++)
          {
              output = output + "--read-filter " + inputs.read_filter[i] + " ";
          }
          return output;
      }
    shellQuote: false
  sbg:altPrefix: -RF
  sbg:category: Optional Common Arguments
  sbg:toolDefaultValue: 'null'
- id: read_index
  label: Read index
  doc: |-
    Indices to use for the read inputs. If specified, an index must be provided for every read input and in the same order as the read inputs. If this argument is not specified, the path to the index for each input will be inferred automatically.
  type: File[]?
  inputBinding:
    prefix: --read-index
    position: 4
    valueFrom: |-
      ${
          var output = "";
          for (var i=0; i<inputs.read_index.length; i++)
          {
              output = output + "--read-index " + inputs.read_index[i].path + " ";
          }
          return output;
      }
    shellQuote: false
  sbg:altPrefix: -read-index
  sbg:category: Optional Common Arguments
  sbg:toolDefaultValue: 'null'
- id: read_validation_stringency
  label: Read validation stringency
  doc: |-
    Validation stringency for all sam/bam/cram/sra files read by this program. The default stringency value silent can improve performance when processing a bam file in which variable-length data (read, qualities, tags) do not otherwise need to be decoded.
  type:
  - 'null'
  - name: read_validation_stringency
    type: enum
    symbols:
    - STRICT
    - LENIENT
    - SILENT
  inputBinding:
    prefix: --read-validation-stringency
    position: 4
    shellQuote: false
  sbg:altPrefix: -VS
  sbg:category: Optional Common Arguments
  sbg:toolDefaultValue: SILENT
- id: seconds_between_progress_updates
  label: Seconds between progress updates
  doc: Output traversal statistics every time this many seconds elapse 0.
  type: float?
  inputBinding:
    prefix: --seconds-between-progress-updates
    position: 4
    shellQuote: false
  sbg:altPrefix: -seconds-between-progress-updates
  sbg:category: Optional Common Arguments
  sbg:toolDefaultValue: '10.0'
- id: sequence_dictionary
  label: Sequence dictionary
  doc: |-
    Use the given sequence dictionary as the master/canonical sequence dictionary. Must be a .dict file.
  type: File?
  inputBinding:
    prefix: --sequence-dictionary
    position: 4
    valueFrom: |-
      ${
          if (self){
              self = [].concat(self)[0];
              if (self.nameext != ".dict" && self.secondaryFiles && self.secondaryFiles[0]){
                  for (var i = 0; i < self.secondaryFiles.length; i ++){
                      if (self.secondaryFiles[i].nameext == '.dict'){
                          return self.secondaryFiles[i].path;
                      }
                  }
              }
              return self.path;
          } else {
              return null;
          }
      }
    shellQuote: false
  sbg:altPrefix: -sequence-dictionary
  sbg:category: Optional Common Arguments
  sbg:fileTypes: DICT
  sbg:toolDefaultValue: 'null'
- id: sites_only_vcf_output
  label: Sites only vcf output
  doc: If true, don't emit genotype fields when writing vcf file output.
  type: boolean?
  inputBinding:
    prefix: --sites-only-vcf-output
    position: 4
    shellQuote: false
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: 'false'
- id: tumor_lod_to_emit
  label: Tumor lod to emit
  doc: Log 10 odds threshold to emit variant to vcf. 0.
  type: float?
  inputBinding:
    prefix: --tumor-lod-to-emit
    position: 4
    shellQuote: false
  sbg:altPrefix: -emit-lod
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: 3,0
- id: tumor_sample
  label: Tumor sample
  doc: |-
    Bam sample name of tumor. May be url-encoded as output by getsamplename with -encode argument.
  type: string?
  inputBinding:
    prefix: --tumor-sample
    position: 4
    valueFrom: "${\n    return '\"' + self + '\"';\n}"
    shellQuote: false
  sbg:altPrefix: -tumor
  sbg:category: Deprecated Arguments
  sbg:toolDefaultValue: 'null'
- id: use_jdk_deflater
  label: Use jdk deflater
  doc: Whether to use the jdkdeflater (as opposed to inteldeflater).
  type: boolean?
  inputBinding:
    prefix: --use-jdk-deflater
    position: 4
    shellQuote: false
  sbg:altPrefix: -jdk-deflater
  sbg:category: Optional Common Arguments
  sbg:toolDefaultValue: 'false'
- id: use_jdk_inflater
  label: Use jdk inflater
  doc: Whether to use the jdkinflater (as opposed to intelinflater).
  type: boolean?
  inputBinding:
    prefix: --use-jdk-inflater
    position: 4
    shellQuote: false
  sbg:altPrefix: -jdk-inflater
  sbg:category: Optional Common Arguments
  sbg:toolDefaultValue: 'false'
- id: verbosity
  label: Verbosity
  doc: Control verbosity of logging.
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
    prefix: --verbosity
    position: 4
    shellQuote: false
  sbg:altPrefix: -verbosity
  sbg:category: Optional Common Arguments
  sbg:toolDefaultValue: INFO
- id: active_probability_threshold
  label: Active probability threshold
  doc: Minimum probability for a locus to be considered active. 002.
  type: float?
  inputBinding:
    prefix: --active-probability-threshold
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: '0'
- id: adaptive_pruning_initial_error_rate
  label: Adaptive pruning initial error rate
  doc: Initial base error rate estimate for adaptive pruning 001.
  type: float?
  inputBinding:
    prefix: --adaptive-pruning-initial-error-rate
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: '0'
- id: allow_non_unique_kmers_in_ref
  label: Allow non unique kmers in ref
  doc: Allow graphs that have non-unique kmers in the reference.
  type: boolean?
  inputBinding:
    prefix: --allow-non-unique-kmers-in-ref
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: 'false'
- id: assembly_region_padding
  label: Assembly region padding
  doc: Number of additional bases of context to include around each assembly region.
  type: int?
  inputBinding:
    prefix: --assembly-region-padding
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: '100'
- id: bam_writer_type
  label: Bam writer type
  doc: Which haplotypes should be written to the bam.
  type:
  - 'null'
  - name: bam_writer_type
    type: enum
    symbols:
    - ALL_POSSIBLE_HAPLOTYPES
    - CALLED_HAPLOTYPES
  inputBinding:
    prefix: --bam-writer-type
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: CALLED_HAPLOTYPES
- id: debug_assembly
  label: Debug assembly
  doc: Print out verbose debug information about each assembly region.
  type: boolean?
  inputBinding:
    prefix: --debug-assembly
    position: 4
    shellQuote: false
  sbg:altPrefix: -debug
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: 'false'
- id: disable_adaptive_pruning
  label: Disable adaptive pruning
  doc: Disable the adaptive algorithm for pruning paths in the graph.
  type: boolean?
  inputBinding:
    prefix: --disable-adaptive-pruning
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: 'false'
- id: disable_tool_default_annotations
  label: Disable tool default annotations
  doc: Disable all tool default annotations.
  type: boolean?
  inputBinding:
    prefix: --disable-tool-default-annotations
    position: 4
    shellQuote: false
  sbg:altPrefix: -disable-tool-default-annotations
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: 'false'
- id: disable_tool_default_read_filters
  label: Disable tool default read filters
  doc: |-
    Disable all tool default read filters (warning: many tools will not function correctly without their default read filters on).
  type: boolean?
  inputBinding:
    prefix: --disable-tool-default-read-filters
    position: 4
    shellQuote: false
  sbg:altPrefix: -disable-tool-default-read-filters
  sbg:category: Optional Common Arguments
  sbg:toolDefaultValue: 'false'
- id: dont_increase_kmer_sizes_for_cycles
  label: Dont increase kmer sizes for cycles
  doc: Disable iterating over kmer sizes when graph cycles are detected.
  type: boolean?
  inputBinding:
    prefix: --dont-increase-kmer-sizes-for-cycles
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: 'false'
- id: dont_trim_active_regions
  label: Dont trim active regions
  doc: |-
    If specified, we will not trim down the active region from the full region (active.
  type: boolean?
  inputBinding:
    prefix: --dont-trim-active-regions
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
- id: dont_use_soft_clipped_bases
  label: Dont use soft clipped bases
  doc: Do not analyze soft clipped bases in the reads.
  type: boolean?
  inputBinding:
    prefix: --dont-use-soft-clipped-bases
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: 'false'
- id: emit_ref_confidence
  label: Emit ref confidence
  doc: (beta feature) mode for emitting reference confidence scores.
  type:
  - 'null'
  - name: emit_ref_confidence
    type: enum
    symbols:
    - NONE
    - BP_RESOLUTION
    - GVCF
  inputBinding:
    prefix: --emit-ref-confidence
    position: 4
    shellQuote: false
  sbg:altPrefix: -ERC
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: NONE
- id: enable_all_annotations
  label: Enable all annotations
  doc: Use all possible annotations (not for the faint of heart).
  type: boolean?
  inputBinding:
    prefix: --enable-all-annotations
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: 'false'
- id: force_active
  label: Force active
  doc: If provided, all regions will be marked as active.
  type: boolean?
  inputBinding:
    prefix: --force-active
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: 'false'
- id: force_call_filtered_alleles
  label: Genotype filtered alleles
  doc: Whether to force genotype even filtered alleles.
  type: boolean?
  inputBinding:
    prefix: --force-call-filtered-alleles
    position: 4
    shellQuote: false
  sbg:altPrefix: --genotype-filtered-alleles
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: 'false'
- id: gvcf_lod_band
  label: Gvcf lod band
  doc: |-
    Exclusive upper bounds for reference confidence lod bands (must be specified in increasing order) default value:.
  type: float[]?
  inputBinding:
    prefix: ''
    position: 4
    valueFrom: |-
      ${
          var output = "";
          for (var i=0; i<inputs.gvcf_lod_band.length; i++)
          {
              output = output + "--gvcf-lod-band " + inputs.gvcf_lod_band[i] + " ";
          }
          return output;
      }
    shellQuote: false
  sbg:altPrefix: -LODB
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: '[-2.5, -2.0, -1.5, -1.0, -0.5, 0.0, 0.5, 1.0]'
- id: kmer_size
  label: Kmer size
  doc: Kmer size to use in the read threading assembler default value:.
  type: int[]?
  inputBinding:
    prefix: ''
    position: 4
    valueFrom: |-
      ${
          var output = "";
          for (var i=0; i<inputs.kmer_size.length; i++)
          {
              output = output + "--kmer-size " + inputs.kmer_size[i] + " ";
          }
          return output;
      }
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: '[10, 25]'
- id: max_assembly_region_size
  label: Max assembly region size
  doc: Maximum size of an assembly region.
  type: int?
  inputBinding:
    prefix: --max-assembly-region-size
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: '300'
- id: max_mnp_distance
  label: Max mnp distance
  doc: |-
    Two or more phased substitutions separated by this distance or less are merged into mnps.
  type: int?
  inputBinding:
    prefix: --max-mnp-distance
    position: 4
    shellQuote: false
  sbg:altPrefix: -mnp-dist
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: '1'
- id: max_num_haplotypes_in_population
  label: Max num haplotypes in population
  doc: Maximum number of haplotypes to consider for your population.
  type: int?
  inputBinding:
    prefix: --max-num-haplotypes-in-population
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: '128'
- id: max_prob_propagation_distance
  label: Max prob propagation distance
  doc: |-
    Upper limit on how many bases away probability mass can be moved around when calculating the boundaries between active and inactive assembly regions.
  type: int?
  inputBinding:
    prefix: --max-prob-propagation-distance
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: '50'
- id: max_suspicious_reads_per_alignment_start
  label: Max suspicious reads per alignment start
  doc: |-
    Maximum number of suspicious reads (mediocre mapping quality or too many substitutions) allowed in a downsampling stride. Set to 0 to disable.
  type: int?
  inputBinding:
    prefix: --max-suspicious-reads-per-alignment-start
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: '0'
- id: max_unpruned_variants
  label: Max unpruned variants
  doc: Maximum number of variants in graph the adaptive pruner will allow.
  type: int?
  inputBinding:
    prefix: --max-unpruned-variants
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: '100'
- id: min_assembly_region_size
  label: Min assembly region size
  doc: Minimum size of an assembly region.
  type: int?
  inputBinding:
    prefix: --min-assembly-region-size
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: '50'
- id: min_dangling_branch_length
  label: Min dangling branch length
  doc: Minimum length of a dangling branch to attempt recovery.
  type: int?
  inputBinding:
    prefix: --min-dangling-branch-length
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: '4'
- id: min_pruning
  label: Min pruning
  doc: Minimum support to not prune paths in the graph.
  type: int?
  inputBinding:
    prefix: --min-pruning
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: '2'
- id: minimum_allele_fraction
  label: Minimum allele fraction
  doc: |-
    Lower bound of variant allele fractions to consider when calculating variant lod 0.
  type: float?
  inputBinding:
    prefix: --minimum-allele-fraction
    position: 4
    shellQuote: false
  sbg:altPrefix: -min-AF
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: '0'
- id: num_pruning_samples
  label: Num pruning samples
  doc: Number of samples that must pass the minpruning threshold.
  type: int?
  inputBinding:
    prefix: --num-pruning-samples
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: '1'
- id: pair_hmm_gap_continuation_penalty
  label: Pair hmm gap continuation penalty
  doc: Flat gap continuation penalty for use in the pair hmm.
  type: int?
  inputBinding:
    prefix: --pair-hmm-gap-continuation-penalty
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: '10'
- id: pair_hmm_implementation
  label: Pair hmm implementation
  doc: The pairhmm implementation to use for genotype likelihood calculations.
  type:
  - 'null'
  - name: pair_hmm_implementation
    type: enum
    symbols:
    - EXACT
    - ORIGINAL
    - LOGLESS_CACHING
    - AVX_LOGLESS_CACHING
    - AVX_LOGLESS_CACHING_OMP
    - EXPERIMENTAL_FPGA_LOGLESS_CACHING
    - FASTEST_AVAILABLE
  inputBinding:
    prefix: --pair-hmm-implementation
    position: 4
    shellQuote: false
  sbg:altPrefix: -pairHMM
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: FASTEST_AVAILABLE
- id: pcr_indel_model
  label: Pcr indel model
  doc: The pcr indel model to use.
  type:
  - 'null'
  - name: pcr_indel_model
    type: enum
    symbols:
    - NONE
    - HOSTILE
    - AGGRESSIVE
    - CONSERVATIVE
  inputBinding:
    prefix: --pcr-indel-model
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: CONSERVATIVE
- id: phred_scaled_global_read_mismapping_rate
  label: Phred scaled global read mismapping rate
  doc: The global assumed mismapping rate for reads.
  type: int?
  inputBinding:
    prefix: --phred-scaled-global-read-mismapping-rate
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: '45'
- id: pruning_lod_threshold
  label: Pruning lod threshold
  doc: Ln likelihood ratio threshold for adaptive pruning algorithm
  type: float?
  inputBinding:
    prefix: --pruning-lod-threshold
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: '2.302585092994046'
- id: recover_all_dangling_branches
  label: Recover all dangling branches
  doc: Recover all dangling branches.
  type: boolean?
  inputBinding:
    prefix: --recover-all-dangling-branches
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: 'false'
- id: showhidden
  label: Showhidden
  doc: Display hidden arguments.
  type: boolean?
  inputBinding:
    prefix: --showHidden
    position: 4
    shellQuote: false
  sbg:altPrefix: -showHidden
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: 'false'
- id: smith_waterman
  label: Smith waterman
  doc: |-
    Which smith-waterman implementation to use, generally fastest_available is the right choice.
  type:
  - 'null'
  - name: smith_waterman
    type: enum
    symbols:
    - FASTEST_AVAILABLE
    - AVX_ENABLED
    - JAVA
  inputBinding:
    prefix: --smith-waterman
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: JAVA
- id: ambig_filter_bases
  label: Ambig filter bases
  doc: |-
    Threshold number of ambiguous bases. If null, uses threshold fraction; otherwise, overrides threshold fraction. Cannot be used in conjuction with argument(s) maxambiguousbasefraction. Valid only if "ambiguousbasereadfilter" is specified.
  type: int?
  inputBinding:
    prefix: --ambig-filter-bases
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: 'null'
- id: ambig_filter_frac
  label: Ambig filter frac
  doc: |-
    Threshold fraction of ambiguous bases 05. Cannot be used in conjuction with argument(s) maxambiguousbases. Valid only if "ambiguousbasereadfilter" is specified.
  type: float?
  inputBinding:
    prefix: --ambig-filter-frac
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: '0'
- id: max_fragment_length
  label: Max fragment length
  doc: |-
    Maximum length of fragment (insert size). Valid only if "fragmentlengthreadfilter" is specified.
  type: int?
  inputBinding:
    prefix: --max-fragment-length
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: '1000000'
- id: min_fragment_length
  label: Min fragment length
  doc: |-
    Minimum length of fragment (insert size). Valid only if "fragmentlengthreadfilter" is specified.
  type: int?
  inputBinding:
    prefix: --min-fragment-length
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: '0'
- id: keep_intervals
  label: Keep intervals
  doc: |-
    One or more genomic intervals to keep this argument must be specified at least once. Valid only if "intervaloverlapreadfilter" is specified.
  type: string?
  inputBinding:
    prefix: --keep-intervals
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
- id: library
  label: Library
  doc: |-
    Name of the library to keep this argument must be specified at least once. Valid only if "libraryreadfilter" is specified.
  type: string?
  inputBinding:
    prefix: --library
    position: 4
    shellQuote: false
  sbg:altPrefix: -library
  sbg:category: Advanced Arguments
- id: maximum_mapping_quality
  label: Maximum mapping quality
  doc: |-
    Maximum mapping quality to keep (inclusive). Valid only if "mappingqualityreadfilter" is specified.
  type: int?
  inputBinding:
    prefix: --maximum-mapping-quality
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: 'null'
- id: minimum_mapping_quality
  label: Minimum mapping quality
  doc: |-
    Minimum mapping quality to keep (inclusive). Valid only if "mappingqualityreadfilter" is specified.
  type: int?
  inputBinding:
    prefix: --minimum-mapping-quality
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: '20'
- id: dont_require_soft_clips_both_ends
  label: Dont require soft clips both ends
  doc: |-
    Allow a read to be filtered out based on having only 1 soft-clipped block. By default, both ends must have a soft-clipped block, setting this flag requires only 1 soft-clipped block. Valid only if "overclippedreadfilter" is specified.
  type: boolean?
  inputBinding:
    prefix: --dont-require-soft-clips-both-ends
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: 'false'
- id: filter_too_short
  label: Filter too short
  doc: |-
    Minimum number of aligned bases. Valid only if "overclippedreadfilter" is specified.
  type: int?
  inputBinding:
    prefix: --filter-too-short
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: '30'
- id: platform_filter_name
  label: Platform filter name
  doc: |-
    Platform attribute (pl) to match this argument must be specified at least once. Valid only if "platformreadfilter" is specified.
  type: string?
  inputBinding:
    prefix: --platform-filter-name
    position: 4
    valueFrom: "${\n    return '\"' + self + '\"';\n}"
    shellQuote: false
  sbg:category: Advanced Arguments
- id: black_listed_lanes
  label: Black listed lanes
  doc: |-
    Platform unit (pu) to filter out this argument must be specified at least once. Valid only if "platformunitreadfilter" is specified.
  type: string?
  inputBinding:
    prefix: --black-listed-lanes
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
- id: read_group_black_list
  label: Read group black list
  doc: |-
    Name of the read group to filter out this argument must be specified at least once. Valid only if "readgroupblacklistreadfilter" is specified.
  type: string?
  inputBinding:
    prefix: --read-group-black-list
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
- id: keep_read_group
  label: Keep read group
  doc: |-
    The name of the read group to keep. Valid only if "readgroupreadfilter" is specified.
  type: string?
  inputBinding:
    prefix: --keep-read-group
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
- id: max_read_length
  label: Max read length
  doc: |-
    Keep only reads with length at most equal to the specified value. Valid only if "readlengthreadfilter" is specified.
  type: int?
  inputBinding:
    prefix: --max-read-length
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: '2147483647'
- id: min_read_length
  label: Min read length
  doc: |-
    Keep only reads with length at least equal to the specified value. Valid only if "readlengthreadfilter" is specified.
  type: int?
  inputBinding:
    prefix: --min-read-length
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: '30'
- id: read_name
  label: Read name
  doc: |-
    Keep only reads with this read name. Valid only if "readnamereadfilter" is specified.
  type: string?
  inputBinding:
    prefix: --read-name
    position: 4
    valueFrom: "${\n    return '\"' + self + '\"';\n}"
    shellQuote: false
  sbg:category: Advanced Arguments
- id: keep_reverse_strand_only
  label: Keep reverse strand only
  doc: |-
    Keep only reads on the reverse strand. Valid only if "readstrandfilter" is specified.
  type: boolean?
  inputBinding:
    prefix: --keep-reverse-strand-only
    position: 4
    shellQuote: false
  sbg:category: Advanced Arguments
- id: sample
  label: Sample
  doc: |-
    The name of the sample(s) to keep, filtering out all others this argument must be specified at least once. Valid only if "samplereadfilter" is specified.
  type: string?
  inputBinding:
    prefix: --sample
    position: 4
    valueFrom: "${\n    return '\"' + self + '\"';\n}"
    shellQuote: false
  sbg:altPrefix: -sample
  sbg:category: Advanced Arguments
- id: cpu_per_job
  label: CPU per job
  doc: Number of CPUs per job
  type: int?
  sbg:category: Execution
  sbg:toolDefaultValue: '1'
- id: in_interval_files
  label: Interval Files
  doc: One or more genomic intervals, given in form of a file, over which to operate.
  type: File[]?
  inputBinding:
    position: 4
    valueFrom: |-
      ${
          var output = "";
          var interval_files = [].concat(self);
          for (var i=0; i < interval_files.length; i++)
              output += " --intervals " + interval_files[i].path;
          return output;
      }
    shellQuote: false
  sbg:altPrefix: -L
  sbg:category: Optional Tool Arguments
  sbg:fileTypes: LIST, BED, INTERVALS, VCF, INTERVAL_LIST
- id: exclude_interval_files
  label: Exclude intervals
  doc: Or more genomic intervals, in form of a file, to exclude from processing.
  type: File[]?
  inputBinding:
    position: 4
    valueFrom: |-
      ${
          var output = "";
          for (var i=0; i<self.length; i++)
              output += " -XL " + self[i].path;
          return output;
      }
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:fileTypes: LIST, INTERVALS, VCF, BED, INTERVAL_LIST
- id: make_bamout
  label: Make BAM output
  doc: File to which assembled haplotypes should be written
  type: boolean?
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: 'null'
- id: make_f1r2
  label: Make f1r2 file
  doc: Make f1r2 output file.
  type: boolean?
  sbg:category: Advanced Arguments
- id: compress
  label: Compress output
  doc: Compres output VCF.
  type: boolean?
  sbg:category: Advanced Arguments
- id: mem_per_job
  label: Memory Per Job
  doc: Memory Per Job (in MB)
  type: int?
  sbg:category: Execution
  sbg:toolDefaultValue: '3500'
- id: mem_overhead_per_job
  label: Memory overhead per job
  doc: Memory overhead per job (in MB).
  type: int?
  sbg:category: Execution
  sbg:toolDefaultValue: '500'
- id: output_bam_filename
  label: Output BAM filename
  doc: Filename of the output BAM file.
  type: string?
  sbg:altPrefix: -bamout
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: 'null'
- id: append_interval_to_name
  label: Append interval to name
  doc: |-
    Appends first 4 characters of the intervals name to the output name. This option should be used if Mutect is scattered by input intervals.
  type: boolean?
  sbg:category: Additional inputs
  sbg:toolDefaultValue: 'False'
- id: mutect2_extra_arguments
  label: Extra Arguments
  doc: |-
    This will be inserted directly into the command line of the tool (Use with care!).
  type: string[]?
  inputBinding:
    position: 4
    valueFrom: |-
      ${
          if (self.length > 0){
              return self.join(" ");
      } else {
              return null;
          }
      }
    shellQuote: false
  sbg:category: Optional Tool Arguments
  sbg:toolDefaultValue: None

outputs:
- id: out_variants
  label: Output variants
  doc: Output variants in VCF or VCF.GZ format.
  type: File?
  secondaryFiles:
  - pattern: "${\n    return [self.basename + \".idx\", self.nameroot + \".idx\"]\n\
      }"
  - pattern: "${\n    return [self.basename + \".tbi\", self.nameroot + \".tbi\"]\n\
      }"
  outputBinding:
    glob: "${\n    return [\"*.vcf.gz\", \"*.vcf\"]\n}"
    outputEval: |-
      ${
          function removeNull(array){
              var output = [];
              for (var i = 0; i<array.length; i++){
                  if (array[i] != null){
                      output.push(array[i]);
                  }
              }
              return output;
          }
          
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
          
          self = inheritMetadata(self, removeNull([].concat(inputs.in_alignments)));
          return self;
      }
  sbg:fileTypes: VCF, VCF.GZ
- id: out_alignments
  label: Output alignments
  doc: Output alignments in BAM format
  type: File?
  secondaryFiles:
  - pattern: .bai
  - pattern: ^.bai
  outputBinding:
    glob: '*.bam'
    outputEval: |-
      ${
          function removeNull(array){
              var output = [];
              for (var i = 0; i<array.length; i++){
                  if (array[i] != null){
                      output.push(array[i]);
                  }
              }
              return output;
          }
          
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
          
          self = inheritMetadata(self, removeNull([].concat(inputs.in_alignments)));
          return self;
      }
  sbg:fileTypes: BAM
- id: f1r2_counts
  label: Output f1r2 counts
  doc: Output f1r2 counts in TAR.GZ format
  type: File?
  outputBinding:
    glob: '*.tar.gz'
    outputEval: |-
      ${
          function removeNull(array){
              var output = [];
              for (var i = 0; i<array.length; i++){
                  if (array[i] != null){
                      output.push(array[i]);
                  }
              }
              return output;
          }
          
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
          
          self = inheritMetadata(self, removeNull([].concat(inputs.in_alignments)));
          return self;
      }
  sbg:fileTypes: TAR.GZ
- id: out_stats
  label: Output stats
  doc: Output stat file.
  type: File?
  outputBinding:
    glob: "${\n    return [\"*.vcf.gz.stats\", \"*.vcf.stats\"]\n}"
    outputEval: |-
      ${
          function removeNull(array){
              var output = [];
              for (var i = 0; i<array.length; i++){
                  if (array[i] != null){
                      output.push(array[i]);
                  }
              }
              return output;
          }
          
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
          
          self = inheritMetadata(self, removeNull([].concat(inputs.in_alignments)));
          return self;
      }
  sbg:fileTypes: STATS, VCF.GZ.STATS, VCF.STATS

baseCommand:
- /opt/gatk
arguments:
- prefix: --java-options
  position: 2
  valueFrom: |-
    ${
        if (inputs.mem_per_job) {
            return '\"-Xmx'.concat(inputs.mem_per_job, 'M') + '\"'
        }
        return '\"-Xmx7500M\"'
    }
  shellQuote: false
- position: 3
  valueFrom: Mutect2
  shellQuote: false
- prefix: --output
  position: 5
  valueFrom: |-
    ${
        function extractSampleId(file) {
            if (file.hasOwnProperty('metadata') && file.metadata && file.metadata['sample_id']){
                return file.metadata['sample_id'];
            } else {
                return file.basename.split(".").slice(0)[0];
            }
        }
        
        function isTumor(file){
            if (file.hasOwnProperty('metadata') && file.metadata && file.metadata['sample_type']){
                return file.metadata['sample_type'].indexOf('Tumor') != -1;
            } else {
                return false;
            }
        }
        
        function removeEmpty(list){
            list = [].concat(list);
            var new_list = [];
            for (var i=0; i < list.length; i++){
                if (list[i] != ""){
                    new_list.push(list[i]);
                }
            }
            return new_list;
        }
        
        var added_suffix = "";
        if (inputs.append_interval_to_name){
            var intervals = [].concat(inputs.in_interval_files);
            if (intervals.length > 0){
                added_suffix = intervals[0].nameroot;
                if (added_suffix.length >= 4){
                    added_suffix = added_suffix.substring(0, 4);
                } else {
                    added_suffix = "";
                }
            }
        }
        
        if (added_suffix.length > 0){
            added_suffix = "_" + added_suffix;
        }
        
        var suffix = added_suffix + ".somatic.vcf";
        if (inputs.compress){
            suffix += ".gz";
        }
        
        var output = "mutect2";
        
        if (inputs.output_filename){
            output = inputs.output_filename;
        } else {
            var tumor_id = "";
            var normal_id = "";
            var output_files = [].concat(inputs.in_alignments);
            
            if (inputs.tumor_sample){
                tumor_id = removeEmpty(inputs.tumor_sample)[0];
            }
            
            if (inputs.normal_sample){
                normal_id = removeEmpty(inputs.normal_sample)[0];
            }
            
            if (!tumor_id || !normal_id){
                var normal_names = [];
                var tumor_names = [];
                
                if (inputs.normal_sample){
                    normal_names = removeEmpty(inputs.normal_sample);
                }
                if (!normal_names[0]){
                    for (var i=0; i < output_files.length; i++){
                        if (output_files[i]){
                            var id = extractSampleId(output_files[i]);
                            if (!isTumor(output_files[i]) && id){
                                normal_names.push(id);
                            }
                        }
                    }
                }
                
                if (inputs.tumor_sample){
                    tumor_names = removeEmpty(inputs.tumor_sample);
                }
                if (!tumor_names[0]){
                    for (var i=0; i < output_files.length; i++){
                        if (output_files[i]){
                            var id = extractSampleId(output_files[i]);
                            if (isTumor(output_files[i]) && id){
                                tumor_names.push(id);
                            }
                        }
                    }
                }
                
                if (tumor_names.length == 1){
                    tumor_id = tumor_names[0];
                }
                
                if (normal_names.length == 1){
                    normal_id = normal_names[0];
                }
                
                if (!tumor_id || tumor_names.length>1 || normal_names.length>1){
                    tumor_id = 'mutect2';
                    normal_id = '';
                }
            }
            if (normal_id){
                output = tumor_id + "-" + normal_id
            } else {
                output = tumor_id;
            }
        }
        var name = output + suffix;
        while (name.indexOf(" ") > -1){
            name = name.replace(" ", "_")
        }
        return name;
    }
  shellQuote: false
- prefix: --f1r2-tar-gz
  position: 5
  valueFrom: |-
    ${
        function extractSampleId(file) {
            if (file.metadata && file.metadata['sample_id']){
                return file.metadata['sample_id'];
            } else {
                return file.basename.split(".").slice(0)[0];
            }
        }
        
        function isTumor(file){
            if (output_files[i].metadata && output_files[i].metadata['sample_type']){
                return output_files[i].metadata['sample_type'].indexOf('Tumor') != -1;
            } else {
                return false;
            }
        }
        
        function removeEmpty(list){
            list = [].concat(list);
            var new_list = [];
            for (var i=0; i < list.length; i++){
                if (list[i] != ""){
                    new_list.push(list[i]);
                }
            }
            return new_list;
        }
        
        // If make_f1_r2 is true, create outoput name and prefix
        if (inputs.make_f1r2){
            var added_suffix = "";
            if (inputs.in_interval_files.length > 0){
                added_suffix = inputs.in_interval_files[0].nameroot;
                if (added_suffix.length >= 4){
                    added_suffix = added_suffix.substring(0, 4);
                } else {
                    added_suffix = "";
                }
            }
            
            if (added_suffix.length > 0){
                added_suffix = "_" + added_suffix;
            }
            var suffix = added_suffix + ".tar.gz";
            var output = "f1r2";
            
            if (inputs.f1r2_tar_gz){
                output = inputs.f1r2_tar_gz;
            } else if (inputs.output_filename){
                output = inputs.output_filename;
            } else {
                var tumor_id = "";
                var normal_id = "";
                var output_files = [].concat(inputs.in_alignments);
                
                if (inputs.tumor_sample){
                    tumor_id = removeEmpty(inputs.tumor_sample)[0];
                }
                
                if (inputs.normal_sample){
                    normal_id = removeEmpty(inputs.normal_sample)[0];
                }
                
                if (!tumor_id || !normal_id){
                    var normal_names = [];
                    var tumor_names = [];
                    
                    if (inputs.normal_sample){
                        normal_names = removeEmpty(inputs.normal_sample);
                    }
                    
                    if (inputs.tumor_sample){
                        tumor_names = removeEmpty(inputs.tumor_sample);
                    }
                    if (!normal_names[0]){
                        for (var i=0; i < output_files.length; i++){
                            var id = extractSampleId(output_files[i]);
                            if (!isTumor(output_files[i]) && id){
                                normal_names.push(id);
                            }
                        }
                    }
                    
                    if (!tumor_names[0]){
                        for (var i=0; i < output_files.length; i++){
                            var id = extractSampleId(output_files[i]);
                            if (isTumor(output_files[i]) && id){
                                tumor_names.push(id);
                            }
                        }
                    }
                    
                    if (tumor_names.length == 1){
                        tumor_id = tumor_names[0];
                    }
                    
                    if (normal_names.length == 1){
                        normal_id = normal_names[0];
                    }
                    
                    if (!tumor_id || tumor_names.length>1 || normal_names.length>1){
                        tumor_id = 'f1r2';
                        normal_id = '';
                    }
                }
                if (normal_id){
                    output = tumor_id + "-" + normal_id
                } else {
                    output = tumor_id;
                }
            }
            var name = output + suffix;
            while (name.indexOf(" ") > -1){
                name = name.replace(" ", "_")
            }
            return name;
        } else {
            return null;
        }
    }
  shellQuote: false
- prefix: --bam-output
  position: 5
  valueFrom: |-
    ${
        function extractSampleId(file) {
            if (file.metadata && file.metadata['sample_id']){
                return file.metadata['sample_id'];
            } else {
                return file.basename.split(".").slice(0)[0];
            }
        }
        
        function isTumor(file){
            if (output_files[i].metadata && output_files[i].metadata['sample_type']){
                return output_files[i].metadata['sample_type'].indexOf('Tumor') != -1;
            } else {
                return false;
            }
        }
        
        function removeEmpty(list){
            list = [].concat(list);
            var new_list = [];
            for (var i=0; i < list.length; i++){
                if (list[i] != ""){
                    new_list.push(list[i]);
                }
            }
            return new_list;
        }
        
        if (inputs.make_bamout){
            var suffix = '.bam'
            
            var output = "mutect2";
            
            if (inputs.output_bam_filename){
                output = inputs.output_bam_filename;
            } else {
                var tumor_id = "";
                var normal_id = "";
                var output_files = [].concat(inputs.in_alignments);
                
                if (inputs.tumor_sample){
                    tumor_id = removeEmpty(inputs.tumor_sample)[0];
                }
                
                if (inputs.normal_sample){
                    normal_id = removeEmpty(inputs.normal_sample)[0];
                }
                
                if (!tumor_id || !normal_id){
                    var normal_names = [];
                    var tumor_names = [];
                    
                    if (inputs.normal_sample){
                        normal_names = removeEmpty(inputs.normal_sample);
                    }
                    
                    if (inputs.tumor_sample){
                        tumor_names = removeEmpty(inputs.tumor_sample);
                    }
                    if (!normal_names[0]){
                        for (var i=0; i < output_files.length; i++){
                            var id = extractSampleId(output_files[i]);
                            if (!isTumor(output_files[i]) && id){
                                normal_names.push(id);
                            }
                        }
                    }
                    
                    if (!tumor_names[0]){
                        for (var i=0; i < output_files.length; i++){
                            var id = extractSampleId(output_files[i]);
                            if (isTumor(output_files[i]) && id){
                                tumor_names.push(id);
                            }
                        }
                    }
                    
                    if (tumor_names.length == 1){
                        tumor_id = tumor_names[0];
                    }
                    
                    if (normal_names.length == 1){
                        normal_id = normal_names[0];
                    }
                    
                    if (!tumor_id || tumor_names.length>1 || normal_names.length>1){
                        tumor_id = 'mutect2';
                        normal_id = '';
                    }
                }
                if (normal_id){
                    output = tumor_id + "-" + normal_id
                } else {
                    output = tumor_id;
                }
            }
            var name = output + suffix;
            while (name.indexOf(" ") > -1){
                name = name.replace(" ", "_")
            }
            return name;
        } else {
            return null;
        }
    }
  shellQuote: false
id: dave/build-mitochondria-pipeline/gatk-mutect2/5
sbg:appVersion:
- v1.2
sbg:categories:
- GATK-4
- CWL1.0
sbg:content_hash: acace08f44a80755f97843e88640bde484aaa476b26c41ac00ec1ff7cf2407fc2
sbg:contributors:
- dave
sbg:createdBy: dave
sbg:createdOn: 1622646232
sbg:id: dave/build-mitochondria-pipeline/gatk-mutect2/5
sbg:image_url:
sbg:latestRevision: 5
sbg:license: Open source BSD (3-clause) license
sbg:links:
- id: https://software.broadinstitute.org/gatk/
  label: Homepage
- id: https://github.com/broadinstitute/gatk/
  label: Source
- id: |-
    https://github.com/broadinstitute/gatk/releases/download/4.1.6.0/gatk-4.1.6.0.zip
  label: Download
- id: https://www.ncbi.nlm.nih.gov/pubmed?term=20644199
  label: Publication
- id: |-
    https://software.broadinstitute.org/gatk/documentation/tooldocs/4.1.6.0/org_broadinstitute_hellbender_tools_walkers_mutect_Mutect2.php
  label: Documentation
sbg:modifiedBy: dave
sbg:modifiedOn: 1622862857
sbg:project: dave/build-mitochondria-pipeline
sbg:projectName: 'BUILD: Mitochondria Pipeline'
sbg:publisher: sbg
sbg:revision: 5
sbg:revisionNotes: ''
sbg:revisionsInfo:
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1622646232
  sbg:revision: 0
  sbg:revisionNotes: "Uploaded using sbpack v2020.10.05. \nSource: gatk_mutect2_cwl1_0.cwl"
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1622834532
  sbg:revision: 1
  sbg:revisionNotes: single input file bam
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1622834908
  sbg:revision: 2
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1622835842
  sbg:revision: 3
  sbg:revisionNotes: added .fai secondary file
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1622855767
  sbg:revision: 4
  sbg:revisionNotes: ^.dict
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1622862857
  sbg:revision: 5
  sbg:revisionNotes: ''
sbg:sbgMaintained: false
sbg:toolAuthor: Broad Institute
sbg:toolkit: GATK
sbg:toolkitVersion: 4.1.9.0
sbg:validationErrors: []
sbg:wrapperAuthor: Pavle Marinkovic
