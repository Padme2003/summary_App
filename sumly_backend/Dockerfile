# Dockerfile para Render - Soluciona problemas con pdf-parse y canvas

FROM node:18-bullseye

# Instalar dependencias del sistema necesarias para canvas y pdf-parse
RUN apt-get update && apt-get install -y \
    build-essential \
    libcairo2-dev \
    libpango1.0-dev \
    libjpeg-dev \
    libgif-dev \
    librsvg2-dev \
    python3 \
    g++ \
    make \
    && rm -rf /var/lib/apt/lists/*

# Crear directorio de la app
WORKDIR /app

# Copiar package files
COPY package*.json ./

# Instalar dependencias
RUN npm ci --production

# Copiar el resto del código
COPY . .

# Crear directorios necesarios
RUN mkdir -p uploads

# Exponer puerto
EXPOSE 5000

# Comando de inicio
CMD ["npm", "start"]
