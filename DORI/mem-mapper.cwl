#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow

requirements:
  - class: ScatterFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement

inputs:
  reffa:
    type: File
    secondaryFiles:
      - .amb
      - .ann
      - .bwt
      - .pac
      - .sa
  fastqs: File[]
  fastq2s:
    type:
      - type: array
        items: ["null", File]
  output_bam: string
  threads:
    type: int
    default: 1
  K:
    type: int
    default: 100000000
  Y:
    type: boolean
    default: true
  Rs: string[]

steps:
  #########################################################################
  # 1. Map each fastq (se) or pair of fastqs (pe) seperately with bwa mem #
  #########################################################################
  bwa_mem:
    run: ../CommandLineTools/bwa-mem.cwl
    scatter: [fastq, fastq2, R]
    scatterMethod: dotproduct
    in:
      reffa: reffa
      fastq: fastqs
      fastq2: fastq2s
      output_sam:
        valueFrom: |
          ${
            var s = inputs.fastq.nameroot;
            s = s.replace(/\.fq/g, "");
            s = s.replace(/\.fastq/g, "");
            return s + ".mapped.sam";
          }
      threads: threads
      K: K
      Y: Y
      R: Rs
    out:
      [mapped_sam]

  ################################################################
  # 2. Merge all bwa-mem mapped bams into a queryname sorted bam #
  ################################################################
  merge_and_qsort:
    run: ../CommandLineTools/gatk-MergeSamFiles.cwl
    in:
      input_bams: bwa_mem/mapped_sam
      sort_order:
        valueFrom: $("queryname")
      output_bam:
        source: output_bam
        valueFrom: $(self.replace(".bam", ".qsorted.bam"))
    out:
      [merged_bam]

  ###############
  # 3. MarkDups #
  ###############
  markdups:
    run: ../CommandLineTools/gatk-MarkDuplicates.cwl
    in:
      input_bam: merge_and_qsort/merged_bam
      metrics_file:
        source: output_bam
        valueFrom: $(self.replace(".bam", ".markdup.txt"))
      output_bam:
        source: output_bam
        valueFrom: $(self.replace(".bam", ".qsorted.md.bam"))
    out:
      [marked_bam, metrics_file]

  #####################################
  # 4. Coordinate sort the marked bam #
  #####################################
  csort:
    run: ../CommandLineTools/gatk-SortSam.cwl
    in:
      input_bam: markdups/marked_bam
      output_bam: output_bam
      sort_order:
        valueFrom: $("coordinate")
    out:
      [sorted_bam]

  ##########################
  # 5. Create index (.bai) #
  ##########################
  index:
    run: ../CommandLineTools/samtools-index.cwl
    in:
      bamfile: csort/sorted_bam
    out:
      [baifile]

  # 6. samtools flagstat?
  # 7. md5sum?

outputs:
  # For debugging
  #mapped_sams:
  #  type: File[]
  #  outputSource: bwa_mem/mapped_sam
  #merged_bam:
  #  type: File
  #  outputSource: merge_and_qsort/merged_bam
  #marked_bam:
  #  type: File
  #  outputSource: markdups/marked_bam
  metrics_file:
    type: File
    outputSource: markdups/metrics_file
  final_bam:
    type: File
    outputSource: csort/sorted_bam
  baifile:
    type: File
    outputSource: index/baifile
