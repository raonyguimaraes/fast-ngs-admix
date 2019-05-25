# fast-ngs-admix

This Nextflow pipeline estimates ancestry/admixture proportions of 23andMe files using the tools [fastNGSadmix](https://github.com/e-jorsboe/fastNGSadmix) & [iAdmix](https://github.com/vibansal/ancestry)


## Quick Start
The tool(s) can be run on:
* [the command line](#running-on-the-command-line)
* [Deploit](#deploit) (recommended)

## Running on the command line

### Dependencies 
[Nextflow](https://www.nextflow.io/)
[Docker](https://www.docker.com/)

An example run of the pipeline on the command line may look like this:

```bash
nextflow run lifebit-ai/fast-ngs-admix --genotypes_path s3://lifebit-featured-datasets/modules/ancestry/uk35C650_20170608144013.txt
```
The only required parameter is a 23andMe file, specified using the `genotypes_path` parameter. This can be a single 23andMe file or a folder conttaining 23andMe files.

## Deploit

Deploit is a bioinformatics platform, developed by Lifebit, where you can run your analysis over the Cloud/AWS.

It is free for indivudal users to [sign-up](https://deploit.lifebit.ai/register)

You can run this pipeline under the modules section on the pipelines page, where this pipeline is named `New ancestry`. See an example job [here]() including the output of the pipelines

## Testdata
Testdata & reference files including the reference panel(s) are stored on the AWS S3 bucket [`s3://lifebit-featured-datasets/modules/ancestry/`](https://s3.console.aws.amazon.com/s3/buckets/lifebit-featured-datasets/modules/ancestry/?region=eu-west-1&tab=overview). This also includes an example 23andMe file.

## Other Paramters
`--fastngsadmix_fname` reference panel for fastNGSadmix, default is `refPanel_k27.txt`

`--fastngsadmux_nname` Nname reference file fastNGSadmix, default is `nInd_k27.txt`

`--iadmix_ref` reference panel for iAdmix, default is `k27.iadmix`

`--tool` select with tool to run (`fastngsadmix`, `iadmix` or both), default is `fastngsadmix,iadmix`

`--outdir` directory to save results to, default is `results`