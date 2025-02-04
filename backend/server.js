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

    var currentRoom = "";
    socket.on("disconnect", () => {
        console.log("Client disconnesso")
    })
    socket.on('join-room', room => {
        socket.leave(currentRoom);
        socket.join(room);
        console.log(`Connesso alla stanza ${room}.`)
        currentRoom = room;
    })


    socket.on('sendMessage', (data) => {
        // switch(currentRoom){
        //     case "broadcast":
        //         io.broadcast.emit("message", data) //mando in broadcast
        //         break;
        //     default:
        //         //invio il messaggio nella stanza in cui siamo connessi
        //         io.to(currentRoom).emit("message", data) 
        // }   
        io.to(currentRoom).emit("message", data)
    })

})


server.listen(PORT, '192.168.0.124', () => {
    console.log("server in ascolto alla porta ", PORT)
})