cwlVersion: v1.2
class: Workflow
label: mitochondria-pipeline
$namespaces:
  sbg: https://sevenbridges.com

requirements:
- class: ScatterFeatureRequirement
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
  sbg:x: -469.82830810546875
  sbg:y: -527.2415161132812
- id: cram
  type: File?
  secondaryFiles:
  - pattern: .crai
    required: true
  sbg:x: -580.0416870117188
  sbg:y: -231.31129455566406
- id: reference_index_tar
  label: Non shifted Reference Index TAR
  doc: Reference fasta file with its BWA index files packed in a TAR archive.
  type: File
  sbg:fileTypes: TAR
  sbg:x: 134.5868377685547
  sbg:y: -652.9955444335938
- id: shifted_reference_index_tar
  label: Shifted Reference Index TAR
  doc: Reference fasta file with its BWA index files packed in a TAR archive.
  type: File
  sbg:fileTypes: TAR
  sbg:x: 138.75247192382812
  sbg:y: -45.26885223388672
- id: non_shifed_in_reference
  label: Non Shifted Reference
  doc: |-
    The reference sequence in FASTA format to which reads will be aligned.  Required.
  type: File
  sbg:fileTypes: FASTA, FA, FASTA.GZ
  sbg:x: 514.718505859375
  sbg:y: -859.6279907226562
- id: in_reference_1
  label: Shifted Reference
  doc: |-
    The reference sequence in FASTA format to which reads will be aligned.  Required.
  type: File
  sbg:fileTypes: FASTA, FA, FASTA.GZ
  sbg:x: 472.44720458984375
  sbg:y: -192.5330352783203

outputs:
- id: dups_metrics
  label: Sormadup metrics
  doc: Metrics file for biobambam mark duplicates
  type: File?
  outputSource:
  - bwa_mem_bundle/dups_metrics
  sbg:fileTypes: LOG
  sbg:x: 523.5358276367188
  sbg:y: -529.854736328125
- id: aligned_reads
  label: Aligned SAM/BAM
  doc: Aligned reads.
  type: File?
  outputSource:
  - bwa_mem_bundle/aligned_reads
  sbg:fileTypes: SAM, BAM, CRAM
  sbg:x: 521.3660278320312
  sbg:y: -336.5093994140625
- id: aligned_reads_1
  label: Aligned SAM/BAM
  doc: Aligned reads.
  type: File?
  outputSource:
  - bwa_mem_bundle_1/aligned_reads
  sbg:fileTypes: SAM, BAM, CRAM
  sbg:x: 468.83074951171875
  sbg:y: 132.8069305419922
- id: shifted_wgs_metrics
  label: Shifted WGS metrics
  doc: Output metrics file.
  type: File?
  outputSource:
  - picard_collectwgsmetricswithnonzerocoverage_2_21_6_cwl1_0/wgs_metrics
  sbg:fileTypes: TXT
  sbg:x: 953.853271484375
  sbg:y: 51.96418380737305
- id: shited_output_chart
  label: Shifted Output chart
  doc: Output chart.
  type: File?
  outputSource:
  - picard_collectwgsmetricswithnonzerocoverage_2_21_6_cwl1_0/output_chart
  sbg:fileTypes: PDF
  sbg:x: 868.3981323242188
  sbg:y: 181.16172790527344
- id: non_shifted_output_chart
  label: Non Shifted Output chart
  doc: Output chart.
  type: File?
  outputSource:
  - picard_collectwgsmetricswithnonzerocoverage_2_21_6_cwl1_1/output_chart
  sbg:fileTypes: PDF
  sbg:x: 950.7110595703125
  sbg:y: -711.778564453125
- id: non_shifted_wgs_metrics
  label: Non Shifted WGS metrics
  doc: Output metrics file.
  type: File?
  outputSource:
  - picard_collectwgsmetricswithnonzerocoverage_2_21_6_cwl1_1/wgs_metrics
  sbg:fileTypes: TXT
  sbg:x: 885.3248291015625
  sbg:y: -870.4193115234375
- id: non_shifted_variants
  label: Non Shifted Variants
  doc: Output variants in VCF or VCF.GZ format.
  type: File?
  outputSource:
  - gatk_mutect2_non_shifted_mt/out_variants
  sbg:fileTypes: VCF, VCF.GZ
  sbg:x: 908.877197265625
  sbg:y: -574.6871337890625
- id: non_shifted_out_stats
  label: Non Shifted Mutect2 Output stats
  doc: Output stat file.
  type: File?
  outputSource:
  - gatk_mutect2_non_shifted_mt/out_stats
  sbg:fileTypes: STATS, VCF.GZ.STATS, VCF.STATS
  sbg:x: 1010.8218994140625
  sbg:y: -459.2934265136719
- id: shifted_out_variants
  label: Shifted Output variants
  doc: Output variants in VCF or VCF.GZ format.
  type: File?
  outputSource:
  - gatk_mutect2_shifted_mt/out_variants
  sbg:fileTypes: VCF, VCF.GZ
  sbg:x: 1163.3890380859375
  sbg:y: -268.1025085449219
- id: shifted_out_stats
  label: Shifted Mutect2 Output stats
  doc: Output stat file.
  type: File?
  outputSource:
  - gatk_mutect2_shifted_mt/out_stats
  sbg:fileTypes: STATS, VCF.GZ.STATS, VCF.STATS
  sbg:x: 1163.3890380859375
  sbg:y: -121.05300903320312

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
  sbg:x: -316.7553405761719
  sbg:y: -342.0967102050781
