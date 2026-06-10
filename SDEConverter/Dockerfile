# syntax=docker/dockerfile:1

FROM swift:6.0-noble AS build

WORKDIR /app

COPY Package.swift Package.resolved ./
COPY SDEConverter/*.swift ./SDEConverter/
COPY SDEConverter/Tables ./SDEConverter/Tables
COPY SDEConverter/effect_patches.json ./SDEConverter/effect_patches.json

# Keep the Package.swift exclude path valid without copying this Dockerfile into the build context.
RUN touch SDEConverter/Dockerfile
RUN swift build -c release --product SDEConverter

FROM swift:6.0-noble

WORKDIR /work

COPY --from=build /app/.build/release/SDEConverter /usr/local/bin/SDEConverter
COPY SDEConverter/effect_patches.json /opt/sdeconverter/effect_patches.json

RUN mkdir -p /sde /output

VOLUME ["/sde", "/output"]

ENTRYPOINT ["stdbuf", "-oL", "-eL", "SDEConverter"]
CMD ["--sde-dir", "/sde", "--effect-patches", "/opt/sdeconverter/effect_patches.json", "--output-file", "/output/EVE.sqlite"]
