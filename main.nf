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
  Make channel(s) for reference panel(s)
---------------------------------------------------*/

Channel.fromPath(params.iadmix_ref)
           .ifEmpty { exit 1, "iAdmix reference panel file not found: ${params.iadmix_ref}" }
           .set { iadmix_ref }

Channel.fromPath(params.fastngsadmix_fname)
           .ifEmpty { exit 1, "fastNGSadmix reference panel file not found: ${params.fastngsadmix_fname}" }
           .set { fastngsadmix_fname }
Channel.fromPath(params.fastngsadmux_nname)
           .ifEmpty { exit 1, "fastNGSadmix Nname file not found: ${params.fastngsadmux_nname}" }
           .set { fastngsadmux_nname }
fastngsadmix_ref = fastngsadmix_fname.merge(fastngsadmux_nname)

/*--------------------------------------------------
  Convert from 23AndMe format to plink
---------------------------------------------------*/

process convert_23andMe_to_plink {
  tag "${name}"
  container 'lifebitai/ancestry'

  input:
  set val(name), file(genotype_file) from genoChannel

  output:
  set val(name), file("${name}.map"), file("${name}.ped") into plinkGenotypes, plinkGenotypesCombine

  script:
  """
  23andme-to-plink.py $genotype_file
  """
}

/*--------------------------------------------------
  Generate plink binary files
---------------------------------------------------*/

process plink {
  tag "${name}"
  container 'alliecreason/plink:1.90'
  publishDir "${params.outdir}/plink", mode: 'copy'

  input:
  set val(name), file(map), file(ped) from plinkGenotypes

  output:
  set val(name), file("${name}.map"), file("${name}.ped"), file("${name}.bed"), file("${name}.bim"), file("${name}.fam") into plink, plink2

  script:
  """
  plink --file ${name} --list-duplicate-vars ids-only suppress-first
  plink --file ${name} --recode -exclude plink.dupvar --out ${name}
  plink --file ${name} --out ${name}
  """
}

plink
    .combine(fastngsadmix_ref)
    .set { fastngsadmix }
plink2
    .combine(iadmix_ref)
    .set { iadmix }

/*--------------------------------------------------
  Estimate admixture proportions from plink files
---------------------------------------------------*/

process fastNGSadmix {
  tag "${name}"
  container 'lifebitai/ancestry'
  publishDir "${params.outdir}/fastNGSadmix", mode: 'copy'

  input:
  set val(name), file(map), file(ped), file(bed), file(bim), file(fam), file(ref), file(nname) from fastngsadmix

  output:
  set val(name), file("${name}.log"), file("${name}.qopt") into fastngsadmix_out

  script:
  """
  fastNGSadmix -plink ${name} -fname $ref -Nname $nname -out ${name} -whichPops all
  """
}

/*--------------------------------------------------
  Estimate admixture coefficients from plink files
---------------------------------------------------*/

process iAdmix {
  tag "${name}"
  container 'lifebitai/ancestry'
  publishDir "${params.outdir}/iAdmix", mode: 'copy'

  input:
  set val(name), file(map), file(ped), file(bed), file(bim), file(fam), file(ref) from iadmix

  output:
  set val(name), file("out.${name}.input"), file("out.${name}.input.ancestry"), file("iAdmix.txt") into iadmix_out

  script:
  """
  runancestry.py --plink ${name} -f $ref -o out --path /ancestry/
  cp .command.log iAdmix.txt
  """
}

/*--------------------------------------------------
  Generate table report to display on Deploit
---------------------------------------------------*/

process table_report {
  publishDir "${params.outdir}/Visualisations", mode: 'copy'
  container 'lifebitai/vizjson'

  input:
  set val(name), file(log), file(qopt) from fastngsadmix_out

  output:
  file '.report.json' into report

  script:
  """
  sed -i 's/[ \t]*\$//' $qopt
  sed 's/ /,/g' $qopt > ${name}.csv
  csv2json.py ${name}.csv "Ancestry admixture proportion estimates generated from ${name}.txt 23andMe file" ${name}.json
  combine_reports.py .
  """
}