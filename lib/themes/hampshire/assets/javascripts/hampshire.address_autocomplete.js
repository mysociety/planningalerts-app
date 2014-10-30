(function($, google, PlanningAlerts) {
  var service = new google.maps.places.AutocompleteService();

  // Return true or false depending on whether we want to use this
  // prediction. Returning true means we do, false we don't
  var filterPrediction = function filterPrediction(prediction) {
    if (prediction.types[0] === 'route') {
      return prediction;
    }
    else {
      return null;
    }
  };
  var boundsSWCoords = PlanningAlerts.configuration.boundingBoxSW;
  var boundsNECoords = PlanningAlerts.configuration.boundingBoxNE;
  var boundsSW = new google.maps.LatLng(boundsSWCoords[0], boundsSWCoords[1]);
  var boundsNE = new google.maps.LatLng(boundsNECoords[0], boundsNECoords[1]);
  var autoCompleteBounds = new google.maps.LatLngBounds(boundsSW, boundsNE);

  $(function(){
    $('#location').autocomplete({
      html: true,
      source: function(request, response) {
        service.getPlacePredictions({
          input: request.term,
          componentRestrictions: {country: 'gb'},
          types: ['geocode'],
          bounds: autoCompleteBounds
        }, function(predictions, status){
          predictions = $.map(predictions, filterPrediction);
          response($.map(predictions, function(prediction){
            // Just highlight the first matched substring
            var length = prediction.matched_substrings[0].length;
            var offset = prediction.matched_substrings[0].offset;
            // Remove the country name from the list to make a slightly shorter version of the text
            var textArray = $.map(prediction.terms.slice(0,-1), function(term){
              return(term.value);
            });
            var text = textArray.join(', ');
            var html = text.slice(0, offset) +
              '<strong>' + text.slice(offset, offset+length) + '</strong>' +
              text.slice(offset+length);

            return({label: html, value: text});
          }));
        });
      },
      select: function( event, ui ) {
        $(this).val(ui.item.value);
        // If we're on the search page make selecting an address submit the form
        $('.address-search').submit();
      }
    });
  });
})(window.jQuery, window.google, window.PlanningAlerts);