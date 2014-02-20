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


// Start a websocket connection to the server for status updates
Lockdown.prototype.initializeWebSocket = function() {
  var self = this;

  this.ws = new WebSocket('ws://' + window.location.host + window.location.pathname);
  this.ws.onopen = function() {
    self.wsConnected = true;
    console.info('websocket opened');
    clearInterval(self.wsInterval);
  };
  this.ws.onclose = function() {
    console.info('websocket closed');
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
    self.parseMessage(m.data);
  };
};


// Do whatever needs to be done based on the message from the server
Lockdown.prototype.parseMessage = function(message) {
  var self = this;
  var data = $.parseJSON(message);
  $.each(data, function(index, item) {
    switch(item.event) {
    case 'egress':
      self.updateHouse(item.data);
      break;
    default:
      console.info(item.data);
    }
  });
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


// Update the state of the one of the house entry points
Lockdown.prototype.updateHouse = function(data) {
  $('#sensor_'+data.id).removeClass('open closed').addClass(data.value == '0' ? 'closed' : 'open');
};
