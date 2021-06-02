cwlVersion: v1.2
class: Workflow
label: mitochondria-pipeline
$namespaces:
  sbg: https://sevenbridges.com

requirements:
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
  sbg:x: 65
  sbg:y: -575
- id: shifted_reference_index_tar
  label: Shifted Reference Index TAR
  doc: Reference fasta file with its BWA index files packed in a TAR archive.
  type: File
  sbg:fileTypes: TAR
  sbg:x: 69.43341064453125
  sbg:y: -56.54893112182617
- id: non_shifed_in_reference
  label: Non Shifted Reference
  doc: |-
    The reference sequence in FASTA format to which reads will be aligned.  Required.
  type: File
  sbg:fileTypes: FASTA, FA, FASTA.GZ
  sbg:x: 592.3997192382812
  sbg:y: -792.1829223632812
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
  sbg:x: 603.4678955078125
  sbg:y: 77.78815460205078
- id: shifted_wgs_metrics
  label: Shifted WGS metrics
  doc: Output metrics file.
  type: File?
  outputSource:
  - picard_collectwgsmetricswithnonzerocoverage_2_21_6_cwl1_0/wgs_metrics
  sbg:fileTypes: TXT
  sbg:x: 956.5830078125
  sbg:y: -167.07359313964844
- id: shited_output_chart
  label: Shifted Output chart
  doc: Output chart.
  type: File?
  outputSource:
  - picard_collectwgsmetricswithnonzerocoverage_2_21_6_cwl1_0/output_chart
  sbg:fileTypes: PDF
  sbg:x: 965.0188598632812
  sbg:y: 91.06881713867188
- id: non_shifted_output_chart
  label: Non Shifted Output chart
  doc: Output chart.
  type: File?
  outputSource:
  - picard_collectwgsmetricswithnonzerocoverage_2_21_6_cwl1_1/output_chart
  sbg:fileTypes: PDF
  sbg:x: 1072.8206787109375
  sbg:y: -437.9896240234375
- id: non_shifted_wgs_metrics
  label: Non Shifted WGS metrics
  doc: Output metrics file.
  type: File?
  outputSource:
  - picard_collectwgsmetricswithnonzerocoverage_2_21_6_cwl1_1/wgs_metrics
  sbg:fileTypes: TXT
  sbg:x: 983.2622680664062
  sbg:y: -733.200927734375

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
  sbg:x: -302.4132080078125
  sbg:y: -326.0962219238281
- id: revert_sam
  label: revert-sam
  in:
  - id: bam
    source: subset_bam_to_chrom_m/chrM_bam
  run: mitochondria-pipeline.cwl.steps/revert_sam.cwl
  out:
  - id: unaligned_bam
  sbg:x: -101.16980743408203
  sbg:y: -331.6811218261719
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
  sbg:x: 719.5621948242188
  sbg:y: -41.6231575012207
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
  sbg:x: 789.0736083984375
  sbg:y: -563.7018432617188
sbg:appVersion:
- v1.2
- v1.0
sbg:content_hash: aefb417a68dc43a7bab8a04b2dcdabcd1b5b0f95c8ef00531479b7f4e0459c40f
sbg:contributors:
- dave
sbg:createdBy: dave
sbg:createdOn: 1622052954
sbg:id: dave/build-mitochondria-pipeline/mitochondria-pipeline/9
sbg:image_url:
sbg:latestRevision: 9
sbg:modifiedBy: dave
sbg:modifiedOn: 1622161723
sbg:original_source: |-
  https://api.sb.biodatacatalyst.nhlbi.nih.gov/v2/apps/dave/build-mitochondria-pipeline/mitochondria-pipeline/9/raw/
sbg:project: dave/build-mitochondria-pipeline
sbg:projectName: 'BUILD: Mitochondria Pipeline'
sbg:publisher: sbg
sbg:revision: 9
sbg:revisionNotes: ''
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
sbg:sbgMaintained: false
sbg:validationErrors: []
