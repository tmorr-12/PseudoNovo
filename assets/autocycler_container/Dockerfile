FROM mambaorg/micromamba:latest as builder

USER root
COPY --chmod=755 install_tools.sh /usr/local/bin/
USER $MAMBA_USER

FROM builder as builder_flye
RUN install_tools.sh flye

FROM builder as builder_metamdbg
RUN install_tools.sh metamdbg

FROM builder as builder_necat
RUN install_tools.sh necat

FROM builder as builder_miniasm
RUN install_tools.sh miniasm miniasm bioconda::minipolish racon

FROM builder as builder_nextdenovo
RUN install_tools.sh nextdenovo nextdenovo nextpolish

FROM builder as builder_raven
RUN install_tools.sh raven raven-assembler


FROM mambaorg/micromamba:latest

USER root

RUN apt-get update && \
    apt-get install -y curl libgomp1 procps && \
    rm -rf /var/lib/apt/lists/*

USER $MAMBA_USER

RUN micromamba create -y -n autocycler python && \
    micromamba clean --all --yes

ENV PATH="/opt/conda/envs/autocycler/bin:$PATH"

RUN set -eux; \
    URL=$(curl -fsSL \
        https://api.github.com/repos/rrwick/Autocycler/releases/latest \
        | python -c 'import json,sys; print(next(a["browser_download_url"] for a in json.load(sys.stdin)["assets"] if "linux-x86_64-musl" in a["name"] and a["name"].endswith(".tar.gz")))'); \
    curl -fsSL -o autocycler.tar.gz "$URL"; \
    tar -xzf autocycler.tar.gz; \
    mv autocycler /opt/conda/envs/autocycler/bin/; \
    rm autocycler.tar.gz


# External tools
COPY --from=docker.io/staphb/minimap2 \
    /usr/local/bin/minimap2 \
    /usr/local/bin/minimap2

COPY --from=docker.io/troder/lja \
    /opt/LJA/bin/lja \
    /usr/local/bin/lja


# Assembler environments
COPY --from=builder_raven \
    /opt/conda/envs/raven \
    /opt/conda/envs/raven

COPY --from=builder_flye \
    /opt/conda/envs/flye \
    /opt/conda/envs/flye

COPY --from=builder_metamdbg \
    /opt/conda/envs/metamdbg \
    /opt/conda/envs/metamdbg

COPY --from=builder_necat \
    /opt/conda/envs/necat \
    /opt/conda/envs/necat

COPY --from=builder_miniasm \
    /opt/conda/envs/miniasm \
    /opt/conda/envs/miniasm

COPY --from=builder_nextdenovo \
    /opt/conda/envs/nextdenovo \
    /opt/conda/envs/nextdenovo

CMD ["/bin/sh", "-c", "autocycler --help"]