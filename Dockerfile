FROM node:22-alpine AS base

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable
COPY --chown=node:node . /app
WORKDIR /app

FROM base AS prod-deps
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --prod --frozen-lockfile --package-import-method copy

USER node

FROM base AS build
ENV NODE_ENV=development
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile --package-import-method copy
RUN ls -al /app/node_modules/@angular
RUN pnpm build

USER node

FROM base
ENV NODE_ENV=production
COPY --from=prod-deps --chown=node:node /app/node_modules /app/node_modules
COPY --from=build --chown=node:node /app/dist/qatest/* /app

EXPOSE 80 443

CMD [ "node", "/app/server/server.mjs" ]