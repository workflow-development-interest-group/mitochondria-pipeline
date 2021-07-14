cwlVersion: v1.2
class: Workflow
label: mitochondria-pipeline
$namespaces:
  sbg: https://sevenbridges.com

requirements:
- class: MultipleInputFeatureRequirement
- class: InlineJavascriptRequirement
- class: StepInputExpressionRequirement

inputs:
- id: ref_fasta
  type: File?
  secondaryFiles:
  - pattern: .fai
    required: true
  - pattern: ^.dict
    required: true
  sbg:fileTypes: FASTA
  sbg:x: 0
  sbg:y: 336.9140625
- id: cram
  type: File?
  secondaryFiles:
  - pattern: .crai
    required: true
  sbg:x: 0
  sbg:y: 443.6796875
- id: reference_index_tar
  label: Non shifted Reference Index TAR
  doc: Reference fasta file with its BWA index files packed in a TAR archive.
  type: File
  sbg:fileTypes: TAR
  sbg:x: 0
  sbg:y: 230.1484375
- id: shifted_reference_index_tar
  label: Shifted Reference Index TAR
  doc: Reference fasta file with its BWA index files packed in a TAR archive.
  type: File
  sbg:fileTypes: TAR
  sbg:x: 0
  sbg:y: 123.3828125
- id: in_reference_and_index
  label: Shifted Reference FASTA and index
  doc: Reference FASTA or FA sequence file and associated index and dict.
  type: File
  secondaryFiles:
  - pattern: .fai
    required: true
  - pattern: ^.dict
    required: true
  sbg:fileTypes: FASTA, FA
  sbg:x: 952.1976318359375
  sbg:y: 178.59780883789062
- id: in_reference_and_index_1
  label: Non ShiftedReference FASTA and index
  doc: Reference FASTA or FA sequence file and associated index and dict.
  type: File
  secondaryFiles:
  - pattern: .fai
    required: true
  - pattern: ^.dict
    required: true
  sbg:fileTypes: FASTA, FA
  sbg:x: 952.8524780273438
  sbg:y: -407.0513610839844
- id: chain
  type: File
  sbg:x: 1302.29345703125
  sbg:y: 553.0625
- id: blacklisted_sites
  type: File
  sbg:x: 1997.68701171875
  sbg:y: 577.0529174804688

outputs:
- id: wgs_metrics
  label: Non Shifted WGS metrics
  doc: Output metrics file.
  type: File?
  outputSource:
  - picard_collectwgsmetricswithnonzerocoverage_2_21_6_cwl1_2/wgs_metrics
  sbg:fileTypes: TXT
  sbg:x: 1581.826171875
  sbg:y: -149.3757781982422
- id: wgs_metrics_1
  label: Shifted WGS metrics
  doc: Output metrics file.
  type: File?
  outputSource:
  - picard_collectwgsmetricswithnonzerocoverage_2_21_6_cwl1_1/wgs_metrics
  sbg:fileTypes: TXT
  sbg:x: 1825.9027099609375
  sbg:y: -22.09930419921875
- id: merged_and_filtered_vcf
  type: File?
  outputSource:
  - filtermutectcalls_1/merged_and_filtered_vcf
  sbg:x: 3409.916015625
  sbg:y: 202.43544006347656

steps:
- id: subset_bam_to_chrom_m
  label: subset-bam-to-chrom-m
  in:
  - id: cram
    source: cram
  - id: contig_name
    default: chrM
  - id: ref_fasta
    source: ref_fasta
  run: mitochondria-pipeline.cwl.steps/subset_bam_to_chrom_m.cwl
  out:
  - id: chrM_bam
  sbg:x: 276.625
  sbg:y: 276.53125
- id: revert_sam
  label: revert-sam
  in:
  - id: bam
    source: subset_bam_to_chrom_m/chrM_bam
  run: mitochondria-pipeline.cwl.steps/revert_sam.cwl
  out:
  - id: unaligned_bam
  sbg:x: 481.85467529296875
  sbg:y: 283.53125
- id: gatk_samtofastq
  label: GATK SamToFastq
  in:
  - id: in_alignments
    source: revert_sam/unaligned_bam
  run: mitochondria-pipeline.cwl.steps/gatk_samtofastq.cwl
  out:
  - id: out_reads
  - id: unmapped_reads
  sbg:x: 678.6671752929688
  sbg:y: 276.53125
