const express = require("express");
const http = require("http");
const socketIo = require("socket.io");
const admin = require("firebase-admin");
const { getAuth } = require("firebase-admin/auth");

var serviceAccount = ("C:\\Users\\matte\\Desktop\\importantissimo\\key.json")
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const app = express();
const server = http.createServer(app);
const PORT = process.env.PORT || 3000;
const IP = process.env.IP || "0.0.0.0";

const listAllUsers = async (nextPageToken) => {
  try {
    let result = await getAuth().listUsers(1000, nextPageToken);
    users = result.users.map(user => ({
      uid: user.uid,
      email: user.email,
      displayName: user.displayName || "Sconosciuto",
      photoURL : user.photoURL
    }));
    if (result.pageToken) {
      await listAllUsers(result.pageToken);
    }
  } catch (error) {
    console.error("Errore nel recupero degli utenti:", error);
  }
};

let users = listAllUsers();
var currentRoom = "";
//var room ="";

const io = socketIo(server, {
  cors: {
    origin: "*",
  },
});

io.on("connection", (socket) => {
  console.log("client connesso");

  socket.on("disconnect", () => {
    console.log("Client disconnesso");
  });

  socket.on("join-room", (room, host) => {
    if(currentRoom != "") {socket.leave(currentRoom)}
    socket.join(room);
    console.log(`${host} si è connesso alla stanza ${room}.`);
    currentRoom = room;
  });

  socket.on("join-my-room", (room) => {
    socket.join(room);
    console.log(`Host connesso alla room ${room}`);
    io.to(room).emit("receive-users", users);
  });

  socket.on("leave-room", () => {
    socket.leave(currentRoom);
  });

  socket.on("sendMessage", (data) => {
    io.to(data.roomId).emit("message", data);
  });
});

server.listen(PORT, IP, () => {
  console.log(`Server running at ${IP}:${PORT}`);
});