- id: revert_sam
  label: revert-sam
  in:
  - id: bam
    source: subset_bam_to_chrom_m/chrM_bam
  run: mitochondria-pipeline.cwl.steps/revert_sam.cwl
  out:
  - id: unaligned_bam
  sbg:x: -106.36557006835938
  sbg:y: -379.2901916503906
- id: gatk_samtofastq
  label: GATK SamToFastq
  in:
  - id: in_alignments
    source: revert_sam/unaligned_bam
  run: mitochondria-pipeline.cwl.steps/gatk_samtofastq.cwl
  out:
  - id: out_reads
  - id: unmapped_reads
  sbg:x: 101.75660705566406
  sbg:y: -304.56036376953125
- id: bwa_mem_bundle
  label: BWA MEM Bundle 0.7.15 CWL1.0
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
  sbg:x: 321.1471862792969
  sbg:y: -440.2679138183594
- id: bwa_mem_bundle_1
  label: BWA MEM Bundle 0.7.15 CWL1.0
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
  sbg:x: 373.1943359375
  sbg:y: -85.68302154541016
- id: picard_collectwgsmetricswithnonzerocoverage_2_21_6_cwl1_0
  label: Picard CollectWgsMetricsWithNonZeroCoverage CWL1.0
  in:
  - id: chart_output
    default: shifted
  - id: include_bq_histogram
    default: 'true'
  - id: in_alignments
    source: bwa_mem_bundle_1/aligned_reads
  - id: in_reference
    source: in_reference_1
  run: |-
    mitochondria-pipeline.cwl.steps/picard_collectwgsmetricswithnonzerocoverage_2_21_6_cwl1_0.cwl
  out:
  - id: output_chart
  - id: wgs_metrics
  - id: theoretical_sensitivity_out_file
  sbg:x: 703.9730834960938
  sbg:y: 48.08837127685547
- id: picard_collectwgsmetricswithnonzerocoverage_2_21_6_cwl1_1
  label: Picard CollectWgsMetricsWithNonZeroCoverage CWL1.0
  in:
  - id: in_alignments
    source: bwa_mem_bundle/aligned_reads
  - id: in_reference
    source: non_shifed_in_reference
  run: |-
    mitochondria-pipeline.cwl.steps/picard_collectwgsmetricswithnonzerocoverage_2_21_6_cwl1_1.cwl
  out:
  - id: output_chart
  - id: wgs_metrics
  - id: theoretical_sensitivity_out_file
  sbg:x: 777.193115234375
  sbg:y: -737.9566650390625
- id: gatk_mutect2_non_shifted_mt
  label: GATK Mutect2 CWL1.0
  in:
  - id: in_alignments
    source:
    - bwa_mem_bundle/aligned_reads
  - id: in_reference_and_index
    source: non_shifed_in_reference
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
  sbg:x: 764.9480590820312
  sbg:y: -449.82147216796875
- id: gatk_mutect2_shifted_mt
  label: GATK Mutect2 CWL1.0
  in:
  - id: in_alignments
    source:
    - bwa_mem_bundle_1/aligned_reads
  - id: in_reference_and_index
    source: in_reference_1
  - id: annotation
    default:
    - StrandBiasBySample
  - id: read_filter
    default:
    - MateOnSameContigOrNoMappedMateReadFilter
    - MateUnmappedAndUnmappedReadFilter
  - id: max_mnp_distance
    default: 0
  scatter:
  - in_alignments
  run: mitochondria-pipeline.cwl.steps/gatk_mutect2_shifted_mt.cwl
  out:
  - id: out_variants
  - id: out_alignments
  - id: f1r2_counts
  - id: out_stats
  sbg:x: 847.5328979492188
  sbg:y: -226.8144073486328
sbg:appVersion:
- v1.2
- v1.0
sbg:content_hash: a76d0d5e28aabe3cea7922146f0cabaad49d1120f418dcb7b6ad4fd2afc93e34f
sbg:contributors:
- dave
sbg:createdBy: dave
sbg:createdOn: 1622052954
sbg:id: dave/build-mitochondria-pipeline/mitochondria-pipeline/11
sbg:image_url:
sbg:latestRevision: 11
sbg:modifiedBy: dave
sbg:modifiedOn: 1622647228
sbg:original_source: |-
  https://api.sb.biodatacatalyst.nhlbi.nih.gov/v2/apps/dave/build-mitochondria-pipeline/mitochondria-pipeline/11/raw/
sbg:project: dave/build-mitochondria-pipeline
sbg:projectName: 'BUILD: Mitochondria Pipeline'
sbg:publisher: sbg
sbg:revision: 11
sbg:revisionNotes: label mutect2
sbg:revisionsInfo:
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1622052954
  sbg:revision: 0
  sbg:revisionNotes:
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1622053106
  sbg:revision: 1
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1622053860
  sbg:revision: 2
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1622141554
  sbg:revision: 3
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1622141673
  sbg:revision: 4
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1622155388
  sbg:revision: 5
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1622160498
  sbg:revision: 6
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1622161030
  sbg:revision: 7
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1622161443
  sbg:revision: 8
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1622161723
  sbg:revision: 9
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1622647015
  sbg:revision: 10
  sbg:revisionNotes: added mutect2
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1622647228
  sbg:revision: 11
  sbg:revisionNotes: label mutect2
sbg:sbgMaintained: false
sbg:validationErrors: []
