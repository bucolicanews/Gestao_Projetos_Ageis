# Build stage
FROM node:20-alpine AS builder

WORKDIR /app
RUN apk add --no-cache bash curl git

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

# Production stage
FROM node:20-alpine

WORKDIR /app

COPY --from=builder /app/.output ./.output
COPY --from=builder /app/package*.json ./

EXPOSE 3000

ENV HOST=0.0.0.0 PORT=3000 NODE_ENV=production

CMD ["node", ".output/server/index.mjs"]