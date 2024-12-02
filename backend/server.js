const express = require("express");
const http = require('http');
const socketIo = require("socket.io");  //si basa su http

const app = express();
const server = http.createServer(app);
const PORT = process.env.PORT || 3000

const io = socketIo(server, {
    cors : {
        origin: '*'
    }
})

server.listen(PORT, '127.0.0.1', () => {
    console.log("server in ascolto alla porta ", PORT)
})
io.on('connection', socket => {
    console.log("client connesso");

    socket.on("disconnect", () => {
        console.log("Client disconesso")
    })

    socket.on('sendMessage', (data) => {
        console.log(`Messaggio inviato: ${data}`)
        io.emit('message', data)
    })
})