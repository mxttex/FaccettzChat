const express = require("express");
const http = require("http");
const socketIo = require("socket.io"); //si basa su http
const firebase = require("firebase-admin");

const app = express();
const server = http.createServer(app);
const PORT = process.env.PORT || 3000;
const IP = process.env.IP || "0.0.0.0";

const io = socketIo(server, {
  cors: {
    origin: "*",
  },
});

io.on("connection", (socket) => {
  console.log("client connesso");

  var currentRoom = "";
  socket.on("disconnect", () => {
    console.log("Client disconnesso");
  });
  socket.on("join-room", (room, host) => {
    socket.leave(currentRoom);
    socket.join(room);
    console.log(`${host} si è connesso alla stanza ${room}.`);
    currentRoom = room;
  });

  socket.on("join-my-room", (room) => {
    socket.join(room);
    console.log(`Host connesso alla room ${room}`)
  });
  socket.on("leave-room", () => {
    socket.leave(currentRoom);
  });

  socket.on("sendMessage", (data) => {
    io.to(data.roomId).emit("message", data);
  });
});

server.listen(PORT, IP, () => {
  console.log("server in ascolto alla porta ", PORT);
});
