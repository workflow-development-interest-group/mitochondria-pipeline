# mitochondria-pipeline  
  
 Based on [mitochondria m2 wdl](https://github.com/broadinstitute/gatk/tree/2e6045a259ed2ded3e9036a5b44a1f8ba330860d/scripts/mitochondria_m2_wdl)
   
  Steps  
  1.  [SubsetBamToChrM](https://github.com/cwl-apps/mitochondria-pipeline/blob/60097661bd453cd7fbfa6c26c58f6b2757b4e833/scripts/MitochondriaPipeline.wdl#L192)
  2.  RevertSam
  3.  AlignAndCall  
  4.  --- AlignToMt/AlignToShiftedMT [AlignAndMarkDuplicates](https://github.com/cwl-apps/mitochondria-pipeline/blob/508b4d6ca88d9182d0277fb90c8b8e9ae70fb1c5/scripts/AlignmentPipeline.wdl#L56)  
      ------- picard samtofastq  
      ------- bwa-mem  
      ------- picard mark duplicates  
      ------- picard sort sam  
  6.  --- scatter: CollectWgsMetrics   
  7.  --- scatter: Call M2  
  8. --- scater?: LiftoverAndCombineVcfs
  9. --- MergeStats
  13. --- InitialFilter
  14. --- SplitMultiAllelicsAndRemoveNonPassSites
  15. --- GetContamination
  16. --- FilterContamination
  17. --- FilterNuMTs
  18. --- FilterLowHetSites
  20.  ConvergeAtEveryBase
  21.  SplitMultiAllelicSites

[Dashboard ⋅ BUILD: Mitochondria Pipeline](https://platform.sb.biodatacatalyst.nhlbi.nih.gov/u/dave/build-mitochondria-pipeline/) 

  
https://console.cloud.google.com/storage/browser/gcp-public-data--broad-references/hg38/v0/chrM?pageState=(%22StorageObjectListTable%22:(%22f%22:%22%255B%255D%22))&prefix=&forceOnObjectsSortingFiltering=false
  
 ![](https://firebasestorage.googleapis.com/v0/b/firescript-577a2.appspot.com/o/imgs%2Fapp%2FSB_engagement%2Fp1xpMtv3U0.png?alt=media&token=242926fb-258b-4c01-baf3-7f6efca04b91)
