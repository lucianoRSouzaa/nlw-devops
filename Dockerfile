# imagem node:20 - com muito recurso (1GB) - OS - Debian
# AS - para criar um apelido para um stage, já que vamos trabalhar com multi-stage build
# primeiro stage (base) - preparativo
FROM node:20 AS base

RUN npm i -g pnpm

# segundo stage (dependencies) - instalação de dependências
FROM base AS dependencies

# cria um diretório para a aplicação no OS do container
WORKDIR /usr/src/app

# copia os arquivos package.json e pnpm-lock.yaml para ./ (diretório da aplicação (WORKDIR))
COPY package.json pnpm-lock.yaml ./

RUN pnpm install

# terceiro stage (build) - build da aplicação
FROM base AS build

WORKDIR /usr/src/app

# copia todos os arquivos da aplicação para o . (raiz do WORKDIR) 
COPY . .
# pega os arquivos node_modules do stage dependencies e copia para o WORKDIR/node_modules
COPY --from=dependencies /usr/src/app/node_modules ./node_modules

RUN pnpm build
# executa o comando de prune para remover as dependências de desenvolvimento
RUN pnpm prune --prod

# imagem node:20-alpine3.19 com menos recurso (50MB) - OS - Alpine
FROM node:20-alpine3.19 AS deploy

# cria um diretório para a aplicação no OS do container
WORKDIR /usr/src/app

# instala o pnpm e o prisma globalmente
RUN npm i -g pnpm prisma

# copia dist do stage build para o WORKDIR/dist
COPY --from=build /usr/src/app/dist ./dist
# copia os arquivos node_modules, package.json e prisma para o WORKDIR
COPY --from=build /usr/src/app/node_modules ./node_modules
COPY --from=build /usr/src/app/package.json ./package.json
COPY --from=build /usr/src/app/prisma ./prisma

RUN pnpm prisma generate

# expõe a porta 3333
EXPOSE 	3333

# executa o comando start
CMD [ "pnpm", "start" ]
