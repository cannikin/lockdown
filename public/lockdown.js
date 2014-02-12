var ws, wsInterval, show, wsConnected;

window.onload = function() {
  var container = document.getElementById('messages');

  show = function(message) {
    container.innerHTML = message + '<br />' + container.innerHTML;
  };

  var input = document.getElementById('input');
  document.getElementById('form').onsubmit = function() {
    ws.send(input.value);
    input.value = "";
    return false;
  };

  initializeWebSocket();
}

var initializeWebSocket = function() {
  ws = new WebSocket('ws://' + window.location.host + window.location.pathname);
  ws.onopen = function() {
    wsConnected = true;
    show('websocket opened');
    clearInterval(wsInterval);
  };
  ws.onclose = function() {
    show('websocket closed');
    if (wsConnected) {
      wsInterval = setInterval(function() {
        while (ws.readyState == 3) {
          console.info("Trying to connect...");
          initializeWebSocket();
        }
      }, 2000);
    }
    wsConnected = false;
  };
  ws.onmessage = function(m) {
    show(m.data);
  };
}
