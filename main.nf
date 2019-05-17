#!/usr/bin/env nextflow
/*
========================================================================================
                         lifebit-ai/fast-ngs-admix
========================================================================================
 lifebit-ai/fast-ngs-admix Ancestry Pipeline.
 #### Homepage / Documentation
 https://github.com/lifebit-ai/fast-ngs-admix
----------------------------------------------------------------------------------------
*/

/*--------------------------------------------------
  Genotype input files from kindof 23AndMe style
---------------------------------------------------*/

if(params.genotypes_path) {
  if(params.genotypes_path.endsWith(".txt")) {

     Channel
        .fromPath( "${params.genotypes_path}" )
        .map { row -> [ file(row).baseName, [ file( row ) ] ] }
        .ifEmpty { exit 1, "${params.genotypes_path} not found"}
        .set { genoChannel }

  } else {
    Channel
        .fromFilePairs("${params.genotypes_path}/*", size: 1)
        .ifEmpty { exit 1, "${params.genotypes_path}/*.txt not found"}
        .set{genoChannel}
  }
} else {
  exit 1, "please specify --genotypes OR --genotypes_path"
}

/*--------------------------------------------------
  Make channel(s) for FASTA input files
---------------------------------------------------*/

Channel.fromPath(params.fasta)
           .ifEmpty { exit 1, "FASTA reference file not found: ${params.fasta}" }
           .set { fasta }
Channel.fromPath(params.fai)
           .ifEmpty { exit 1, "FASTA index file not found: ${params.fai}" }
           .set { fai }

/*--------------------------------------------------
  Convert from 23AndMe format to VCF
---------------------------------------------------*/

process bcftools {
  tag "${name}"
  container 'lifebitai/bcftools'

  input:
  set val(name), file(genotype_file) from genoChannel
  file fasta from fasta
  file fai from fai

  output:
  set val(name), file("${name}.vcf.gz") into vcfGenotypes

  script:
  """
  # convert ancestry files
  sed 's/23/X/g; s/24/Y/g; s/25/MT/g; s/26/X/g' ${genotype_file} > tmp.txt
  # for lines where genotype contains one allele (non-autosomal chrs), duplicate the allele so that it's homozygous
  awk '{OFS="\t"; if (((length(\$4) == 2 ))) \$4=\$4\$4; print \$0}' tmp.txt > ${genotype_file}
  bcftools convert --tsv2vcf ${genotype_file}  -f ${fasta} -s $name -Oz -o ${name}.tmp.vcf.gz
  bcftools filter --set-GTs . -e 'FMT/GT="."' -Oz -o ${name}.filt.vcf.gz ${name}.tmp.vcf.gz
  bcftools view -t "^MT" -f PASS -Oz -o ${name}.vcf.gz ${name}.filt.vcf.gz
  """
}

/*--------------------------------------------------
  Convert from 23AndMe format to VCF
---------------------------------------------------*/

process vcftools {
  tag "${name}"
  container 'lifebitai/vcftools'

  input:
  set val(name), file(vcf) from vcfGenotypes

  output:
  set val(name), file("*") into beagle_gl
  // set val(name), file("${name}.vcf.gz") into beagle_gl

  script:
  """
  gzip -fd $vcf
  vcftools --vcf ${name}.vcf --out test --BEAGLE-GL --chr 1,2
  """
}