(function(google, $, _, PlanningAlerts){
  $(function(){
    var applications = PlanningAlerts.search.applications;
    var lat = PlanningAlerts.search.lat;
    var lng = PlanningAlerts.search.lng;
    var $map = $('#map');

    // Don't bother doing map things if there's not a map element on the page
    // (there might not be if the user asked for a list view or they didn't
    // search by location)
    if($map.length > 0) {
      var defaultZoomLevel = 16;
      var markers = [];
      // Tell underscore to use mustache style delimeters so that it doesn't
      // collide with ERB and confuse HAML in our views
      _.templateSettings = {
        interpolate : /\{\{(.+?)\}\}/g
      };
      var markerTemplate = _.template($('#marker-template').html(), {variable: 'application'});
      var map, infoWindow;

      // Hide the list (we show both when people don't specify a view
      // because they might not have javascript to get the map)
      var $list = $('#list');
      $list.hide();

      // Draw the map
      if(!isNaN(lat) && !isNaN(lng)) {
        $map.css('height', '600px');
        var mapOptions = {
          center: { lat: lat, lng: lng},
          zoom: defaultZoomLevel,
          styles: PlanningAlerts.mapStyles,
          scrollwheel: false,
          streetViewControl: false,
          mapTypeControl: false,
          panControlOptions: {
            position: google.maps.ControlPosition.RIGHT_TOP
          },
          zoomControlOptions: {
            position: google.maps.ControlPosition.RIGHT_TOP
          }
        };
        map = new google.maps.Map(document.getElementById('map'), mapOptions);

        // Create an info window to show popup info in
        infoWindow = new google.maps.InfoWindow({content: ''});

        // Add markers to the map
        $.each(applications, function(index, applicationObject) {
          var application = applicationObject.application;
          var marker = new google.maps.Marker({
            position: new google.maps.LatLng(application.lat, application.lng),
            title: application.description,
            map: map
          });
          google.maps.event.addListener(marker, 'click', function() {
            var content = markerTemplate(application);
            infoWindow.setContent(content);
            infoWindow.open(map, marker);
          });
          markers.push(marker);
        });
      }
    }
  });
})(window.google, window.$, window._, window.PlanningAlerts);
