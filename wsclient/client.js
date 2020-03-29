(function () {
  // var SERVER = 'bosa3032.odns.fr';
  // var SERVER = 'localhost:1337';
  // var SERVER = 'app-96e160ad-34c6-4f60-a605-30805dbe4214.cleverapps.io/';
  var SERVER = window.location.host;
  var PROTOCOL = location.protocol;
  var WS_PROTOCOL = PROTOCOL === 'https:' ? 'wss:' : 'ws:';

  var ws = new WebSocket(`${WS_PROTOCOL}//${SERVER}/`);

  var chatform = document.querySelector('.chatform');
  var loginform = document.querySelector('.loginform');
  var registerform = document.querySelector('.registerform');
  document.querySelector('#chat').style.display = 'none';

  async function sendLogging(login, password) {
    const loginResponse = await fetch(`${PROTOCOL}//${SERVER}/login`, {
      method: 'POST',
      body: JSON.stringify({
        "username": login,
        "password": password
      }),
      headers: {
        'Content-Type': 'application/json'
      },
      credentials: 'include'
    });
    const loginResponseValue = await loginResponse.text();
    if (loginResponseValue.ok) {
      document.querySelector('.error').textContent = loginResponseValue;
      return;
    }

    const ticketResponse = await fetch(`${PROTOCOL}//${SERVER}/wsTicket`, {
      method: 'GET',
      credentials: 'include'
    });

    const ticketResponseValue = await ticketResponse.text();
    console.log(ticketResponseValue);
    if (ticketResponse.ok) {
      console.log("Sending ticketResponseValue");
      ws.send(ticketResponseValue);
      document.querySelector('#login').style.display = 'none';
      document.querySelector('#register').style.display = 'none';
      document.querySelector('#chat').style.display = 'block';
      document.querySelector('input[name=message]').focus();

    } else {
      document.querySelector('.error').textContent = ticketResponseValue;
    }
  }

  async function sendRegister(login, password, email) {
    const response = await fetch(`${PROTOCOL}//${SERVER}/subscribe`, {
      method: 'POST',
      body: JSON.stringify({
        "username": login,
        "password": password,
        "email": email,
      }),
      headers: {
        'Content-Type': 'application/json'
      },
      credentials: 'include'
    });
    const registerResponseValue = await response.text();
    if (!registerResponseValue.ok) {
      document.querySelector('.error').textContent = registerResponseValue;
    } else {
      document.querySelector('.error').textContent = 'Le compte a été créé !';
    }
  }

  loginform.onsubmit = function (e) {
    e.preventDefault();
    var loginInput = loginform.querySelector('input[name=login]');
    var passwordInput = loginform.querySelector('input[name=password]');
    var login = loginInput.value;
    var password = passwordInput.value;
    sendLogging(login, password);
  }

  registerform.onsubmit = function (e) {
    e.preventDefault();
    var loginInput = registerform.querySelector('input[name=login]');
    var passwordInput = registerform.querySelector('input[name=password]');
    var emailInput = registerform.querySelector('input[name=email]');
    sendRegister(loginInput.value, passwordInput.value, emailInput.value);
  }

  chatform.onsubmit = function (e) {
    e.preventDefault();
    var input = document.querySelector('input[name=message]');
    var text = input.value;
    ws.send(text);
    console.log("sending: " + text)
    input.value = '';
    input.focus();
    return false;
  }

  ws.onmessage = function (msg) {
    console.log("received: " + msg)
    var response = msg.data;
    var messageList = document.querySelector('.messages');
    var li = document.createElement('li');
    li.textContent = response;
    messageList.appendChild(li);
  }

}());