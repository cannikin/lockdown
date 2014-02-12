Lockdown = function() {
  this.ws;
  this.wsInterval;
  this.wsConnected;
  this.output = document.getElementById('messages');

  this.attachEvents();
  this.initializeWebSocket();
};

Lockdown.prototype.attachEvents = function() {
  var self = this;

  var input = document.getElementById('input');
  document.getElementById('form').onsubmit = function() {
    self.ws.send(input.value);
    input.value = "";
    return false;
  };
};

Lockdown.prototype.show = function(message) {
  this.output.innerHTML = message + '<br />' + this.output.innerHTML;
};

Lockdown.prototype.initializeWebSocket = function() {
  var self = this;

  this.ws = new WebSocket('ws://' + window.location.host + window.location.pathname);
  this.ws.onopen = function() {
    self.wsConnected = true;
    self.show('websocket opened');
    clearInterval(self.wsInterval);
  };
  this.ws.onclose = function() {
    self.show('websocket closed');
    if (self.wsConnected) {
      self.wsInterval = setInterval(function() {
        while (self.ws.readyState == 3) {
          console.info("Trying to connect...");
          self.initializeWebSocket();
        }
      }, 2000);
    }
    self.wsConnected = false;
  };
  this.ws.onmessage = function(m) {
    self.show(m.data);
  };
};
