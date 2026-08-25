FROM elixir:1.18-alpine AS build
WORKDIR /src
ENV MIX_ENV=prod
COPY mix.exs .formatter.exs ./
COPY lib ./lib
RUN mix compile --warnings-as-errors && mix escript.build

FROM elixir:1.18-alpine AS runtime
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app
COPY --from=build /src/sky_loyalty /app/sky_loyalty
USER app
ENTRYPOINT ["/app/sky_loyalty"]
CMD ["help"]
