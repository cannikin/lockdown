require 'sinatra'
require 'sinatra-websocket'
require './guarddog'
require 'pry'
require 'pry-nav'

set :server, 'thin'
set :sockets, []
set :guarddog, Guarddog.new('/dev/tty.usbmodem40111')

get '/' do
  if !request.websocket?
    erb :index
  else
    request.websocket do |ws|
      ws.onopen do
        ws.send("Hello World!")
        settings.sockets << ws
        EM.next_tick { settings.sockets.each { |s| s.send(settings.guarddog.status.to_json) } }
      end
      ws.onmessage do |msg|
        EM.next_tick { settings.sockets.each { |s| s.send(settings.guarddog.poll.to_json) } }
      end
      ws.onclose do
        warn("websocket closed")
        settings.sockets.delete(ws)
        if settings.sockets.empty?
          settings.guarddog.close
        end
      end
    end
  end
end

__END__
@@ index
<html>
  <body>
     <h1>Simple Echo & Chat Server</h1>
     <form id="form">
       <input type="text" id="input" placeholder="message"></input>
     </form>
     <div id="msgs"></div>
  </body>

  <script type="text/javascript">
    window.onload = function(){
      (function(){
        var show = function(el){
          return function(msg){ el.innerHTML = msg + '<br />' + el.innerHTML; }
        }(document.getElementById('msgs'));

        var ws       = new WebSocket('ws://' + window.location.host + window.location.pathname);
        ws.onopen    = function()  { show('websocket opened'); };
        ws.onclose   = function()  { show('websocket closed'); }
        ws.onmessage = function(m) { show('websocket message: ' +  m.data); };

        var sender = function(f){
          var input     = document.getElementById('input');
          input.onclick = function(){ input.value = "" };
          f.onsubmit    = function(){
            ws.send(input.value);
            input.value = "";
            return false;
          }
        }(document.getElementById('form'));
      })();
    }
  </script>
</html>
