(function(google, $, _, OverlappingMarkerSpiderfier, PlanningAlerts){
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
      // http://stackoverflow.com/a/9150399
      _.templateSettings = {
        evaluate : /\{\[([\s\S]+?)\]\}/g,
        interpolate : /\{\{([\s\S]+?)\}\}/g
      };
      var markerTemplate = _.template($('#marker-template').html(), {variable: 'data'});
      var map, infoWindow, oms;

      // Hide the list, make the map "full screen", and hide the footer
      var headerHeight = $('#header-wrapper').height();
      var searchHeight = 0;
      $('body').addClass('fullscreen-map');
      $('#content').css('top', headerHeight);
      // (#searchbar is hidden by default on narrow screens)
      if($('#searchbar').is(':visible')){
        searchHeight += $('#searchbar').outerHeight();
      }
      // (If #searchbar is statically positioned above the map, like
      // on a narrow screen, we need to move the map further down)
      if($('#sidebar').css('position') === 'static'){
        searchHeight += $('#sidebar').outerHeight();
      }
      $('#map').css('top', searchHeight);

      // Draw the map
      var mapCenter = new google.maps.LatLng(lat, lng);
      if(!isNaN(lat) && !isNaN(lng)) {
        var mapOptions = {
          center: mapCenter,
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
        oms = new OverlappingMarkerSpiderfier(map);

        // Create an info window to show popup info in
        infoWindow = new google.maps.InfoWindow({
          content: '',
          maxWidth: 260 - 23 // Google Maps adds 23px on for close button
        });

        // Define the bounds of the google map that we'll compute from the
        // markers
        var bounds = new google.maps.LatLngBounds();

        // Add markers to the map
        $.each(applications, function(index, applicationObject) {
          var application = applicationObject.application;
          var marker = new google.maps.Marker({
            position: new google.maps.LatLng(application.lat, application.lng),
            icon: {
              url: '/assets/marker-' + (application.status || 'pending') + '.png',
              size: new google.maps.Size(31, 50)
            },
            title: application.description,
            map: map
          });
          marker.clicked = function clicked() {
            var tooSmall = ($('#map').height() < 500) || ($('#map').width() <= 480);
            var queryString = $.param(PlanningAlerts.search.return_params);
            if(tooSmall){
              window.location.href = '/applications/' + application.id + '/' + application.authority.short_name_encoded + '/' + application.council_reference + '?' + queryString;
            } else {
              var content = markerTemplate({application: application, queryString: queryString});
              infoWindow.setContent(content);
              infoWindow.open(map, marker);
            }
          };
          markers.push(marker);
          oms.addMarker(marker);
          // Add the marker to the bounds
          bounds.extend(marker.getPosition());
        });

        oms.addListener('click', function(marker) {
          marker.clicked();
        });

        // Zoom to the extent of the markers, if there are any
        if(!bounds.isEmpty()) {
          map.fitBounds(bounds);
        }
      }
    }
  });
})(window.google, window.$, window._, window.OverlappingMarkerSpiderfier, window.PlanningAlerts);
