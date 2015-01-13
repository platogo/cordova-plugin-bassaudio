Cordova BASS Audio Library Plugin
=================================

Installation
------------
```
cordova plugin add https://github.com/platogo/cdv-bassaudio
```

Usage
-----
```
<script type="text/javascript>
	bassaudio.play(fileName, options, function(channel) {
		alert('success');
	}, function(e) {
		alert('error');
	});
</script>
```

Compatibility
-------------
Phonegap > 3.0.0
