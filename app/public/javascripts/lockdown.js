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

  // var input = document.getElementById('input');
  // document.getElementById('form').onsubmit = function() {
  //   self.ws.send(input.value);
  //   input.value = "";
  //   return false;
  // };

  // Watch buttons for clicks
  $('#modes').on('click', 'a', function(e) {
    self.changeMode(this);
    e.preventDefault();
  });

  // Watch for video clicks
  $('#videos').on('click', '.video', function(e) {
    self.scaleVideo(this);
  });

  // Update the date/time every minute
  setInterval(function() {
    self.updateDateTime();
  }, 60000);
};

// Lockdown.prototype.show = function(message) {
//   this.output.innerHTML = message + '<br />' + this.output.innerHTML;
// };


// Start a websocket connection to the server for status updates
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
    self.handleMessage(m.data);
  };
};


// Do whatever needs to be done based on the message from the server
Lockdown.prototype.handleMessage = function(message) {
  var data = $.parseJSON(message);
  console.info(data)
  // this.show(message);
};

// Switch from/to day/night/away modes
Lockdown.prototype.changeMode = function(el) {
  var modeName = $(el).data('mode')
  $('#modes a').removeClass('active');
  $(el).addClass('active');
  $('body').removeClass('day night away').addClass(modeName);
  $.post('/mode/'+modeName);
};


// Zoom a video window
Lockdown.prototype.scaleVideo = function(el) {
  $(el).toggleClass('open');
};


// Update the date/time at the bottom of the screen
Lockdown.prototype.updateDateTime = function() {
  var now = new Date();
  var hour = now.getHours();
  var minute = now.getMinutes();
  var second = now.getSeconds();

  if (hour > 12) {
    hour -= 12;
  }
  if (minute < 10) {
    minute = '0' + minute;
  }
  $('time').attr('datetime', hour + ':' + minute + ':' + second).text(hour + ':' + minute);
};
