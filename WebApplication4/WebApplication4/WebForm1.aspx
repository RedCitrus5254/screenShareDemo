﻿<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="WebForm1.aspx.cs" Inherits="WebApplication4.WebForm1" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta charset="utf-8"/>
    <title>Screen Sharing using RTCMultiConnection</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, minimum-scale=1.0"/>
    <link rel="shortcut icon" href="/demos/logo.png"/>
    <link rel="stylesheet" href="stylesheet.css"/>
    <script src="menu.js"></script>
</head>
<body>
    <section class="make-center">
        <input type="text" id="room-id" value="abcdef" size="20"/>
        <input id="open-room" type="button" name="button"></input>
        <button id="join-room">Join Room</button>
        <button id="open-or-join-room">Auto Open Or Join Room</button>

        <div id="videos-container" style="margin: 20px 0;"></div>

        <div id="room-urls" style="text-align: center;display: none;background: #F1EDED;margin: 15px -10px;border: 1px solid rgb(189, 189, 189);border-left: 0;border-right: 0;"></div>
    </section>

    <script src="RTCMultiConnection.js"></script>
    <script src="adapter.js"></script>
    <script src="https://rtcmulticonnection.herokuapp.com/socket.io/socket.io.js"></script>

    <!-- custom layout for HTML5 audio/video elements -->
    <link rel="stylesheet" href="getHTMLMediaElement.css"/>
    <script src="getHTMLMediaElement.js"></script>
    <script>
// ......................................................
// .......................UI Code........................
// ......................................................
document.getElementById('open-room').onclick = function() {
    disableInputButtons();
    connection.open('carrot1', function() {
        showRoomURL(connection.sessionid);
    });
};

document.getElementById('join-room').onclick = function() {
    disableInputButtons();

    connection.sdpConstraints.mandatory = {
        OfferToReceiveAudio: false,
        OfferToReceiveVideo: true
    };
    connection.join(document.getElementById('room-id').value);
};

document.getElementById('open-or-join-room').onclick = function() {
    disableInputButtons();
    connection.openOrJoin(document.getElementById('room-id').value, function(isRoomExist, roomid) {
        if (isRoomExist === false && connection.isInitiator === true) {
            // if room doesn't exist, it means that current user will create the room
            showRoomURL(roomid);
        }

        if(isRoomExist) {
          connection.sdpConstraints.mandatory = {
              OfferToReceiveAudio: false,
              OfferToReceiveVideo: true
          };
        }
    });
};

// ......................................................
// ..................RTCMultiConnection Code.............
// ......................................................

var connection = new RTCMultiConnection();

// by default, socket.io server is assumed to be deployed on your own URL
connection.socketURL = 'https://rtcmulticonnection.herokuapp.com:443/';

// comment-out below line if you do not have your own socket.io server
// connection.socketURL = 'https://rtcmulticonnection.herokuapp.com:443/';

connection.socketMessageEvent = 'screen-sharing-demo';

connection.session = {
    screen: true,
    oneway: true
};

connection.sdpConstraints.mandatory = {
    OfferToReceiveAudio: false,
    OfferToReceiveVideo: false
};

// https://www.rtcmulticonnection.org/docs/iceServers/
// use your own TURN-server here!
connection.iceServers = [{
    'urls': [
        'stun:stun.l.google.com:19302',
        'stun:stun1.l.google.com:19302',
        'stun:stun2.l.google.com:19302',
        'stun:stun.l.google.com:19302?transport=udp',
    ]
}];

connection.videosContainer = document.getElementById('videos-container');
connection.onstream = function(event) {
    var existing = document.getElementById(event.streamid);
    if(existing && existing.parentNode) {
      existing.parentNode.removeChild(existing);
    }

    event.mediaElement.removeAttribute('src');
    event.mediaElement.removeAttribute('srcObject');
    event.mediaElement.muted = true;
    event.mediaElement.volume = 0;

    var video = document.createElement('video');

    try {
        video.setAttributeNode(document.createAttribute('autoplay'));
        video.setAttributeNode(document.createAttribute('playsinline'));
    } catch (e) {
        video.setAttribute('autoplay', true);
        video.setAttribute('playsinline', true);
    }

    if(event.type === 'local') {
      video.volume = 0;
      try {
          video.setAttributeNode(document.createAttribute('muted'));
      } catch (e) {
          video.setAttribute('muted', true);
      }
    }
    video.srcObject = event.stream;

    var width = innerWidth - 80;
    var mediaElement = getHTMLMediaElement(video, {
        title: event.userid,
        buttons: ['full-screen'],
        width: width,
        showOnMouseEnter: false
    });

    connection.videosContainer.appendChild(mediaElement);

    setTimeout(function() {
        mediaElement.media.play();
    }, 5000);

    mediaElement.id = event.streamid;
};

