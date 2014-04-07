$(function() {
  if (navigator.geolocation) {
    $("li#q_input").append("<a class='inline-hints' id='geolocate' href='#'>... or locate me automatically</p>");
  }

  $("#geolocate").click(function(e){
    // TODO: Spin something
    navigator.geolocation.getCurrentPosition(function(pos) {
      var latlng = new google.maps.LatLng(pos.coords.latitude, pos.coords.longitude);
      geocoder = new google.maps.Geocoder();
      geocoder.geocode({'latLng': latlng}, function(results, status){
        if (status == google.maps.GeocoderStatus.OK) {
          console.log(results[0].formatted_address);
          location.href = '/?q=' + results[0].formatted_address;
        } else {
          alert("Reverse geocoding didn't work");
        }
      });
    }, function(err) {
      alert("Something errored");
    }, {enableHighAccuracy: true, timeout: 10000});

  });

  // if (geo_position_js.init()) {
  //     if ($('body.frontpage').length) {
  //         $('#postcodeForm').after('<a href="#" id="geolocate_link">&hellip; or locate me automatically</a>');
  //     } else{
  //         $('#postcodeForm').append('<a href="#" id="geolocate_link">&hellip; or locate me automatically</a>');
  //     }
  //     $('#geolocate_link').click(function(e) {
  //         var $link = $(this);
  //         e.preventDefault();
  //         // Spinny thing!
  //         if($('.mobile').length){
  //             $link.append(' <img src="/cobrands/fixmystreet/images/spinner-black.gif" alt="" align="bottom">');
  //         }else{
  //             $link.append(' <img src="/cobrands/fixmystreet/images/spinner-yellow.gif" alt="" align="bottom">');
  //         }
  //         geo_position_js.getCurrentPosition(function(pos) {
  //             $link.find('img').remove();
  //             var latitude = pos.coords.latitude;
  //             var longitude = pos.coords.longitude;
  //             location.href = '/around?latitude=' + latitude + ';longitude=' + longitude;
  //         }, function(err) {
  //             $link.find('img').remove();
  //             if (err.code == 1) { // User said no
  //                 $link.html("You declined; please fill in the box above");
  //             } else if (err.code == 2) { // No position
  //                 $link.html("Could not look up location");
  //             } else if (err.code == 3) { // Too long
  //                 $link.html("No result returned");
  //             } else { // Unknown
  //                 $link.html("Unknown error");
  //             }
  //         }, {
  //             enableHighAccuracy: true,
  //             timeout: 10000
  //         });
  //     });
  // }
});
