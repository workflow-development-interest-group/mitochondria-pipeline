# mitochondria-pipeline  
  
 Based on [mitochondria m2 wdl](https://github.com/broadinstitute/gatk/tree/2e6045a259ed2ded3e9036a5b44a1f8ba330860d/scripts/mitochondria_m2_wdl)
   
  Steps  
  1.  [SubsetBamToChrM](https://github.com/cwl-apps/mitochondria-pipeline/blob/60097661bd453cd7fbfa6c26c58f6b2757b4e833/scripts/MitochondriaPipeline.wdl#L192)
  2.  RevertSam
  3.  AlignAndCall  
  4.  --- AlignToMt (AlignAndMarkDuplicates)
  7.  --- AlignToShiftedMt (AlignAndMarkDuplicates)
  8.  --- scatter: CollectWgsMetrics 
  9.  --- scatter: Call M2  
  11. --- scater?: LiftoverAndCombineVcfs
  12. --- MergeStats
  13. --- InitialFilter
  14. --- SplitMultiAllelicsAndRemoveNonPassSites
  15. --- GetContamination
  16. --- FilterContamination
  17. --- FilterNuMTs
  18. --- FilterLowHetSites
  20.  ConvergeAtEveryBase
  21.  SplitMultiAllelicSites

[Dashboard ⋅ BUILD: Mitochondria Pipeline](https://platform.sb.biodatacatalyst.nhlbi.nih.gov/u/dave/build-mitochondria-pipeline/) 