- id: bwa_mem_bundle
  label: non shifted bwa
  in:
  - id: input_reads
    source:
    - gatk_samtofastq/out_reads
  - id: reference_index_tar
    source: reference_index_tar
  run: mitochondria-pipeline.cwl.steps/bwa_mem_bundle.cwl
  out:
  - id: aligned_reads
  - id: dups_metrics
  sbg:x: 993.5999145507812
  sbg:y: 450.6796875
- id: bwa_mem_bundle_1
  label: Shifted bwa
  in:
  - id: input_reads
    source:
    - gatk_samtofastq/out_reads
  - id: reference_index_tar
    source: shifted_reference_index_tar
  run: mitochondria-pipeline.cwl.steps/bwa_mem_bundle_1.cwl
  out:
  - id: aligned_reads
  - id: dups_metrics
  sbg:x: 993.5999145507812
  sbg:y: 329.9140625
- id: gatk_mutect2_non_shifted_mt
  label: non shifted mutect2
  in:
  - id: in_alignments
    source: bwa_mem_bundle/aligned_reads
    pickValue: first_non_null
  - id: in_reference_and_index
    source: in_reference_and_index_1
  - id: annotation
    default:
    - StrandBiasBySample
  - id: annotation_group
    default: []
  - id: annotations_to_exclude
    default: []
  - id: mitochondria_mode
    default: true
  - id: read_filter
    default:
    - MateOnSameContigOrNoMappedMateReadFilter
    - MateUnmappedAndUnmappedReadFilter
  - id: max_mnp_distance
    default: 0
  run: mitochondria-pipeline.cwl.steps/gatk_mutect2_non_shifted_mt.cwl
  out:
  - id: out_variants
  - id: out_alignments
  - id: f1r2_counts
  - id: out_stats
  sbg:x: 1334.3018798828125
  sbg:y: 425
- id: gatk_mutect2_shifted_mt
  label: shifted mutect2
  doc: |-
    https://github.com/cwl-apps/gatk-best-practices/blob/8f54dbc054ef5d5401a48d13b9979d3156da4e6d/pre-processing.cwl.steps/gatk_samtofastq_4_1_0_0.cwl
  in:
  - id: in_alignments
    source: bwa_mem_bundle_1/aligned_reads
    pickValue: first_non_null
  - id: in_reference_and_index
    source: in_reference_and_index
  - id: annotation
    default:
    - StrandBiasBySample
  - id: read_filter
    default:
    - MateOnSameContigOrNoMappedMateReadFilter
    - MateUnmappedAndUnmappedReadFilter
  - id: max_mnp_distance
    default: 0
  run: mitochondria-pipeline.cwl.steps/gatk_mutect2_shifted_mt.cwl
  out:
  - id: out_variants
  - id: out_alignments
  - id: f1r2_counts
  - id: out_stats
  sbg:x: 1302.29345703125
  sbg:y: 276.53125
- id: picard_collectwgsmetricswithnonzerocoverage_2_21_6_cwl1_2
  label: non shifted metrics
  in:
  - id: in_alignments
    source: bwa_mem_bundle/aligned_reads
  - id: in_reference
    source: in_reference_and_index_1
  run: |-
    mitochondria-pipeline.cwl.steps/picard_collectwgsmetricswithnonzerocoverage_2_21_6_cwl1_2.cwl
  out:
  - id: output_chart
  - id: wgs_metrics
  - id: theoretical_sensitivity_out_file
  sbg:x: 1369.103271484375
  sbg:y: -110.30288696289062
- id: picard_collectwgsmetricswithnonzerocoverage_2_21_6_cwl1_1
  label: shifted wgs metrics
  in:
  - id: in_alignments
    source: bwa_mem_bundle_1/aligned_reads
  - id: in_reference
    source: in_reference_and_index
  run: |-
    mitochondria-pipeline.cwl.steps/picard_collectwgsmetricswithnonzerocoverage_2_21_6_cwl1_1.cwl
  out:
  - id: output_chart
  - id: wgs_metrics
  - id: theoretical_sensitivity_out_file
  sbg:x: 1356.5589599609375
  sbg:y: 81.09429168701172
- id: picard_lift_over_and_merge
  label: picard-lift-over-and-merge
  in:
  - id: shifted_vcf
    source: gatk_mutect2_shifted_mt/out_variants
  - id: reference
    source: in_reference_and_index_1
  - id: chain
    source: chain
  - id: non_shifted_vcf
    source: gatk_mutect2_non_shifted_mt/out_variants
  run: mitochondria-pipeline.cwl.steps/picard_lift_over_and_merge.cwl
  out:
  - id: merged_vcf
  sbg:x: 1742.103271484375
  sbg:y: 140.79840087890625