connection.onstreamended = function(event) {
    var mediaElement = document.getElementById(event.streamid);
    if (mediaElement) {
        mediaElement.parentNode.removeChild(mediaElement);

        if(event.userid === connection.sessionid && !connection.isInitiator) {
          alert('Broadcast is ended. We will reload this page to clear the cache.');
          location.reload();
        }
    }
};

connection.onMediaError = function(e) {
    if (e.message === 'Concurrent mic process limit.') {
        if (DetectRTC.audioInputDevices.length <= 1) {
            alert('Please select external microphone. Check github issue number 483.');
            return;
        }

        var secondaryMic = DetectRTC.audioInputDevices[1].deviceId;
        connection.mediaConstraints.audio = {
            deviceId: secondaryMic
        };

        connection.join(connection.sessionid);
    }
};

// ..................................
// ALL below scripts are redundant!!!
// ..................................

function disableInputButtons() {
    document.getElementById('room-id').onkeyup();

    document.getElementById('open-or-join-room').disabled = true;
    document.getElementById('open-room').disabled = true;
    document.getElementById('join-room').disabled = true;
    document.getElementById('room-id').disabled = true;
}

// ......................................................
// ......................Handling Room-ID................
// ......................................................

function showRoomURL(roomid) {
    var roomHashURL = '#' + roomid;
    var roomQueryStringURL = '?roomid=' + roomid;

    var html = '<h2>Unique URL for your room:</h2><br>';

    html += 'Hash URL: <a href="' + roomHashURL + '" target="_blank">' + roomHashURL + '</a>';
    html += '<br>';
    html += 'QueryString URL: <a href="' + roomQueryStringURL + '" target="_blank">' + roomQueryStringURL + '</a>';

    var roomURLsDiv = document.getElementById('room-urls');
    roomURLsDiv.innerHTML = html;

    roomURLsDiv.style.display = 'block';
}

(function() {
    var params = {},
        r = /([^&=]+)=?([^&]*)/g;

    function d(s) {
        return decodeURIComponent(s.replace(/\+/g, ' '));
    }
    var match, search = window.location.search;
    while (match = r.exec(search.substring(1)))
        params[d(match[1])] = d(match[2]);
    window.params = params;
})();

var roomid = '';
if (localStorage.getItem(connection.socketMessageEvent)) {
    roomid = localStorage.getItem(connection.socketMessageEvent);
} else {
    roomid = connection.token();
}
document.getElementById('room-id').value = roomid;
document.getElementById('room-id').onkeyup = function() {
    localStorage.setItem(connection.socketMessageEvent, document.getElementById('room-id').value);
};

var hashString = location.hash.replace('#', '');
if (hashString.length && hashString.indexOf('comment-') == 0) {
    hashString = '';
}

var roomid = params.roomid;
if (!roomid && hashString.length) {
    roomid = hashString;
}

if (roomid && roomid.length) {
    document.getElementById('room-id').value = roomid;
    localStorage.setItem(connection.socketMessageEvent, roomid);

    // auto-join-room
    (function reCheckRoomPresence() {
        connection.checkPresence(roomid, function(isRoomExist) {
            if (isRoomExist) {
                connection.join(roomid);
                return;
            }

            setTimeout(reCheckRoomPresence, 5000);
        });
    })();

    disableInputButtons();
}

// detect 2G
if(navigator.connection &&
   navigator.connection.type === 'cellular' &&
   navigator.connection.downlinkMax <= 0.115) {
  alert('2G is not supported. Please use a better internet service.');
}
    </script>

    <footer>
        <small id="send-message"></small>
    </footer>

    <script src="https://www.webrtc-experiment.com/common.js"></script>
</body>
</html>

