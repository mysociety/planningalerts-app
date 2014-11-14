// Override the default initialiseMaps function
(function(mxn, google) {
  // Override the existing function that plannings alerts maps.js provides
  // TODO - it would be nicer if this was on the PlanningAlerts global instead
  // and perhaps if the core function could look for theme functions rather
  // than us monkey patching it.
  window.initialiseMaps = function(latitude, longitude, address, status, extraOptions) {
    var application = { status: status };
    var map = new mxn.Mapstraction('map_div','googlev3');
    var point = new mxn.LatLonPoint(latitude, longitude);
    map.setCenterAndZoom(point, 16);
    var marker = new mxn.Marker(point);
    marker.setLabel(address);
    marker.setIcon('/assets/marker-' + (application.status || 'pending') + '.png', [31, 50], [31/2, 50]);
    map.addMarker(marker);

    // Set additional options, note this is Google Maps specific
    var googleMap = map.getMap();
    googleMap.setOptions(extraOptions);

    // Can't yet figure out how to make the POV point at the marker
    var pointToLookAt = new google.maps.LatLng(latitude, longitude);
    // Call the StreetViewService to check that something exists at the location
    // before we add it.
    // https://developers.google.com/maps/documentation/javascript/streetview#StreetViewMapUsage
    // says that if the second radius parameter is 50 meters or less it will
    // show the nearest panorama to that location.
    var streetViewService = new google.maps.StreetViewService();
    streetViewService.getPanoramaByLocation(pointToLookAt, 50, function(data, status){
      if(status === google.maps.StreetViewStatus.OK) {
        // Google thinks it can find a StreetView, so show it
        var myPano = new google.maps.StreetViewPanorama(document.getElementById('pano'), {
          position: pointToLookAt,
          navigationControl: false,
          addressControl: false,
          panControl: false,
          linksControl: false,
          zoomControl: false,
          clickToGo: false,
          zoom: 0
        });
        google.maps.event.addListener(myPano, 'position_changed', function() {
          // Orient the camera to face the position we're interested in
          var angle = window.computeAngle(pointToLookAt, myPano.getPosition());
          myPano.setPov({heading:angle, pitch:0, zoom:1});
        });
        var panoMarker = new google.maps.Marker({
          position: pointToLookAt,
          title: address,
          icon: {
            url: '/assets/marker-' + (application.status || 'pending') + '.png',
            size: new google.maps.Size(31, 50)
          }
        });
        panoMarker.setMap(myPano);
      }
      else {
        // No streetview in this location, show a static satellite image
        // instead
        var satelliteMap = new mxn.Mapstraction('pano','googlev3');
        satelliteMap.setCenterAndZoom(point, 16);
        satelliteMap.addMarker(marker);
        satelliteMap.getMap().setOptions({mapTypeId: google.maps.MapTypeId.SATELLITE});
      }
    });
  };
})(window.mxn, window.google);
