# Usa un'immagine base di Node.js
FROM node:17

# Imposta la directory di lavoro nel container
WORKDIR /backend

# Copia i file package.json e package-lock.json
COPY package*.json ./

# Installa le dipendenze
RUN npm install

# Copia il resto dell'applicazione
COPY . .

# Espone la porta su cui il server Node.js sarà in ascolto
EXPOSE 3000

# Comando per avviare l'applicazione
CMD ["node", "server.js"]
