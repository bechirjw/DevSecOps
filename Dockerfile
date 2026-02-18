FROM node:18-alpine

# Patch OS packages (fixes OpenSSL CVEs if Alpine repo has updates)
RUN apk update && apk upgrade --no-cache

WORKDIR /app
COPY package*.json ./

# Prefer modern flag (equivalent to production-only)
RUN npm ci --omit=dev

COPY . .
EXPOSE 3000
CMD ["npm", "start"]