- id: gatk_merge_mutect_stats
  label: gatk-merge-mutect-stats
  in:
  - id: stats
    source:
    - gatk_mutect2_shifted_mt/out_stats
    - gatk_mutect2_non_shifted_mt/out_stats
  run: mitochondria-pipeline.cwl.steps/gatk_merge_mutect_stats.cwl
  out:
  - id: merged_stats
  sbg:x: 1779.68505859375
  sbg:y: 437.43829345703125
- id: filtermutectcalls
  label: Initial Filter - FilterMutectCalls
  in:
  - id: vcf
    source: picard_lift_over_and_merge/merged_vcf
  - id: fasta
    source: in_reference_and_index_1
  - id: raw_vcf_stats
    source: gatk_merge_mutect_stats/merged_stats
  - id: max_alt_allele_count
    default: 4
  - id: min_allele_fraction
    default: 0
  - id: blacklisted_sites
    source: blacklisted_sites
  run: mitochondria-pipeline.cwl.steps/filtermutectcalls.cwl
  out:
  - id: filter_vcf
  - id: merged_and_filtered_vcf
  - id: tsv
  sbg:x: 2198.98388671875
  sbg:y: 243.75921630859375
- id: splitmultiallelicsandremovenonpasssites
  label: SplitMultiAllelicsAndRemoveNonPassSites
  in:
  - id: reference
    source: in_reference_and_index_1
  - id: vcf
    source: filtermutectcalls/merged_and_filtered_vcf
  run: mitochondria-pipeline.cwl.steps/splitmultiallelicsandremovenonpasssites.cwl
  out:
  - id: all_vcfs
  - id: splitAndPassOnly_vcf
  sbg:x: 2460.104248046875
  sbg:y: -22.690200805664062
- id: get_contamination
  label: Get Contamination
  in:
  - id: vcf
    source: splitmultiallelicsandremovenonpasssites/splitAndPassOnly_vcf
  run: mitochondria-pipeline.cwl.steps/get_contamination.cwl
  out:
  - id: output_noquotes
  - id: contamination
  - id: headers
  - id: major_hg
  - id: output
  - id: mean_het_maj_minor
  - id: minor_hg
  sbg:x: 2711.877685546875
  sbg:y: -251.48751831054688
- id: filtermutectcalls_1
  label: FilterMutectCalls
  in:
  - id: vcf
    source: splitmultiallelicsandremovenonpasssites/splitAndPassOnly_vcf
  - id: fasta
    source: in_reference_and_index_1
  - id: raw_vcf_stats
    source: gatk_merge_mutect_stats/merged_stats
  - id: max_alt_allele_count
    default: 4
  - id: blacklisted_sites
    source: blacklisted_sites
  - id: custom_input
    source: get_contamination/contamination
  run: mitochondria-pipeline.cwl.steps/filtermutectcalls_1.cwl
  when: |-
    ${if(inputs.custom_input.contents = "YES"){
        true
        
    } else {
            false
        
    }}
  out:
  - id: filter_vcf
  - id: merged_and_filtered_vcf
  - id: tsv
  sbg:x: 3042.3251953125
  sbg:y: 36.56428146362305
sbg:appVersion:
- v1.2
sbg:content_hash: a830e9a7a7640067f213c3c97b9d3ffce1ada03fd0416b24de13642a5ce8e2d2e
sbg:contributors:
- dave
sbg:createdBy: dave
sbg:createdOn: 1626279500
sbg:id: arocco/mitochondrial-pipeline/mitochondria-pipeline/1
sbg:image_url:
sbg:latestRevision: 1
sbg:modifiedBy: dave
sbg:modifiedOn: 1626280007
sbg:original_source: |-
  https://api.sb.biodatacatalyst.nhlbi.nih.gov/v2/apps/arocco/mitochondrial-pipeline/mitochondria-pipeline/1/raw/
sbg:project: arocco/mitochondrial-pipeline
sbg:projectName: Mitochondrial Pipeline
sbg:publisher: sbg
sbg:revision: 1
sbg:revisionNotes: ''
sbg:revisionsInfo:
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1626279500
  sbg:revision: 0
  sbg:revisionNotes: Copy of dave/build-mitochondria-pipeline/mitochondria-pipeline/64
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1626280007
  sbg:revision: 1
  sbg:revisionNotes: ''
sbg:sbgMaintained: false
sbg:validationErrors: []
