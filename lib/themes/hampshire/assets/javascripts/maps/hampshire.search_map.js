(function(google, $, applications){
  $(function(){
    var url = $.url();
    var $map = $('#map');
    var styles = [
      {
        'featureType': 'water',
        'stylers': [
          {
            'saturation': 43
          },
          {
            'lightness': -11
          },
          {
            'hue': '#0088ff'
          }
        ]
      },
      {
        'featureType': 'road',
        'elementType': 'geometry.fill',
        'stylers': [
          {
            'hue': '#ff0000'
          },
          {
            'saturation': -100
          },
          {
            'lightness': 99
          }
        ]
      },
      {
        'featureType': 'road',
        'elementType': 'geometry.stroke',
        'stylers': [
          {
            'color': '#808080'
          },
          {
            'lightness': 54
          }
        ]
      },
      {
        'featureType': 'landscape.man_made',
        'elementType': 'geometry.fill',
        'stylers': [
          {
            'color': '#ece2d9'
          }
        ]
      },
      {
        'featureType': 'poi.park',
        'elementType': 'geometry.fill',
        'stylers': [
          {
            'color': '#ccdca1'
          }
        ]
      },
      {
        'featureType': 'road',
        'elementType': 'labels.text.fill',
        'stylers': [
          {
            'color': '#767676'
          }
        ]
      },
      {
        'featureType': 'road',
        'elementType': 'labels.text.stroke',
        'stylers': [
          {
            'color': '#ffffff'
          }
        ]
      },
      {
        'featureType': 'poi',
        'stylers': [
          {
            'visibility': 'off'
          }
        ]
      },
      {
        'featureType': 'landscape.natural',
        'elementType': 'geometry.fill',
        'stylers': [
          {
            'visibility': 'on'
          },
          {
            'color': '#b8cb93'
          }
        ]
      },
      {
        'featureType': 'poi.park',
        'stylers': [
          {
            'visibility': 'on'
          }
        ]
      },
      {
        'featureType': 'poi.sports_complex',
        'stylers': [
          {
            'visibility': 'on'
          }
        ]
      },
      {
        'featureType': 'poi.medical',
        'stylers': [
          {
            'visibility': 'on'
          }
        ]
      },
      {
        'featureType': 'poi.business',
        'stylers': [
          {
            'visibility': 'simplified'
          }
        ]
      }
    ];

    // Don't bother doing map things if there's not a map element on the page
    // (there might not be if the user asked for a list view or they didn't
    // search by location)
    if($map.length > 0) {
      var lat = parseFloat(url.param('lat'));
      var lng = parseFloat(url.param('lng'));
      var defaultZoomLevel = 13;
      var markers = [];
      var map;

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
          styles: styles,
          streetViewControl: false,
          panControl: false,
          zoomControlOptions: {
            style: google.maps.ZoomControlStyle.SMALL
          }
        };
        map = new google.maps.Map(document.getElementById('map'), mapOptions);

        $.each(applications, function(index, applicationObject) {
          var application = applicationObject.application;
          console.log(application);
          markers.push(new google.maps.Marker({
            position: new google.maps.LatLng(application.lat, application.lng),
            title: application.description,
            map: map
          }));
        });
      }
    }
  });
})(window.google, window.$, window.applications);
