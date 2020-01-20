(function() {
  var ws = new WebSocket("ws://localhost:1338");
  
  var form = document.querySelector('.form');

  form.onsubmit = function() {
    var input = document.querySelector('.input'); 
    var text = input.value;
    ws.send(text);
    input.value = '';
    input.focus();
    return false;
  }
  
  ws.onmessage = function(msg) {
    var response = msg.data;
    var messageList = document.querySelector('.messages');
    var li = document.createElement('li');
    li.textContent = response;
    messageList.appendChild(li);
  }
}());