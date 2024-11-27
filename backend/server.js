const express = require("express");
const app = express();
const port = 3000;

const bodyParser = require('body-parser');

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({extended: true}));

app.listen(port, () =>{
    console.log("Server in ascolto alla porta", port)
    
})

app.post('/send', (req, res) => {
    const request = req.body;
    console.log(request)
    const response = {
        status : 'success',
        message : "json ricevuto con successo",
        data: request
    };
    res.json(response);   
})