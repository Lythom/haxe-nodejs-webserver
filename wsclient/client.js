(function () {
  var ws = new WebSocket("ws://localhost:1338");

  var chatform = document.querySelector('.chatform');
  var loginform = document.querySelector('.loginform');
  var registerform = document.querySelector('.registerform');
  document.querySelector('#chat').style.display = 'none';

  async function doLogging(login, password) {
    const loginResponse = await fetch('http://localhost:1337/login', {
      method: 'POST',
      body: {
        "username": "newUser",
        "password": "newPassword"
      },
      headers: {
        'Content-Type': 'application/json'
      }
    });
    const loginResponseValue = await loginResponse.text();
    if (loginResponseValue != "OK") {
      document.querySelector('.error').textContent = loginResponseValue;
      return;
    }

    const ticketResponse = await fetch('http://localhost:1337/wsTicket', {
      method: 'GET'
    });

    const ticketResponseValue = await loginResponse.text();
    if (loginResponse.ok) {
      ws.send(ticketResponseValue);
      document.querySelector('#login').style.display = 'none';
      document.querySelector('#chat').style.display = 'block';
      document.querySelector('input[name=message]').focus();

    } else {
      document.querySelector('.error').textContent = ticketResponseValue;
    }
  }

  loginform.onsubmit = function (e) {
    e.preventDefault();
    var loginInput = loginform.querySelector('input[name=login]');
    var passwordInput = loginform.querySelector('input[name=password]');
    var login = loginInput.value;
    var password = passwordInput.value;
    doLogging(login, password);
  }
  
  registerform.onsubmit = function (e) {
    e.preventDefault();
    var loginInput = registerform.querySelector('input[name=login]');
    var passwordInput = registerform.querySelector('input[name=password]');
    var login = loginInput.value;
    var password = passwordInput.value;
    doLogging(login, password);
  }

  chatform.onsubmit = function (e) {
    e.preventDefault();
    var input = document.querySelector('input[name=message]');
    var text = input.value;
    ws.send(text);
    input.value = '';
    input.focus();
    return false;
  }

  ws.onmessage = function (msg) {
    var response = msg.data;
    var messageList = document.querySelector('.messages');
    var li = document.createElement('li');
    li.textContent = response;
    messageList.appendChild(li);
  }

}());