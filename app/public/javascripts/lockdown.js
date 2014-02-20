Lockdown = function() {
  this.ws;
  this.wsInterval;
  this.wsConnected;
  this.output = document.getElementById('messages');
  this.sounds = { open:'/sounds/door-open.wav',
                  closed:'/sounds/door-closed.wav' };

  this.attachEvents();
  this.startPeriodicTasks();
  this.initializeWebSocket();
};

Lockdown.prototype.attachEvents = function() {
  var self = this;
  var $doc = $(document);

  // Watch buttons for clicks
  $('#modes').on('click', 'a', function(e) {
    $doc.trigger('mode.click', this);
    e.preventDefault();
  });


  // Watch for video clicks
  $('#videos').on('click', '.video', function(e) {
    $doc.trigger('video.click', this);
  });


  // A mode is clicked
  $doc.on('mode.click', function(el) {
    var modeName = $(el).data('mode');
    self.ws.send(JSON.stringify({ event:'change_mode', data:{ mode:modeName } }));
  });


  // Mode is changed via server notice
  $doc.on('mode.change', function(data) {
    $('#modes a').removeClass('active');
    $('#modes #'+data.mode).addClass('active');
    $('body').removeClass('day night away').addClass(data.mode);
  });


  // A video is clicked
  $doc.on('video.click', function(el) {
    $(el).toggleClass('open');
  });

  // Workaround for iOS audio: click the house first to start audio playing
  // $('#house').on('click', function() {
  //   $('#audio').get(0).play();
  // });
};


Lockdown.prototype.startPeriodicTasks = function() {
  var self = this;
  // Update the date/time every second
  setInterval(function() {
    self.updateDateTime();
  }, 1000);
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
    case 'change_mode':
      $(document).trigger('mode.change', item.data);
      break;
    default:
      console.info(item.data);
    }
  });
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
  var state = data.value == '0' ? 'closed' : 'open';
  $('#sensor_'+data.id).removeClass('open closed').addClass(state);
  // $('#audio').attr('src', this.sounds[state]).get(0).play();
};
