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

io.on('connection', socket => {
    console.log("client connesso");

    socket.join("room1")
    socket.on("disconnect", () => {
        console.log("Client disconnesso")
    })

    // socket.on('sendMessage', (data) => {
    //     const mesg = JSON.stringify(data)
    //     const sender = data.author
    //     console.log(`Messaggio inviato: ${mesg}`)
    //     socket.broadcast.emit('message', data)
    //     console.log("Autore ", sender);
    //     //socket.to(sender.id).emit('message', data); 
    // })
    socket.on('sendMessage', (data) => {
        console.log("Dati ricevuti:", data); // Debug
        // socket.broadcast.emit('message', data);
        io.emit('message', data);
    });
})


server.listen(PORT, '192.168.0.124', () => {
    console.log("server in ascolto alla porta ", PORT)
})