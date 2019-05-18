FROM nfcore/base:latest
LABEL maintainer="Phil Palmer"
LABEL authors="phil@lifebit.ai" \
      description="Docker image containing all the requirements for fastNGSadmix & iAdmix"

# Install dependencies
RUN apt-get update -y && apt-get install -y \
    build-essential \
    libz-dev \
    libncurses5-dev && \
    conda install -c bioconda bioconductor-snpstats

# Install iAdmix
RUN git clone https://github.com/vibansal/ancestry.git && \
    cd ancestry && \
    make && \
    cd ..

# Install fastNGSadmix
RUN git clone https://github.com/e-jorsboe/fastNGSadmix.git && \
    cd fastNGSadmix && \
    make && \
    cd ..

RUN cp /fastNGSadmix/fastNGSadmix /usr/local/bin && \
    cp /ancestry/runancestry.py /usr/local/bin && \
    chmod -R u+x /usr/local/bin