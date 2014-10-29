// Override the default initialiseMaps function
window.initialiseMaps = function(latitude, longitude, address) {
  var map = new mxn.Mapstraction("map_div","googlev3");
  point = new mxn.LatLonPoint(latitude, longitude);
  map.setCenterAndZoom(point,16);
  marker = new mxn.Marker(point)
  marker.setLabel(address);
  map.addMarker(marker);

  // Can't yet figure out how to make the POV point at the marker
  var pointToLookAt = new google.maps.LatLng(latitude, longitude);
  var myPano = new google.maps.StreetViewPanorama(document.getElementById("pano"), {
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
    var angle = computeAngle(pointToLookAt, myPano.getPosition());
    myPano.setPov({heading:angle, pitch:0, zoom:1});
  });
  var panoMarker = new google.maps.Marker({position: pointToLookAt, title: address});
  panoMarker.setMap(myPano);
}
