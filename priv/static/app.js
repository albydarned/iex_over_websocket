var ansiUp = new AnsiUp;
var socket = new WebSocket("ws://localhost:4000/ws");
var cmdHistory = [];
var cmdHistoryIndex = 0;

socket.onerror = function(event) {
  console.error("Socket error");
  console.dir(event);
}

socket.onclose = function(event) {
  console.error("Socket close");
  console.dir(event);
}

socket.onopen = function(event) {
  console.log("Socket open");
}

socket.onmessage = function(event) {
  console.log(event.data);
  message = JSON.parse(event.data);

  switch(message.kind) {
    case "put_chars": {
      var html = ansiUp.ansi_to_html(message.data);
      var doc = document.getElementById("puts");
      var data = document.createElement("div");
      data.innerHTML = html;
      doc.appendChild(data);
      socket.send(JSON.stringify({kind: "put_chars", data: "ok"}))
    }
    case "get_line": {
      var text = ansiUp.ansi_to_text(message.data);
      var doc = document.getElementById("gets");
      doc.innerHTML = text;
    }
    case "get_geometry": {
      // socket.send(JSON.stringify({kind: "get_geometry", data: 80}))
    }
  }
}

var tabKeyPressed = false;
// Get the input field
var input = document.getElementById("gets_input");

// Execute a function when the user releases a key on the keyboard
input.addEventListener("keydown", function(event) {
  tabKeyPressed = event.keyCode === 9;
  if (tabKeyPressed) {
     event.preventDefault();
     return;
  }
});

input.addEventListener("keyup", function(event) {
  if (tabKeyPressed) {
    console.log("caught tab");
    event.preventDefault();
  } else if (event.keyCode === 13) {
    event.preventDefault();
    var doc = document.getElementById("puts");
    var div = document.createElement("div");
    div.innerHTML = document.getElementById("gets").innerHTML + " " + input.value;
    doc.appendChild(div);

    data = JSON.stringify({kind: "get_line", data: input.value});

    cmdHistory.push(input.value);
    cmdHistoryIndex = 0;

    socket.send(data);
    input.value = "";
  } else if(event.keyCode === 38) { // up
    input.value = cmdHistory[cmdHistoryIndex--] || "";
  } else if(event.keyCode === 40) { // down
    input.value = cmdHistory[cmdHistoryIndex++] || "";
  }
});

Window["shell_socket"] = socket;
