// Handles all client interface logic. All communication happens through a
// WebSocket to keep it as fast as possible. This also facilitates telling all
// clients about events pretty much simultaneously.

Lockdown = function() {
  this.ws;
  this.wsInterval;
  this.wsConnected;
  this.output = document.getElementById('messages');
  this.sounds = { open:'/sounds/door-open.wav',
                  closed:'/sounds/door-closed.wav' };

  this.attachBrowserEvents();
  this.attachCustomEvents();
  this.startPeriodicTasks();
  this.initializeWebSocket();
};


// Standard browser events. Translated into custom Lockdown events.
Lockdown.prototype.attachBrowserEvents = function() {
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

};


// Custom events that Lockdown fires
Lockdown.prototype.attachCustomEvents = function() {
  var self = this;
  var $doc = $(document);

  // A mode is clicked
  $doc.on('mode.click', function(e, el) {
    var modeName = $(el).data('mode');
    self.ws.send(JSON.stringify({ event:'change_mode', data:{ mode:modeName } }));
  });


  // Server says the mode has changed
  $doc.on('mode.change', function(e, data) {
    $('#modes a').removeClass('active');
    $('#modes #'+data.mode).addClass('active');
    $('body').removeClass('day night away').addClass(data.mode);
  });


  // Sensor has changed values, update house graphic
  $doc.on('house.event', function(e, data) {
    var state = data.value == data.base_state ? 'closed' : 'open';
    var $el = $('#sensor_'+data.id);
    if (!$el.hasClass(state)) {
      $el.removeClass('open closed').addClass(state);
      $('#door-'+state).get(0).play();
    }
  });


  // Motion detected
  $doc.on('motion', function(e, data) {
    console.warn('Motion detected: ' + data.location);
  });


  // A video is clicked
  $doc.on('video.click', function(e, el) {
    $(el).toggleClass('open');
  });

};


// Anything that should happen repeatedly
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
    // console.info('websocket opened');
    clearInterval(self.wsInterval);
  };
  this.ws.onclose = function() {
    // console.info('websocket closed');
    if (self.wsConnected) {
      self.wsInterval = setInterval(function() {
        while (self.ws.readyState == 3) {
          // console.info("Trying to connect...");
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
    case 'sensor_change':
      $(document).trigger('house.event', item.data);
      break;
    case 'change_mode':
      $(document).trigger('mode.change', item.data);
      break;
    case 'motion':
      $(document).trigger('motion', item.data);
      break;
    default:
      console.warn("Unrecognized WebSocket message received: ", item);
      break;
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
