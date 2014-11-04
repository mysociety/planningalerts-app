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
      // http://stackoverflow.com/a/9150399
      _.templateSettings = {
        evaluate : /\{\[([\s\S]+?)\]\}/g,
        interpolate : /\{\{([\s\S]+?)\}\}/g
      };
      var markerTemplate = _.template($('#marker-template').html(), {variable: 'application'});
      var map, infoWindow;

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
      if($('#sidebar').css('position') == 'static'){
        searchHeight += $('#sidebar').outerHeight();
      }
      $('#map').css('top', searchHeight);

      // Draw the map
      if(!isNaN(lat) && !isNaN(lng)) {
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
        infoWindow = new google.maps.InfoWindow({
          content: '',
          maxWidth: 260 - 23 // Google Maps adds 23px on for close button
        });

        // Add markers to the map
        $.each(applications, function(index, applicationObject) {
          var application = applicationObject.application;
          var marker = new google.maps.Marker({
            position: new google.maps.LatLng(application.lat, application.lng),
            title: application.description,
            map: map
          });
          google.maps.event.addListener(marker, 'click', function() {
            var tooSmall = ($('#map').height() < 500) || ($('#map').width() <= 480);
            if(tooSmall){
              window.location.href = '/applications/' + application.id + '/' + application.authority.short_name_encoded + '/' + application.council_reference;
            } else {
              var content = markerTemplate(application);
              infoWindow.setContent(content);
              infoWindow.open(map, marker);
            }
          });
          markers.push(marker);
        });
      }
    }
  });
})(window.google, window.$, window._, window.PlanningAlerts);
